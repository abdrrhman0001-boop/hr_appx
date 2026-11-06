import 'package:flutter/material.dart';
import '../core.dart';
import '../models.dart';
import '../services.dart';
import '../widgets_ui.dart';
import 'screens_employee.dart';
import 'screens_admin.dart';

class Splash extends StatefulWidget{const Splash({super.key});@override State<Splash> createState()=>_Sp();}
class _Sp extends State<Splash>{
  @override void initState(){super.initState();Future.delayed(const Duration(milliseconds:800),()async{
    final u=await Auth.current(); if(!mounted)return;
    Navigator.pushReplacement(context,modernRoute(u==null?const Login():Shell(me:u)));});}
  @override Widget build(BuildContext context)=>Scaffold(body:Container(
    decoration:BoxDecoration(gradient:LinearGradient(colors:[Theme.of(context).colorScheme.primary,Theme.of(context).colorScheme.tertiary],begin:Alignment.topRight,end:Alignment.bottomLeft)),
    child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(Icons.business_center_rounded,size:76,color:Colors.white),SizedBox(height:10),
      Text('فريقنا | Our Team',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.bold)),
      SizedBox(height:10),CircularProgressIndicator(color:Colors.white)]))));
}

class Login extends StatefulWidget{const Login({super.key});@override State<Login> createState()=>_L();}
class _L extends State<Login>{
  final idC=TextEditingController(),pwC=TextEditingController(),nmC=TextEditingController();
  bool isLogin=true,load=false; String? err; bool bioOk=false;
  Future<void> submit() async{
    setState(()=>load=true); String? e;
    if(isLogin){e=await Auth.login(idC.text.trim(),pwC.text);}
    else{if(nmC.text.trim().isEmpty)e='أدخل الاسم';else e=await Auth.register(nmC.text.trim(),idC.text.trim(),pwC.text);}
    setState(()=>load=false);
    if(e!=null){setState(()=>err=e);return;}
    final u=await Auth.current(); if(u!=null&&mounted)Navigator.pushReplacement(context,modernRoute(Shell(me:u)));
  }
  @override Widget build(BuildContext context)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),
    child:Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),elevation:8,
      child:Padding(padding:const EdgeInsets.all(22),child:Column(children:[
        const Icon(Icons.fingerprint_rounded,size:56),const SizedBox(height:6),
        Text(I18n.t['login']!['ar']!,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        const Text('الأول = مشرف رئيسي 👑 |ar/fr/en| بصمة أو وجه',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.grey)),
        const SizedBox(height:14),
        if(!isLogin)TextField(controller:nmC,decoration:const InputDecoration(labelText:'الاسم / Nom',border:OutlineInputBorder(),prefixIcon:Icon(Icons.person))),
        if(!isLogin)const SizedBox(height:10),
        TextField(controller:idC,decoration:InputDecoration(labelText:I18n.t['emailOrId']!['ar'],border:const OutlineInputBorder(),prefixIcon:const Icon(Icons.badge))),
        const SizedBox(height:10),
        TextField(controller:pwC,obscureText:true,decoration:InputDecoration(labelText:I18n.t['password']!['ar'],border:const OutlineInputBorder(),prefixIcon:const Icon(Icons.lock))),
        if(err!=null)...[const SizedBox(height:8),Text(err!,style:const TextStyle(color:Colors.red))],
        const SizedBox(height:12),
        SizedBox(width:double.infinity,child: FilledButton(onPressed:load?null:submit,child:Text(load?'...':(isLogin?'دخول':'تسجيل')))),
        const SizedBox(height:6),
        SizedBox(width:double.infinity,child:OutlinedButton.icon(icon:const Icon(Icons.fingerprint),
          label:Text(I18n.t['biometric']!['ar']),
          onPressed:()async{ // simulated biometric: if a session existed or demo pass
            final u=await Auth.current();
            if(u!=null&&mounted){Navigator.pushReplacement(context,modernRoute(Shell(me:u)));}
            else{setState(()=>bioOk=!bioOk);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('البصمة مفعّلة تجريبياً — سجل الدخول أول مرة ثم استعملها')));}
          })),
        TextButton(onPressed:()=>setState(()=>isLogin=!isLogin),
          child:Text(isLogin?'ليس لديك حساب؟ سجل':'لديك حساب؟ دخول')),
      ]))))));
}

