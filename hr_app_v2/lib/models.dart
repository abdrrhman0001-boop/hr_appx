import 'core.dart';

class User {
  String id, name, jobNumber, email, phone, dept, position, hireDate, managerId;
  double salary, leaveBalance;
  Role role; bool active;
  String password;
  User({required this.id, required this.name, required this.jobNumber,
    required this.email, required this.password, this.phone='', this.dept='عام',
    this.position='موظف', this.hireDate='', this.managerId='', this.salary=0,
    this.leaveBalance=30, this.role=Role.employee, this.active=true});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'jobNumber':jobNumber,'email':email,
    'phone':phone,'dept':dept,'position':position,'hireDate':hireDate,'managerId':managerId,
    'salary':salary,'leaveBalance':leaveBalance,'role':roleToString(role),'active':active,'password':password};
  factory User.fromJson(Map<String,dynamic> j)=>User(
    id:j['id']??'', name:j['name']??'', jobNumber:j['jobNumber']??'', email:j['email']??'',
    password:j['password']??'', phone:j['phone']??'', dept:j['dept']??'عام',
    position:j['position']??'موظف', hireDate:j['hireDate']??'', managerId:j['managerId']??'',
    salary:(j['salary']??0).toDouble(), leaveBalance:(j['leaveBalance']??30).toDouble(),
    role:roleFromString(j['role']??'employee'), active:j['active']??true);
}

class HrRequest {
  String id, userId, userName, type, details, status, date;
  HrRequest({required this.id, required this.userId, required this.userName,
    required this.type, required this.details, this.status='معلق', required this.date});
  Map<String,dynamic> toJson()=>{'id':id,'userId':userId,'userName':userName,'type':type,'details':details,'status':status,'date':date};
  factory HrRequest.fromJson(Map<String,dynamic> j)=>HrRequest(id:j['id'],userId:j['userId'],userName:j['userName'],
    type:j['type'],details:j['details'],status:j['status']??'معلق',date:j['date']);
}

class Announce {
  String id, title, body, date;
  Announce({required this.id, required this.title, required this.body, required this.date});
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'body':body,'date':date};
  factory Announce.fromJson(Map<String,dynamic> j)=>Announce(id:j['id'],title:j['title'],body:j['body'],date:j['date']);
}
