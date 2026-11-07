class ScreeningAppointmentModel {
  final String id;
  final String appointmentId;
  final String userId;
  final String? donorId;
  final String purpose;
  final DateTime appointmentDate;
  final String timeSlot;
  final String status;
  final String hospitalName;
  final String hospitalRoom;
  final String? assignedStaffName;
  final bool attendanceRecorded;
  final bool screeningCompleted;
  final String? donorNotes;
  final String? staffReviewNotes;
  final String? statusReason;
  final DateTime createdAt;

  ScreeningAppointmentModel({
    required this.id,
    required this.appointmentId,
    required this.userId,
    this.donorId,
    required this.purpose,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    required this.hospitalName,
    required this.hospitalRoom,
    this.assignedStaffName,
    this.attendanceRecorded = false,
    this.screeningCompleted = false,
    this.donorNotes,
    this.staffReviewNotes,
    this.statusReason,
    required this.createdAt,
  });

  bool get isActive =>
      status == 'Pending Confirmation' ||
      status == 'Confirmed' ||
      status == 'Rescheduled';

  bool get isConfirmed => status == 'Confirmed';
  bool get isPending => status == 'Pending Confirmation';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled =>
      status == 'Cancelled by User' || status == 'Rejected by Staff';

  factory ScreeningAppointmentModel.fromJson(Map<String, dynamic> json) {
    String? staffName;
    if (json['assignedStaff'] is Map) {
      final s = json['assignedStaff'];
      if (s['name'] is Map) {
        staffName = '${s['name']['first'] ?? ''} ${s['name']['last'] ?? ''}'.trim();
      } else {
        staffName = s['username']?.toString();
      }
    }

    String uId = '';
    if (json['user'] is Map) {
      uId = json['user']['_id']?.toString() ?? '';
    } else {
      uId = json['user']?.toString() ?? '';
    }

    String? dId;
    if (json['donor'] is Map) {
      dId = json['donor']['_id']?.toString();
    } else {
      dId = json['donor']?.toString();
    }

    return ScreeningAppointmentModel(
      id: json['_id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? 'APT-PENDING',
      userId: uId,
      donorId: dId,
      purpose: json['purpose']?.toString() ?? 'First-Time Donor Screening',
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.parse(json['appointmentDate'].toString())
          : DateTime.now(),
      timeSlot: json['timeSlot']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending Confirmation',
      hospitalName: json['hospital'] is Map && json['hospital']['name'] != null
          ? json['hospital']['name'].toString()
          : 'Pasig City Human Milk Bank / PPDH',
      hospitalRoom: json['hospital'] is Map && json['hospital']['room'] != null
          ? json['hospital']['room'].toString()
          : 'Room 204, Milk Bank Screening Clinic',
      assignedStaffName: staffName,
      attendanceRecorded: json['attendanceRecorded'] == true,
      screeningCompleted: json['screeningCompleted'] == true,
      donorNotes: json['donorNotes']?.toString(),
      staffReviewNotes: json['staffReviewNotes']?.toString(),
      statusReason: json['statusReason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}

class ScreeningTimeSlot {
  final String slotTime;
  final int capacity;
  final int booked;
  final int remaining;
  final bool isAvailable;

  ScreeningTimeSlot({
    required this.slotTime,
    required this.capacity,
    required this.booked,
    required this.remaining,
    required this.isAvailable,
  });

  factory ScreeningTimeSlot.fromJson(Map<String, dynamic> json) {
    return ScreeningTimeSlot(
      slotTime: json['slotTime']?.toString() ?? '',
      capacity: (json['capacity'] is num) ? (json['capacity'] as num).toInt() : 3,
      booked: (json['booked'] is num) ? (json['booked'] as num).toInt() : 0,
      remaining: (json['remaining'] is num) ? (json['remaining'] as num).toInt() : 0,
      isAvailable: json['isAvailable'] == true,
    );
  }
}
