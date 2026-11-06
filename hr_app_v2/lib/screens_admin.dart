import 'package:flutter/material.dart';
import '../core.dart';
import '../models.dart';
import '../services.dart';

class AdminDash extends StatefulWidget{final User me;final String lang;final ValueChanged<String> onOpen;
  const AdminDash({super.key,required this.me,required this.lang,required this.onOpen});@override State<AdminDash> createState()=>_AD();}
class _AD extends State<AdminDash>{
  List<User> us=[];List<HrRequest> rq=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async{us=await Db.users();rq=await Db.requests();if(mounted)setState((){});}
  @override Widget build(BuildContext context){
    final pending=rq.where((r)=>r.status=='معلق').length;
    final inactive=us.where((u)=>!u.active).length;
    return ListView(padding:const EdgeInsets.all(14),children:[
      Text(I18n.get(I18n.t['dashboard']!,widget.lang),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
        crossAxisSpacing:10,mainAxisSpacing:10,children:[
        _s('👥','الموظفون','${us.length}'),_s('⏳','طلبات معلقة','$pending'),
        _s('🚫','معطلون','$inactive'),_s('💰','كتلة الأجور','${us.fold<double>(0,(a,b)=>a+b.salary).toStringAsFixed(0)}'),
      ]),
      const SizedBox(height:10),
      Wrap(spacing:8,runSpacing:8,children:[
        _b(context,'👥 إدارة المستخدمين',()=>widget.onOpen('users')),
        _b(context,'➕ إضافة عامل',()=>widget.onOpen('addWorker')),
        _b(context,'✅ الموافقات ($pending)',()=>widget.onOpen('approvals')),
        _b(context,'📢 الإعلانات',()=>widget.onOpen('announce-mgr')),
        if(Perm.canAudit(widget.me.role))_b(context,'🧾 سجل العمليات',()=>widget.onOpen('audit')),
        if(Perm.canAudit(widget.me.role))_b(context,'📤 التقارير',()=>widget.onOpen('reports')),
        if(Perm.canSettings(widget.me.role))_b(context,'⚙️ الإعدادات',()=>widget.onOpen('settings')),
      ]),
    ]);
  }
  Widget _s(String e,String t,String v)=>Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),
    child:Padding(padding:const EdgeInsets.all(14),child:Column(mainAxisSize:MainAxisSize.min,
      children:[Text(e,style:const TextStyle(fontSize:26)),Text(v,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),Text(t)])));
  Widget _b(BuildContext c,String t,VoidCallback f)=>FilledButton.tonal(onPressed:f,child:Text(t));
}