// Shell with drawer + bottom nav + lang + dark
class Shell extends StatefulWidget{final User me;const Shell({super.key,required this.me});@override State<Shell> createState()=>_S();}
class _S extends State<Shell>{
  late User me; int idx=0; final pager=PageController();
  String lang='ar'; bool dark=false;
  @override void initState(){super.initState();me=widget.me;}
  void go(int i){setState(()=>idx=i);pager.animateToPage(i,duration:const Duration(milliseconds:320),curve:Curves.easeOutCubic);}
  Future<void> refresh() async{final u=await Auth.current();if(u!=null&&mounted)setState(()=>me=u);}
  @override Widget build(BuildContext context){
    final showAdmin=me.role==Role.superAdmin;
    final pages=[HomePage(me:me,lang:lang,onOpen:openModule),
      MyRequestsPage(me:me,lang:lang),
      DirectoryPage(me:me,lang:lang),
      ProfilePage(me:me,lang:lang,onChanged:refresh),
      if(showAdmin)AdminDash(me:me,lang:lang,onOpen:openModule)];
    return Scaffold(
      appBar:AppBar(title:Text('${I18n.get(I18n.t['appName']!,lang)} • ${me.name}${me.role==Role.superAdmin?' 👑':''}'),centerTitle:true,
        actions:[IconButton(icon:Icon(dark?Icons.light_mode:Icons.dark_mode),
          onPressed:(){setState(()=>dark=!dark);(context as Element).visitAncestorElements((e){if(e.widget is HrAppCtl){(e.widget as HrAppCtl).toggle();return false;}return true;});}),
          IconButton(icon:const Icon(Icons.logout),onPressed:()async{await Auth.logout();if(context.mounted)Navigator.pushReplacement(context,modernRoute(const Login()));})]),
      drawer:AppDrawer(me:me,lang:lang,onLang:(l)=>setState(()=>lang=l),onOpen:openModule),
      body:Column(children:[Expanded(child:PageView(controller:pager,physics:const BouncingScrollPhysics(),
        onPageChanged:(i)=>setState(()=>idx=i),children:pages)),
        ModernNav(index:idx,onTap:go,showAdmin:showAdmin,lang:lang)]),
    );
  }
  void openModule(String m){
    Navigator.popIfNeeded(context);
    Widget? p;
    if(m=='leaves')p=LeavesPage(me:me,lang:lang);
    else if(m=='attendance')p=AttendancePage(me:me,lang:lang);
    else if(m=='payslip')p=PayslipPage(me:me,lang:lang);
    else if(m=='requests')p=AdminReqPage(me:me,lang:lang);
    else if(m=='training')p=TrainingPage(me:me,lang:lang);
    else if(m=='perf')p=PerfPage(me:me,lang:lang);
    else if(m=='jobs')p=JobsPage(me:me,lang:lang);
    else if(m=='contact')p=ContactPage(lang:lang);
    else if(m=='users')p=UsersPage(me:me,lang:lang);
    else if(m=='addWorker')p=AddWorkerPage(me:me,lang:lang);
    else if(m=='approvals')p=ApprovalsPage(me:me,lang:lang);
    else if(m=='announce-mgr')p=AnnounceMgrPage(me:me,lang:lang);
    else if(m=='audit')p=AuditPage(lang:lang);
    else if(m=='reports')p=ReportsPage(lang:lang);
    else if(m=='settings')p=SettingsPage(lang:lang,onLang:(l)=>setState(()=>lang=l));
    if(p!=null)Navigator.push(context,modernRoute(Directionality(textDirection:lang=='ar'?TextDirection.rtl:TextDirection.ltr,child:p)));
  }
}

class HrAppCtl extends StatelessWidget{
  final VoidCallback toggle; final Widget child;
  const HrAppCtl({super.key,required this.toggle,required this.child});
  @override Widget build(BuildContext context)=>child;
}

