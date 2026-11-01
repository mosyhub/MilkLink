import 'donor_model.dart';

class PatientModel {
  final String id;
  final String name;
  final String motherName;
  final String phone;
  final String patientType;
  final HomeAddress homeAddress;
  final String? age;
  final String? aog;
  final DateTime? admissionDate;
  final String? staffId;
  final String? staffName;
  final String? userId;
  final String? userName;
  final Map<String, dynamic>? intakeQuestionnaire;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.motherName,
    required this.phone,
    required this.patientType,
    required this.homeAddress,
    this.age,
    this.aog,
    this.admissionDate,
    this.staffId,
    this.staffName,
    this.userId,
    this.userName,
    this.intakeQuestionnaire,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
  });

  bool get isClaimed => userId != null && userId!.isNotEmpty;
  String get claimStatus => isClaimed ? 'Claimed / Linked' : 'Unclaimed';

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? sId;
    if (json['staff'] is Map) {
      final s = json['staff'];
      sId = s['_id'];
      if (s['name'] is Map) {
        sName = '${s['name']['first'] ?? ''} ${s['name']['last'] ?? ''}'.trim();
      } else if (s['username'] != null) {
        sName = s['username'];
      }
    } else if (json['staff'] is String) {
      sId = json['staff'];
    }

    String? uName;
    String? uId;
    if (json['user'] is Map) {
      final u = json['user'];
      uId = u['_id'];
      if (u['name'] is Map) {
        uName = '${u['name']['first'] ?? ''} ${u['name']['last'] ?? ''}'.trim();
      } else if (u['username'] != null) {
        uName = u['username'];
      }
    } else if (json['user'] is String) {
      uId = json['user'];
    }

    return PatientModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      motherName: json['motherName'] ?? '',
      phone: json['phone'] ?? '',
      patientType: json['patientType'] ?? 'Inpatient',
      homeAddress: json['home_address'] is Map<String, dynamic>
          ? HomeAddress.fromJson(json['home_address'])
          : HomeAddress(street: '', brgy: '', city: ''),
      age: json['age']?.toString(),
      aog: json['aog']?.toString(),
      admissionDate: json['admissionDate'] != null ? DateTime.tryParse(json['admissionDate']) : null,
      staffId: sId,
      staffName: sName,
      userId: uId,
      userName: uName,
      intakeQuestionnaire: json['intakeQuestionnaire'] is Map<String, dynamic> ? json['intakeQuestionnaire'] : null,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'motherName': motherName,
      'phone': phone,
      'patientType': patientType,
      'home_address': homeAddress.toJson(),
      if (age != null) 'age': age,
      if (aog != null) 'aog': aog,
      if (admissionDate != null) 'admissionDate': admissionDate!.toIso8601String(),
      if (userId != null) 'user': userId,
    };
  }
}