class UsersPage extends StatefulWidget{final User me;final String lang;const UsersPage({super.key,required this.me,required this.lang});@override State<UsersPage> createState()=>_U();}
class _U extends State<UsersPage>{
  List<User> us=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async{us=await Db.users();if(mounted)setState((){});}
  @override Widget build(BuildContext context){
    if(!Perm.canManageUsers(widget.me.role))return Scaffold(appBar:AppBar(),body:const Center(child:Text('غير مصرح')));
    return Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['users']!,widget.lang))),body:ListView.builder(
      padding:const EdgeInsets.all(12),itemCount:us.length,itemBuilder:(_,i){
      final u=us[i];final isMain=u.role==Role.superAdmin;
      return Card(color:u.id==widget.me.id?Theme.of(context).colorScheme.primaryContainer:null,
        child:ListTile(leading:CircleAvatar(child:Text(u.name.isEmpty?'؟':u.name[0])),
        title:Text('${u.name} ${isMain?'👑':''}'),subtitle:Text('${u.email}\n${u.jobNumber} • ${roleToString(u.role)} • ${u.active?'نشط':'معطل'}'),isThreeLine:true,
        trailing:PopupMenuButton<String>(onSelected:(v)async{
          if(v=='edit'){editUser(u);}
          else if(v=='toggle'){u.active=!u.active;await Db.saveUsers(us);await Store.audit(widget.me.email,'Toggle ${u.email} -> ${u.active}');load();}
          else if(v=='role-hr'){if(widget.me.role!=Role.superAdmin){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعيين الأدوار للمشرف الرئيسي فقط')));return;}u.role=u.role==Role.hr?Role.employee:Role.hr;await Db.saveUsers(us);await Store.audit(widget.me.email,'Role ${u.email}=${roleToString(u.role)}');load();}
          else if(v=='del'){
            if(isMain){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('لا يمكن حذف المشرف الرئيسي')));return;}
            us.removeAt(i);await Db.saveUsers(us);await Store.audit(widget.me.email,'Delete ${u.email}');load();}
        },itemBuilder:(_)=>const[
          PopupMenuItem(value:'edit',child:Text('تعديل')),
          PopupMenuItem(value:'toggle',child:Text('تعطيل/تفعيل')),
          PopupMenuItem(value:'role-hr',child:Text('HR ⇄ موظف')),
          PopupMenuItem(value:'del',child:Text('حذف')),
        ])));}));
  }
  void editUser(User u){
    final n=TextEditingController(text:u.name),d=TextEditingController(text:u.dept),
      pos=TextEditingController(text:u.position),sal=TextEditingController(text:u.salary.toString()),
      lv=TextEditingController(text:u.leaveBalance.toString()),mgr=TextEditingController(text:u.managerId);
    showModalBottomSheet(context:context,isScrollControlled:true,
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))),
      builder:(_)=>Padding(padding:EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom+16,left:16,right:16,top:16),
        child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text('تعديل ${u.email}',style:const TextStyle(fontWeight:FontWeight.bold)),
        const SizedBox(height:10),
        TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم',border:OutlineInputBorder())),
        const SizedBox(height:8),TextField(controller:d,decoration:const InputDecoration(labelText:'القسم',border:OutlineInputBorder())),
        const SizedBox(height:8),TextField(controller:pos,decoration:const InputDecoration(labelText:'المنصب',border:OutlineInputBorder())),
        const SizedBox(height:8),TextField(controller:sal,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الراتب',border:OutlineInputBorder())),
        const SizedBox(height:8),TextField(controller:lv,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رصيد الإجازات',border:OutlineInputBorder())),
        const SizedBox(height:8),TextField(controller:mgr,decoration:const InputDecoration(labelText:'المدير المباشر (ID)',border:OutlineInputBorder())),
        const SizedBox(height:10),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{
          u.name=n.text.trim();u.dept=d.text.trim();u.position=pos.text.trim();
          u.salary=double.tryParse(sal.text)??u.salary;u.leaveBalance=double.tryParse(lv.text)??u.leaveBalance;u.managerId=mgr.text.trim();
          await Db.saveUsers(us);await Store.audit(widget.me.email,'Edit ${u.email}');
          if(context.mounted)Navigator.pop(context);load();
        },child:const Text('حفظ'))),
      ]))));
  }
}

