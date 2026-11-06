// Core: roles, i18n, local store + audit
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum Role { employee, manager, hr, superAdmin }

Role roleFromString(String s) {
  switch (s) {
    case 'manager': return Role.manager;
    case 'hr': return Role.hr;
    case 'superAdmin': return Role.superAdmin;
    default: return Role.employee;
  }
}
String roleToString(Role r) {
  switch (r) {
    case Role.manager: return 'manager';
    case Role.hr: return 'hr';
    case Role.superAdmin: return 'superAdmin';
    default: return 'employee';
  }
}

// ---------- Permissions ----------
class Perm {
  static bool isSuper(Role r) => r == Role.superAdmin;
  // Super admin: everything. HR: almost everything except audit/settings/delete-super.
  static bool canSeeAll(Role r) => r == Role.superAdmin || r == Role.hr;
  static bool canManageUsers(Role r) => r == Role.superAdmin || r == Role.hr;
  static bool canApprove(Role r) => r == Role.superAdmin || r == Role.hr || r == Role.manager;
  static bool canPublish(Role r) => r == Role.superAdmin || r == Role.hr;
  static bool canAudit(Role r) => r == Role.superAdmin;
  static bool canSettings(Role r) => r == Role.superAdmin;
  static bool canModule(Role r, String module) {
    if (r == Role.superAdmin) return true;
    // employee allowed modules (authorized ones)
    const emp = {'home','profile','leaves','attendance','payslip','requests','training','performance','jobs','directory','contact'};
    if (r == Role.employee) return emp.contains(module);
    if (r == Role.manager) return true; // manager sees team + own, audit blocked below
    if (r == Role.hr) return module != 'audit' && module != 'settings' ? true : (module == 'audit' ? false : module == 'settings' ? false : true);
    return true;
  }
}

// ---------- Trilingual strings ----------
class I18n {
  static const langs = ['ar','fr','en'];
  static String get(Map<String,String> m, String lang) => m[lang] ?? m['ar'] ?? '';
  static final Map<String, Map<String,String>> t = {
    'appName': {'ar':'موارد بشرية — فريقنا','fr':'RH — Notre Équipe','en':'HR — Our Team'},
    'login': {'ar':'تسجيل الدخول الآمن','fr':'Connexion sécurisée','en':'Secure login'},
    'emailOrId': {'ar':'البريد / الرقم الوظيفي','fr':'Email / Matricule','en':'Email / Job No'},
    'password': {'ar':'كلمة المرور','fr':'Mot de passe','en':'Password'},
    'biometric': {'ar':'دخول بالبصمة / الوجه','fr':'Empreinte / Visage','en':'Fingerprint / Face'},
    'enter': {'ar':'دخول','fr':'Entrer','en':'Login'},
    'register': {'ar':'إنشاء حساب (الأول = مشرف رئيسي 👑)','fr':'Créer un compte (1er = Super Admin)','en':'Register (1st = Super Admin)'},
    'home': {'ar':'الرئيسية','fr':'Accueil','en':'Home'},
    'requests': {'ar':'الطلبات','fr':'Demandes','en':'Requests'},
    'directory': {'ar':'الدليل','fr':'Annuaire','en':'Directory'},
    'profile': {'ar':'حسابي','fr':'Profil','en':'Profile'},
    'admin': {'ar':'المشرف','fr':'Admin','en':'Admin'},
    'announce': {'ar':'إعلانات الشركة','fr':'Annonces','en':'Announcements'},
    'quick': {'ar':'اختصارات سريعة','fr':'Accès rapides','en':'Quick access'},
    'leaves': {'ar':'الإجازات','fr':'Congés','en':'Leaves'},
    'attendance': {'ar':'الحضور والانصراف','fr':'Présence','en':'Attendance'},
    'payslip': {'ar':'كشف الراتب','fr':'Bulletin de paie','en':'Payslip'},
    'training': {'ar':'التدريب','fr':'Formation','en':'Training'},
    'perf': {'ar':'تقييم الأداء','fr':'Performance','en':'Performance'},
    'jobs': {'ar':'التوظيف الداخلي','fr':'Recrutement interne','en':'Internal jobs'},
    'contact': {'ar':'تواصل مع HR','fr':'Contacter RH','en':'Contact HR'},
    'dashboard': {'ar':'لوحة التحكم الشاملة','fr':'Tableau de bord','en':'Dashboard'},
    'users': {'ar':'إدارة المستخدمين','fr':'Utilisateurs','en':'Users'},
    'addWorker': {'ar':'إضافة عامل','fr':'Ajouter employé','en':'Add worker'},
    'approvals': {'ar':'الموافقات','fr':'Approbations','en':'Approvals'},
    'audit': {'ar':'سجل العمليات','fr':'Journal d’audit','en':'Audit log'},
    'reports': {'ar':'التقارير','fr':'Rapports','en':'Reports'},
    'settings': {'ar':'إعدادات التطبيق','fr':'Paramètres','en':'Settings'},
    'save': {'ar':'حفظ','fr':'Enregistrer','en':'Save'},
    'logout': {'ar':'خروج','fr':'Déconnexion','en':'Logout'},
  };
}

// ---------- Local store (offline-first, obfuscated) ----------
class Store {
  static Future<SharedPreferences> get _p async => SharedPreferences.getInstance();
  static String _enc(String s) => base64Encode(utf8.encode(s)); // placeholder for AES in prod
  static String _dec(String s) { try { return utf8.decode(base64Decode(s)); } catch(_) { return s; } }
  static Future<void> write(String key, String json) async {
    final p = await _p; await p.setString(key, _enc(json));
  }
  static Future<String?> read(String key) async {
    final p = await _p; final v = p.getString(key); if (v==null) return null; return _dec(v);
  }
  static Future<void> audit(String actor, String action) async {
    final p = await _p;
    final list = p.getStringList('audit') ?? [];
    list.add('${DateTime.now().toIso8601String()} | $actor | $action');
    if (list.length > 500) list.removeAt(0);
    await p.setStringList('audit', list);
  }
  static Future<List<String>> auditLog() async {
    final p = await _p; return p.getStringList('audit') ?? [];
  }
}
