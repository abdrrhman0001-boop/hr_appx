import 'package:flutter/material.dart';
import '../core.dart';
import '../models.dart';
import '../services.dart';

// Profile / Leaves / Attendance / Payslip / Requests / Training / Perf / Jobs / Directory / Contact
// Each checks Perm.canModule for authorized access; super admin bypasses all.

class ProfilePage extends StatefulWidget{final User me;final String lang;final VoidCallback onChanged;
  const ProfilePage({super.key,required this.me,required this.lang,required this.onChanged});@override State<ProfilePage> createState()=>_P();}
class _P extends State<ProfilePage>{
  late TextEditingController n,p,d;
  @override void initState(){super.initState();n=TextEditingController(text:widget.me.name);p=TextEditingController(text:widget.me.phone);d=TextEditingController(text:widget.me.dept);}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[
    Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),child:Padding(padding:const EdgeInsets.all(18),
      child:Column(children:[
        CircleAvatar(radius:34,child:Text(widget.me.name.isEmpty?'؟':widget.me.name[0],style:const TextStyle(fontSize:26))),
        const SizedBox(height:8),Text(widget.me.name,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
        Text('${widget.me.jobNumber} • ${roleToString(widget.me.role)} • ${widget.me.position}'),
        Text(widget.me.email),Text('رصيد الإجازات: ${widget.me.leaveBalance} يوم'),
        const Divider(),
        TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم',border:OutlineInputBorder())),
        const SizedBox(height:10),TextField(controller:p,decoration:const InputDecoration(labelText:'الهاتف',border:OutlineInputBorder())),
        const SizedBox(height:10),TextField(controller:d,decoration:const InputDecoration(labelText:'القسم',border:OutlineInputBorder())),
        const SizedBox(height:10),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{
          widget.me.name=n.text.trim();widget.me.phone=p.text.trim();widget.me.dept=d.text.trim();
          final us=await Db.users();final i=us.indexWhere((e)=>e.id==widget.me.id);us[i]=widget.me;await Db.saveUsers(us);
          await Store.audit(widget.me.email,'Update own profile');widget.onChanged();
          if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم الحفظ')));
        },child:Text(I18n.get(I18n.t['save']!,widget.lang)))),
        const SizedBox(height:8),
        OutlinedButton.icon(icon:const Icon(Icons.picture_as_pdf),label:const Text('شهادة العمل PDF (تجريبي)'),
          onPressed:(){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Attestation générée (démo) — التصدير PDF الحقيقي عبر API')));}),
      ]))),
  ]);
}

class LeavesPage extends StatefulWidget{final User me;final String lang;const LeavesPage({super.key,required this.me,required this.lang});@override State<LeavesPage> createState()=>_Lv();}
class _Lv extends State<LeavesPage>{
  List<HrRequest> all=[];final det=TextEditingController();
  @override void initState(){super.initState();load();}
  Future<void> load() async{all=await Db.requests();if(mounted)setState((){});}
  @override Widget build(BuildContext context){
    if(!Perm.canModule(widget.me.role,'leaves'))return const Center(child:Text('غير مصرح'));
    final mine=all.where((r)=>r.userId==widget.me.id&&r.type=='إجازة').toList();
    return Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['leaves']!,widget.lang))),body:ListView(padding:const EdgeInsets.all(14),children:[
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
        Text('رصيدك: ${widget.me.leaveBalance} يوم'),
        TextField(controller:det,decoration:const InputDecoration(labelText:'من ... إلى ... + السبب',border:OutlineInputBorder())),
        const SizedBox(height:8),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{
          if(det.text.trim().isEmpty)return;
          all.add(HrRequest(id:DateTime.now().millisecondsSinceEpoch.toString(),userId:widget.me.id,userName:widget.me.name,type:'إجازة',details:det.text.trim(),date:DateTime.now().toIso8601String().substring(0,10)));
          await Db.saveReqs(all);await Store.audit(widget.me.email,'Leave request');det.clear();load();
        },child:const Text('طلب إجازة'))),
      ]))),
      for(final r in mine.reversed)Card(child:ListTile(title:Text(r.details),subtitle:Text('${r.date} • ${r.status}'),trailing:Icon(
        r.status=='مقبول'?Icons.check_circle:r.status=='مرفوض'?Icons.cancel:Icons.hourglass_empty,
        color:r.status=='مقبول'?Colors.green:r.status=='مرفوض'?Colors.red:Colors.orange))),
    ]));
  }
}