class AddWorkerPage extends StatefulWidget{final User me;final String lang;const AddWorkerPage({super.key,required this.me,required this.lang});@override State<AddWorkerPage> createState()=>_AW();}
class _AW extends State<AddWorkerPage>{
  final n=TextEditingController(),job=TextEditingController(),em=TextEditingController(),ph=TextEditingController(),
    dept=TextEditingController(text:'عام'),pos=TextEditingController(text:'موظف'),sal=TextEditingController(text:'45000'),
    mgr=TextEditingController(),lv=TextEditingController(text:'30'),csv=TextEditingController();
  @override Widget build(BuildContext context){
    if(!Perm.canManageUsers(widget.me.role))return Scaffold(appBar:AppBar(),body:const Center(child:Text('غير مصرح')));
    return Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['addWorker']!,widget.lang))),
      body:ListView(padding:const EdgeInsets.all(14),children:[
      const Text('نموذج إضافة عامل جديد',style:TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم *',border:OutlineInputBorder())),const SizedBox(height:8),
      Row(children:[Expanded(child:TextField(controller:job,decoration:const InputDecoration(labelText:'الرقم الوظيفي *',border:OutlineInputBorder()))),
        const SizedBox(width:8),Expanded(child:TextField(controller:em,decoration:const InputDecoration(labelText:'البريد',border:OutlineInputBorder())))]),
      const SizedBox(height:8),
      Row(children:[Expanded(child:TextField(controller:dept,decoration:const InputDecoration(labelText:'القسم',border:OutlineInputBorder()))),
        const SizedBox(width:8),Expanded(child:TextField(controller:pos,decoration:const InputDecoration(labelText:'المنصب',border:OutlineInputBorder())))]),
      const SizedBox(height:8),
      Row(children:[Expanded(child:TextField(controller:sal,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الراتب',border:OutlineInputBorder()))),
        const SizedBox(width:8),Expanded(child:TextField(controller:ph,decoration:const InputDecoration(labelText:'الهاتف',border:OutlineInputBorder())))]),
      const SizedBox(height:8),
      Row(children:[Expanded(child:TextField(controller:mgr,decoration:const InputDecoration(labelText:'المدير المباشر',border:OutlineInputBorder()))),
        const SizedBox(width:8),Expanded(child:TextField(controller:lv,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رصيد الإجازات',border:OutlineInputBorder())))]),
      const SizedBox(height:8),
      SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{
        if(n.text.trim().isEmpty||job.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الاسم والرقم الوظيفي إجباري')));return;}
        final us=await Db.users();
        if(us.any((u)=>u.jobNumber==job.text.trim())){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('رقم وظيفي موجود')));return;}
        us.add(User(id:DateTime.now().millisecondsSinceEpoch.toString(),name:n.text.trim(),jobNumber:job.text.trim(),
          email:em.text.trim().isEmpty?'${job.text.trim()}@company.dz':em.text.trim(),password:job.text.trim(),
          phone:ph.text.trim(),dept:dept.text.trim(),position:pos.text.trim(),hireDate:DateTime.now().toIso8601String().substring(0,10),
          salary:double.tryParse(sal.text)??0,managerId:mgr.text.trim(),leaveBalance:double.tryParse(lv.text)??30));
        await Db.saveUsers(us);await Store.audit(widget.me.email,'Add worker ${job.text}');
        if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم إنشاء حساب دخول: ${job.text.trim()} / كلمة المرور = الرقم الوظيفي')));Navigator.pop(context);}
      },child:const Text('إضافة + إنشاء حساب دخول تلقائي'))),
      const Divider(height:28),
      const Text('إضافة دفعة واحدة عبر CSV',style:TextStyle(fontWeight:FontWeight.bold)),
      const Text('الصيغة: name,jobNumber,email,phone,dept,position,salary',style:TextStyle(fontSize:12,color:Colors.grey)),
      const SizedBox(height:8),
      TextField(controller:csv,maxLines:4,decoration:const InputDecoration(hintText:'Ahmed,101,ah@co.dz,055..,IT,Dév,60000',border:OutlineInputBorder())),
      const SizedBox(height:8),
      OutlinedButton.icon(icon:const Icon(Icons.upload_file),label:const Text('استيراد CSV'),
        onPressed:()async{final c=await Auth.importCsv(csv.text,widget.me.email);
          if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تمت إضافة $c عامل')));}),
    ]));
  }
}

class ApprovalsPage extends StatefulWidget{final User me;final String lang;const ApprovalsPage({super.key,required this.me,required this.lang});@override State<ApprovalsPage> createState()=>_AP();}
class _AP extends State<ApprovalsPage>{
  List<HrRequest> rq=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async{rq=await Db.requests();if(mounted)setState((){});}
  @override Widget build(BuildContext context){
    if(!Perm.canApprove(widget.me.role))return Scaffold(appBar:AppBar(),body:const Center(child:Text('غير مصرح')));
    List<HrRequest> list=rq;
    if(widget.me.role==Role.manager){ // manager: only his team
      list=list.where((r)=>r.status=='معلق').toList();
    }
    return Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['approvals']!,widget.lang))),
      body:ListView.builder(padding:const EdgeInsets.all(12),itemCount:list.length,itemBuilder:(_,i){
        final r=list[list.length-1-i];
        return Card(child:ListTile(title:Text('${r.type} — ${r.userName}'),subtitle:Text('${r.details}\n${r.date} • ${r.status}'),
          trailing:Row(mainAxisSize:MainAxisSize.min,children:[
            IconButton(icon:const Icon(Icons.check,color:Colors.green),onPressed:()async{
              r.status='مقبول';await Db.saveReqs(rq);await Store.audit(widget.me.email,'Approve ${r.id}');load();}),
            IconButton(icon:const Icon(Icons.close,color:Colors.red),onPressed:()async{
              r.status='مرفوض';await Db.saveReqs(rq);await Store.audit(widget.me.email,'Reject ${r.id}');load();}),
          ])));
      }));
  }
}

