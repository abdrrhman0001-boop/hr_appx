import 'package:flutter/material.dart';

Route<T> modernRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 320),
  pageBuilder: (_,__,___)=>page,
  transitionsBuilder: (_,a,__,c){
    final cu = CurvedAnimation(parent:a,curve:Curves.easeOutCubic);
    return FadeTransition(opacity:cu, child:SlideTransition(
      position:Tween<Offset>(begin:const Offset(0,.05),end:Offset.zero).animate(cu),child:c));
  });

class ModernNav extends StatelessWidget {
  final int index; final ValueChanged<int> onTap; final bool showAdmin;
  final String lang;
  const ModernNav({super.key,required this.index,required this.onTap,required this.showAdmin,required this.lang});
  @override
  Widget build(BuildContext context){
    final labels = lang=='ar'?['الرئيسية','الطلبات','الدليل','حسابي',if(showAdmin)'المشرف']
      : lang=='fr'?['Accueil','Demandes','Annuaire','Profil',if(showAdmin)'Admin']
      : ['Home','Requests','Directory','Profile',if(showAdmin)'Admin'];
    final icons = [Icons.home_rounded,Icons.assignment_rounded,Icons.people_rounded,Icons.person_rounded,Icons.admin_panel_settings_rounded];
    return Container(
      margin:const EdgeInsets.fromLTRB(14,0,14,14), padding:const EdgeInsets.all(8),
      decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,
        borderRadius:BorderRadius.circular(24),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(.12),blurRadius:18,offset:const Offset(0,8))]),
      child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround, children:List.generate(labels.length,(i){
        final s=i==index;
        return GestureDetector(onTap:()=>onTap(i),
          child:AnimatedContainer(duration:const Duration(milliseconds:280),
            padding:EdgeInsets.symmetric(horizontal:s?14:10,vertical:10),
            decoration:BoxDecoration(color:s?Theme.of(context).colorScheme.primary:Colors.transparent,borderRadius:BorderRadius.circular(16)),
            child:Row(children:[Icon(icons[i],size:22,color:s?Theme.of(context).colorScheme.onPrimary:Theme.of(context).colorScheme.onSurface.withOpacity(.55)),
              if(s) Padding(padding:const EdgeInsets.only(left:6),child:Text(labels[i],style:TextStyle(color:Theme.of(context).colorScheme.onPrimary,fontWeight:FontWeight.bold,fontSize:12)))])));
      })));
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon; final String title; final String sub; final VoidCallback onTap;
  const SectionCard({super.key,required this.icon,required this.title,required this.sub,required this.onTap});
  @override
  Widget build(BuildContext context)=>Card(
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),
    child:InkWell(borderRadius:BorderRadius.circular(18),onTap:onTap,
      child:Padding(padding:const EdgeInsets.all(14),
        child:Row(children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),Text(sub,style:const TextStyle(color:Colors.grey,fontSize:12))]))]))));
}