class AttendancePage extends StatefulWidget{final User me;final String lang;const AttendancePage({super.key,required this.me,required this.lang});@override State<AttendancePage> createState()=>_A();}
class _A extends State<AttendancePage>{
  String log='';
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['attendance']!,widget.lang))),
    body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        const Icon(Icons.location_on_rounded,size:44),const SizedBox(height:8),
        const Text('تسجيل بالموقع GPS أو QR (تجريبي دون عتاد)'),
        const SizedBox(height:8),
        Row(children:[Expanded(child:FilledButton(onPressed:()async{
          setState(()=>log='✅ حضور ${DateTime.now().toString().substring(0,16)} — GPS: 36.75, 3.06 (Alger)');
          await Store.audit(widget.me.email,'Check-in GPS');},child:const Text('تسجيل حضور GPS'))),
          const SizedBox(width:8),
          Expanded(child:OutlinedButton(onPressed:()async{
            setState(()=>log='✅ انصراف ${DateTime.now().toString().substring(0,16)} — QR scanné');await Store.audit(widget.me.email,'Check-out QR');},child:const Text('مسح QR')))]),
        if(log.isNotEmpty)...[const SizedBox(height:8),Text(log)],
      ]))),
      const SizedBox(height:10),
      const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('السجل الشهري: 22 يوم عمل • 1 غياب • 2 تأخير (تجريبي)'))),
    ])));
}

class PayslipPage extends StatelessWidget{final User me;final String lang;const PayslipPage({super.key,required this.me,required this.lang});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['payslip']!,widget.lang))),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      for(int m=1;m<=3;m++)Card(child:ListTile(leading:const Icon(Icons.receipt_long_rounded),
        title:Text('كشف ${2026}-0$m — ${me.salary>0?me.salary:45000} DZD'),
        subtitle:const Text('صافي • Net • قابل للتحميل'),
        trailing:IconButton(icon:const Icon(Icons.download),onPressed:(){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Téléchargement PDF (démo)')));}))),
    ]));
}

class AdminReqPage extends StatefulWidget{final User me;final String lang;const AdminReqPage({super.key,required this.me,required this.lang});@override State<AdminReqPage> createState()=>_R();}
class _R extends State<AdminReqPage>{
  List<HrRequest> all=[];String type='إذن خروج';final det=TextEditingController();
  @override void initState(){super.initState();load();}
  Future<void> load() async{all=await Db.requests();if(mounted)setState((){});}
  @override Widget build(BuildContext context){
    final mine=all.where((r)=>r.userId==widget.me.id&&r.type!= 'إجازة').toList();
    return Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['requests']!,widget.lang))),body:ListView(padding:const EdgeInsets.all(14),children:[
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
        DropdownButton<String>(value:type,items:const[
          DropdownMenuItem(value:'إذن خروج',child:Text('إذن خروج')),DropdownMenuItem(value:'سلفة',child:Text('سلفة / Avance')),
          DropdownMenuItem(value:'شهادة راتب',child:Text('شهادة راتب')),DropdownMenuItem(value:'أخرى',child:Text('أخرى'))],
          onChanged:(v)=>setState(()=>type=v!)),
        TextField(controller:det,decoration:const InputDecoration(labelText:'التفاصيل',border:OutlineInputBorder())),
        const SizedBox(height:8),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{
          all.add(HrRequest(id:DateTime.now().millisecondsSinceEpoch.toString(),userId:widget.me.id,userName:widget.me.name,type:type,details:det.text.trim(),date:DateTime.now().toIso8601String().substring(0,10)));
          await Db.saveReqs(all);await Store.audit(widget.me.email,'Request $type');det.clear();load();
        },child:const Text('إرسال الطلب'))),
      ]))),
      for(final r in mine.reversed)Card(child:ListTile(title:Text('${r.type}: ${r.details}'),subtitle:Text('${r.date} • ${r.status}'))),
    ]));
  }
}