class AppDrawer extends StatelessWidget{
  final User me; final String lang; final ValueChanged<String> onLang; final ValueChanged<String> onOpen;
  const AppDrawer({super.key,required this.me,required this.lang,required this.onLang,required this.onOpen});
  @override Widget build(BuildContext context){
    final mods=[
      ['home','🏠',I18n.t['home']!,'home'],
      ['leaves','🏖️',I18n.t['leaves']!,'leaves'],
      ['attendance','📍',I18n.t['attendance']!,'attendance'],
      ['payslip','💰',I18n.t['payslip']!,'payslip'],
      ['requests','📝',I18n.t['requests']!,'requests'],
      ['training','🎓',I18n.t['training']!,'training'],
      ['perf','⭐',I18n.t['perf']!,'perf'],
      ['jobs','💼',I18n.t['jobs']!,'jobs'],
      ['directory','📖',I18n.t['directory']!,'directory'],
      ['contact','💬',I18n.t['contact']!,'contact'],
      ['dashboard','📊',I18n.t['dashboard']!,'dashboard'],
      ['users','👥',I18n.t['users']!,'users'],
      ['addWorker','➕',I18n.t['addWorker']!,'addWorker'],
      ['approvals','✅',I18n.t['approvals']!,'approvals'],
      ['audit','🧾',I18n.t['audit']!,'audit'],
      ['reports','📤',I18n.t['reports']!,'reports'],
      ['settings','⚙️',I18n.t['settings']!,'settings'],
    ];
    return Drawer(child:ListView(children:[
      UserAccountsDrawerHeader(accountName:Text('${me.name} ${me.role==Role.superAdmin?'👑':''}'),
        accountEmail:Text('${me.email} • ${roleToString(me.role)} • ${me.jobNumber}'),
        currentAccountPicture:CircleAvatar(child:Text(me.name.isEmpty?'؟':me.name[0]))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:[
        const Text('Lang: '),DropdownButton<String>(value:lang,items:const[
          DropdownMenuItem(value:'ar',child:Text('العربية')),DropdownMenuItem(value:'fr',child:Text('Français')),DropdownMenuItem(value:'en',child:Text('English'))],
          onChanged:(v){if(v!=null)onLang(v);})])),
      const Divider(),
      for(final m in mods)
        if(Perm.canModule(me.role,(m[0] as String))||me.role==Role.superAdmin||(m[0]=='dashboard'&&Perm.canSeeAll(me.role)))
          ListTile(leading:Text(m[1] as String,style:const TextStyle(fontSize:20)),
            title:Text(I18n.get(m[2] as Map<String,String>,lang)),
            onTap:(){if((m[3] as String)=='home'){Navigator.pop(context);}else{onOpen(m[0] as String);}}),
    ]));
  }
}

class HomePage extends StatefulWidget{final User me;final String lang;final ValueChanged<String> onOpen;
  const HomePage({super.key,required this.me,required this.lang,required this.onOpen});@override State<HomePage> createState()=>_H();}
class _H extends State<HomePage>{
  List<Announce> anns=[];
  @override void initState(){super.initState();Db.announces().then((v){if(mounted)setState(()=>anns=v);});}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(14),children:[
    Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),
      child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(I18n.get(I18n.t['announce']!,widget.lang),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        for(final a in anns.take(3))ListTile(leading:const Icon(Icons.campaign_rounded),title:Text(a.title),subtitle:Text(a.body,maxLines:2)),
      ]))),
    const SizedBox(height:10),
    Text(I18n.get(I18n.t['quick']!,widget.lang),style:const TextStyle(fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:3,
      crossAxisSpacing:10,mainAxisSpacing:10,children:[
      _q(context,Icons.beach_access,'🏖️',()=>widget.onOpen('leaves')),
      _q(context,Icons.location_on,'📍',()=>widget.onOpen('attendance')),
      _q(context,Icons.payments,'💰',()=>widget.onOpen('payslip')),
      _q(context,Icons.edit_note,'📝',()=>widget.onOpen('requests')),
      _q(context,Icons.school,'🎓',()=>widget.onOpen('training')),
      _q(context,Icons.work,'💼',()=>widget.onOpen('jobs')),
    ]),
  ]);
  Widget _q(BuildContext c,IconData i,String e,VoidCallback t)=>Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),
    child:InkWell(borderRadius:BorderRadius.circular(18),onTap:t,child:Center(child:Column(mainAxisSize:MainAxisSize.min,
      children:[Text(e,style:const TextStyle(fontSize:26)),Icon(i,size:20),]))));
}
