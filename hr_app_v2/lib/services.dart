import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'core.dart';
import 'models.dart';

class Db {
  static Future<List<User>> users() async {
    final raw = await Store.read('users2');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e)=>User.fromJson(e)).toList();
  }
  static Future<void> saveUsers(List<User> u) async =>
    Store.write('users2', jsonEncode(u.map((e)=>e.toJson()).toList()));
  static Future<List<HrRequest>> requests() async {
    final raw = await Store.read('reqs2');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e)=>HrRequest.fromJson(e)).toList();
  }
  static Future<void> saveReqs(List<HrRequest> r) async =>
    Store.write('reqs2', jsonEncode(r.map((e)=>e.toJson()).toList()));
  static Future<List<Announce>> announces() async {
    final raw = await Store.read('ann2');
    if (raw == null) return [Announce(id:'1',title:'مرحباً بكم في فريقنا 🎉',body:'تم إطلاق قسم الموارد البشرية الجديد.',date:DateTime.now().toIso8601String().substring(0,10))];
    return (jsonDecode(raw) as List).map((e)=>Announce.fromJson(e)).toList();
  }
  static Future<void> saveAnn(List<Announce> a) async =>
    Store.write('ann2', jsonEncode(a.map((e)=>e.toJson()).toList()));
}

class Auth {
  static Future<User?> current() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString('session2'); if (id==null) return null;
    final us = await Db.users();
    try { return us.firstWhere((u)=>u.id==id); } catch(_){ return null; }
  }
  static Future<String?> register(String name,String emailOrJob,String pass) async {
    final us = await Db.users();
    final key = emailOrJob.trim();
    if (us.any((u)=>u.email.toLowerCase()==key.toLowerCase()||u.jobNumber==key)) return 'مسجل مسبقاً / Déjà inscrit';
    final first = us.isEmpty;
    final u = User(id:DateTime.now().millisecondsSinceEpoch.toString(), name:name,
      jobNumber:RegExp(r'^\d+$').hasMatch(key)?key:'EMP${us.length+1001}',
      email:key.contains('@')?key:'$key@company.dz', password:pass,
      role:first?Role.superAdmin:Role.employee,
      position:first?'مشرف رئيسي':'موظف', hireDate:DateTime.now().toIso8601String().substring(0,10));
    us.add(u); await Db.saveUsers(us);
    final p = await SharedPreferences.getInstance(); await p.setString('session2', u.id);
    await Store.audit(u.email, first?'First account = SuperAdmin created':'Register ${u.email}');
    return null;
  }
  static Future<String?> login(String emailOrJob,String pass) async {
    final us = await Db.users();
    try {
      final u = us.firstWhere((x)=>(x.email.toLowerCase()==emailOrJob.trim().toLowerCase()||x.jobNumber==emailOrJob.trim())&&x.password==pass);
      if (!u.active) return 'الحساب معطل / Compte désactivé';
      final p = await SharedPreferences.getInstance(); await p.setString('session2', u.id);
      await Store.audit(u.email, 'Login');
      return null;
    } catch(_){ return 'بيانات خاطئة / Identifiants invalides'; }
  }
  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance(); await p.remove('session2');
  }
  // Bulk import CSV: name,jobNumber,email,phone,dept,position,salary,managerId,leave
  static Future<int> importCsv(String csv, String actor) async {
    final us = await Db.users();
    int n=0;
    for (final line in const LineSplitter().convert(csv)) {
      if (line.trim().isEmpty) continue;
      final c = line.split(',');
      if (c.length<2) continue;
      final name=c[0].trim(); if(name.isEmpty) continue;
      final job=c.length>1?c[1].trim():'EMP${us.length+1001}';
      if (us.any((u)=>u.jobNumber==job)) continue;
      us.add(User(id:DateTime.now().millisecondsSinceEpoch.toString()+n.toString(),name:name,jobNumber:job,
        email:c.length>2?c[2].trim():'$job@company.dz',password:job,phone:c.length>3?c[3].trim():'',
        dept:c.length>4?c[4].trim():'عام',position:c.length>5?c[5].trim():'موظف',
        salary:c.length>6?double.tryParse(c[6].trim())??0:0,hireDate:DateTime.now().toIso8601String().substring(0,10),
        role:Role.employee));
      n++;
    }
    await Db.saveUsers(us);
    await Store.audit(actor, 'Bulk import $n workers');
    return n;
  }
}