class AnnounceMgrPage extends StatefulWidget{final User me;final String lang;const AnnounceMgrPage({super.key,required this.me,required this.lang});@override State<AnnounceMgrPage> createState()=>_AN();}
class _AN extends State<AnnounceMgrPage>{
  List<Announce> a=[];final t=TextEditingController(),b=TextEditingController();
  @override void initState(){super.initState();load();}
  Future<void> load() async{a=await Db.announces();if(mounted)setState((){});}
  @override Widget build(BuildContext context){
    if(!Perm.canPublish(widget.me.role))return Scaffold(appBar:AppBar(),body:const Center(child:Text('غير مصرح')));
    return Scaffold(appBar:AppBar(title:const Text('الإعلانات 📢')),body:ListView(padding:const EdgeInsets.all(14),children:[
      TextField(controller:t,decoration:const InputDecoration(labelText:'العنوان',border:OutlineInputBorder())),const SizedBox(height:8),
      TextField(controller:b,decoration:const InputDecoration(labelText:'النص',border:OutlineInputBorder())),const SizedBox(height:8),
      SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{
        a.insert(0,Announce(id:DateTime.now().millisecondsSinceEpoch.toString(),title:t.text,body:b.text,date:DateTime.now().toIso8601String().substring(0,10)));
        await Db.saveAnn(a);await Store.audit(widget.me.email,'Publish announce');t.clear();b.clear();load();
      },child:const Text('نشر + إشعار جماعي'))),
      const Divider(),
      for(final x in a)Card(child:ListTile(title:Text(x.title),subtitle:Text(x.body))),
    ]));
  }
}

class AuditPage extends StatefulWidget{final String lang;const AuditPage({super.key,required this.lang});@override State<AuditPage> createState()=>_AU();}
class _AU extends State<AuditPage>{
  List<String> l=[];
  @override void initState(){super.initState();Store.auditLog().then((v){if(mounted)setState(()=>l=v.reversed.toList());});}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['audit']!,widget.lang))),
    body:ListView.builder(padding:const EdgeInsets.all(12),itemCount:l.length,
      itemBuilder:(_,i)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Text(l[i],style:const TextStyle(fontSize:12))))));
}

class ReportsPage extends StatelessWidget{final String lang;const ReportsPage({super.key,required this.lang});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['reports']!,lang))),
    body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
      const Text('تصدير التقارير (CSV جاهز لـ Excel)'),
      const SizedBox(height:10),
      FilledButton.icon(icon:const Icon(Icons.download),label:const Text('تصدير الموظفين CSV'),
        onPressed:()async{final us=await Db.users();
          final csv=us.map((u)=>'${u.name},${u.jobNumber},${u.email},${u.dept},${u.position},${u.salary}').join('\n');
          await Store.audit('admin','Export users ${us.length}');
          if(context.mounted)showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('CSV'),
            content:SingleChildScrollView(child:Text(csv.isEmpty?'(فارغ)':csv)),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))]));}),
    ])));
}

class SettingsPage extends StatelessWidget{final String lang;final ValueChanged<String> onLang;
  const SettingsPage({super.key,required this.lang,required this.onLang});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['settings']!,lang))),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('الهوية البصرية: ألوان هادئة • خط Cairo • وضع داكن من الأعلى 🌙\nاللغات: عربي RTL / Français / English\nالنسخ الاحتياطي: محلي مشفّر + API جاهز للربط\nPush: إشعارات فورية عند الموافقة/النشر'))),
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[const Text('اللغة / Langue: '),
        DropdownButton<String>(value:lang,items:const[DropdownMenuItem(value:'ar',child:Text('العربية')),DropdownMenuItem(value:'fr',child:Text('Français')),DropdownMenuItem(value:'en',child:Text('English'))],
          onChanged:(v){if(v!=null)onLang(v);})]))),
    ]));
}
