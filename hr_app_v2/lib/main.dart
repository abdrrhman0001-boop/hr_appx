import 'package:flutter/material.dart';
import 'screens_auth_home.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const HrApp());}
class HrApp extends StatefulWidget{const HrApp({super.key});@override State<HrApp> createState()=>_H(); }
class _H extends State<HrApp>{
  bool dark=false;
  void toggle()=>setState(()=>dark=!dark);
  @override Widget build(BuildContext context)=>HrAppCtl(toggle:toggle,child:MaterialApp(
    title:'HR - فريقنا',debugShowCheckedModeBanner:false,
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xFF1B6EF3),brightness:Brightness.light,fontFamily:'Roboto'),
    darkTheme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xFF1B6EF3),brightness:Brightness.dark),
    themeMode:dark?ThemeMode.dark:ThemeMode.light,
    home:const Directionality(textDirection:TextDirection.rtl,child:Splash()),
  ));
}