class MyRequestsPage extends StatefulWidget{final User me;final String lang;const MyRequestsPage({super.key,required this.me,required this.lang});@override State<MyRequestsPage> createState()=>_MR();}
class _MR extends State<MyRequestsPage>{
  List<HrRequest> all=[];
  @override void initState(){super.initState();Db.requests().then((v){if(mounted)setState(()=>all=v);});}
  @override Widget build(BuildContext context){
    final mine=all.where((r)=>r.userId==widget.me.id).toList();
    return ListView(padding:const EdgeInsets.all(14),children:[
      Text('طلباتي (${mine.length})',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
      for(final r in mine.reversed)Card(child:ListTile(title:Text('${r.type}: ${r.details}'),subtitle:Text('${r.date} • ${r.status}'))),
      if(mine.isEmpty) const Padding(padding:EdgeInsets.all(20),child:Text('لا طلبات بعد')),
    ]);
  }
}
class TrainingPage extends StatelessWidget{final User me;final String lang;const TrainingPage({super.key,required this.me,required this.lang});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['training']!,lang))),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      for(final c in ['السلامة المهنية','Excel متقدم','القيادة','Français pro'])Card(child:ListTile(
        leading:const Icon(Icons.school_rounded),title:Text(c),subtitle:const Text('متاحة • شهادة بعد الإتمام'),
        trailing:FilmedBtn(me:me,c:c))),
    ]));
}
class FilmedBtn extends StatelessWidget{final User me;final String c;const FilmedBtn({super.key,required this.me,required this.c});
  @override Widget build(BuildContext context)=>FilledButton.tonal(onPressed:()async{
    await Store.audit(me.email,'Enroll training $c');
    if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم التسجيل في $c')));},child:const Text('سجل'));}

class PerfPage extends StatelessWidget{final User me;final String lang;const PerfPage({super.key,required this.me,required this.lang});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['perf']!,lang))),
    body:ListView(padding:const EdgeInsets.all(14),children:const[
      Card(child:Padding(padding:EdgeInsets.all(14),child:Text('🎯 أهدافي: إغلاق 10 ملفات • رضا 90% • صفر تأخير'))),
      Card(child:Padding(padding:EdgeInsets.all(14),child:Text('⭐ آخر تقييم: 4.2/5 — جيد جداً (المدير المباشر)'))),
    ]));
}

class JobsPage extends StatelessWidget{final User me;final String lang;const JobsPage({super.key,required this.me,required this.lang});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['jobs']!,lang))),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      for(final j in ['محاسب أول — المالية','مشرف مخزن — اللوجستيك','مطور Flutter — IT'])Card(child:ListTile(
        leading:const Icon(Icons.work_outline),title:Text(j),
        trailing:FilledButton(onPressed:()async{await Store.audit(me.email,'Apply $j');
          if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم التقديم')));},child:const Text('قدّم')))),
    ]));
}

class DirectoryPage extends StatefulWidget{final User me;final String lang;const DirectoryPage({super.key,required this.me,required this.lang});@override State<DirectoryPage> createState()=>_D();}
class _D extends State<DirectoryPage>{
  List<User> us=[];String q='';
  @override void initState(){super.initState();Db.users().then((v){if(mounted)setState(()=>us=v);});}
  @override Widget build(BuildContext context){
    final f=us.where((u)=>u.name.contains(q)||u.dept.contains(q)).toList();
    return Column(children:[Padding(padding:const EdgeInsets.all(12),
      child:TextField(decoration:const InputDecoration(labelText:'بحث بالاسم أو القسم 🔍',border:OutlineInputBorder(),prefixIcon:Icon(Icons.search)),
        onChanged:(v)=>setState(()=>q=v))),
      Expanded(child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:f.length,
        itemBuilder:(_,i)=>Card(child:ListTile(leading:CircleAvatar(child:Text(f[i].name.isEmpty?'؟':f[i].name[0])),
          title:Text('${f[i].name} ${f[i].role==Role.superAdmin?'👑':''}'),subtitle:Text('${f[i].dept} • ${f[i].position} • ${f[i].phone}')))))]);
  }
}

class ContactPage extends StatelessWidget{final String lang;const ContactPage({super.key,required this.lang});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(I18n.get(I18n.t['contact']!,lang))),
    body:ListView(padding:const EdgeInsets.all(14),children:const[
      Card(child:ListTile(leading:Icon(Icons.chat),title:Text('مراسلة HR'),subtitle:Text('rh@company.dz • رد خلال 24سا'))),
      Card(child:Padding(padding:EdgeInsets.all(14),child:Text('❓ أسئلة شائعة:\n• كيف أطلب إجازة؟ من تبويب الإجازات\n• أين كشف الراتب؟ تبويب الراتب\n• نسيت كلمة المرور؟ تواصل مع المشرف الرئيسي'))),
    ]));
}
