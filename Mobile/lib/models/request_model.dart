class RequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientType;
  final String diagnosis;
  final String reason;
  final String doctor;
  final String hospital;
  final String? department;
  final double volume;
  final int days;
  final String status;
  final DateTime? date;
  final String? comment;
  final String? requestedByName;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;

  RequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientType,
    required this.diagnosis,
    required this.reason,
    required this.doctor,
    required this.hospital,
    this.department,
    required this.volume,
    required this.days,
    required this.status,
    this.date,
    this.comment,
    this.requestedByName,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
  });

  String get location => department?.isNotEmpty == true ? department! : hospital;
  String get requestingPhysician => doctor;
  String get hospitalName => hospital;
  double get volumeRequestedMl => volume;

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    String pId = '';
    String pName = '';
    String pType = json['type'] ?? 'Inpatient';

    if (json['patient'] is Map) {
      final p = json['patient'];
      pId = p['_id'] ?? '';
      pName = p['name'] ?? 'Unnamed Patient';
      if (p['patientType'] != null) pType = p['patientType'];
    } else if (json['patient'] is String) {
      pId = json['patient'];
      pName = 'Patient #$pId';
    }

    String? reqName;
    if (json['requestedBy'] is Map) {
      final u = json['requestedBy'];
      if (u['name'] is Map) {
        reqName = '${u['name']['first'] ?? ''} ${u['name']['last'] ?? ''}'.trim();
      }
    }

    double vol = 0.0;
    int dys = 1;
    if (json['volumeRequested'] is Map) {
      final vr = json['volumeRequested'];
      vol = vr['volume'] != null ? (vr['volume'] as num).toDouble() : 0.0;
      dys = vr['days'] != null ? (vr['days'] as num).toInt() : 1;
    }

    return RequestModel(
      id: json['_id'] ?? '',
      patientId: pId,
      patientName: pName,
      patientType: pType,
      diagnosis: json['diagnosis'] ?? 'N/A',
      reason: json['reason'] ?? 'N/A',
      doctor: json['doctor'] ?? 'N/A',
      hospital: json['hospital'] ?? 'Pasig-Pateros District Hospital',
      department: json['department'],
      volume: vol,
      days: dys,
      status: json['status'] ?? 'Pending',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      comment: json['comment'],
      requestedByName: reqName,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient': patientId,
      'patientType': patientType,
      'diagnosis': diagnosis,
      'reason': reason,
      'doctor': doctor,
      'hospital': hospital,
      if (department != null) 'department': department,
      'volumeRequested': {
        'volume': volume,
        'days': days,
      },
      'status': status,
      if (date != null) 'date': date!.toIso8601String(),
      if (comment != null) 'comment': comment,
    };
  }
}

