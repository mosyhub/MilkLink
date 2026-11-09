import 'package:intl/intl.dart';
import 'inventory_models.dart';

class RequestHistoryEntry {
  final String action;
  final String actorName;
  final DateTime timestamp;
  final String? notes;

  RequestHistoryEntry({
    required this.action,
    required this.actorName,
    required this.timestamp,
    this.notes,
  });

  String get formattedDate => DateFormat('MMM dd, yyyy hh:mm a').format(timestamp);

  factory RequestHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RequestHistoryEntry(
      action: json['action']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? 'Staff / Admin',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }
}

class ClinicalReview {
  final String? reviewedBy;
  final String? reviewerName;
  final DateTime? reviewDate;
  final String? assessmentNotes;
  final String? decision; // 'Eligible' | 'Not Eligible'

  ClinicalReview({
    this.reviewedBy,
    this.reviewerName,
    this.reviewDate,
    this.assessmentNotes,
    this.decision,
  });

  bool get isEligible => decision == 'Eligible';

  factory ClinicalReview.fromJson(Map<String, dynamic> json) {
    return ClinicalReview(
      reviewedBy: json['reviewedBy']?.toString(),
      reviewerName: json['reviewerName']?.toString(),
      reviewDate: json['reviewDate'] != null
          ? DateTime.tryParse(json['reviewDate'].toString())
          : null,
      assessmentNotes: json['assessmentNotes']?.toString(),
      decision: json['decision']?.toString(),
    );
  }
}

class AllocatedBatch {
  final String? invId;
  final String batch;
  final String pool;
  final int bottleType;
  final int bottlesAllocated;
  final int volDischarge;
  final DateTime? expiryDate;

  AllocatedBatch({
    this.invId,
    required this.batch,
    this.pool = '',
    required this.bottleType,
    required this.bottlesAllocated,
    required this.volDischarge,
    this.expiryDate,
  });

  factory AllocatedBatch.fromJson(Map<String, dynamic> json) {
    return AllocatedBatch(
      invId: json['invId']?.toString(),
      batch: json['batch']?.toString() ?? '',
      pool: json['pool']?.toString() ?? '',
      bottleType: (json['bottleType'] as num?)?.toInt() ?? 100,
      bottlesAllocated: (json['bottlesAllocated'] as num?)?.toInt() ?? 0,
      volDischarge: (json['volDischarge'] as num?)?.toInt() ?? 0,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
    );
  }
}

class RequesterAccount {
  final String id;
  final String name;
  final String? phone;
  final String? email;

  RequesterAccount({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });

  factory RequesterAccount.fromJson(Map<String, dynamic> json) {
    String n = '';
    if (json['name'] is Map) {
      n = '${json['name']['first'] ?? ''} ${json['name']['last'] ?? ''}'.trim();
    }
    if (n.isEmpty) n = json['username']?.toString() ?? 'Donor Account';

    return RequesterAccount(
      id: json['_id']?.toString() ?? '',
      name: n,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class MilkRequestModel {
  final String id;
  final String requestNumber;
  final String recipientName;
  final String relationToRecipient;
  final double volumeRequested;
  final int feedingDurationDays;
  final double? approvedVolume;
  final String reasonForRequest;
  final String hospitalOrAddress;
  final String? additionalRemarks;
  final String? doctor;
  final String status;
  final DateTime dateRequested;
  final RequesterAccount? requester;
  final ClinicalReview? clinicalReview;
  final List<AllocatedBatch> allocatedBatches;
  final List<RequestHistoryEntry> history;
  final String? rejectionReason;
  final String? cancellationReason;
  final bool isDeleted;

  MilkRequestModel({
    required this.id,
    required this.requestNumber,
    required this.recipientName,
    required this.relationToRecipient,
    required this.volumeRequested,
    this.feedingDurationDays = 7,
    this.approvedVolume,
    required this.reasonForRequest,
    required this.hospitalOrAddress,
    this.additionalRemarks,
    this.doctor,
    required this.status,
    required this.dateRequested,
    this.requester,
    this.clinicalReview,
    this.allocatedBatches = const [],
    this.history = const [],
    this.rejectionReason,
    this.cancellationReason,
    this.isDeleted = false,
  });

  String get formattedDate => DateFormat('MMM dd, yyyy').format(dateRequested);
  String get formattedVolumeRequested => '${NumberFormat('#,##0').format(volumeRequested)} mL';
  String get formattedApprovedVolume => approvedVolume != null
      ? '${NumberFormat('#,##0').format(approvedVolume)} mL'
      : formattedVolumeRequested;

  factory MilkRequestModel.fromJson(Map<String, dynamic> json) {
    String recName = json['recipientName']?.toString() ?? '';
    if (recName.isEmpty && json['patient'] is Map) {
      final p = json['patient'];
      if (p['name'] is Map) {
        recName = '${p['name']['first'] ?? ''} ${p['name']['last'] ?? ''}'.trim();
      } else {
        recName = p['name']?.toString() ?? '';
      }
    }
    if (recName.isEmpty && json['patient'] is String) {
      recName = 'Patient #${json['patient']}';
    }
    if (recName.isEmpty) recName = 'Infant Recipient';

    double vol = 0;
    int days = 7;
    if (json['volumeRequested'] is Map) {
      vol = (json['volumeRequested']['volume'] as num?)?.toDouble() ?? 0;
      days = (json['volumeRequested']['days'] as num?)?.toInt() ?? 7;
    } else if (json['volumeRequested'] is num) {
      vol = (json['volumeRequested'] as num).toDouble();
    } else if (json['volumeRequested'] != null) {
      vol = double.tryParse(json['volumeRequested'].toString()) ?? 0;
    }

    RequesterAccount? reqAcc;
    if (json['requestedBy'] is Map) {
      reqAcc = RequesterAccount.fromJson(Map<String, dynamic>.from(json['requestedBy']));
    }

    ClinicalReview? cRev;
    if (json['clinicalReview'] is Map) {
      cRev = ClinicalReview.fromJson(Map<String, dynamic>.from(json['clinicalReview']));
    }

    List<AllocatedBatch> batches = [];
    if (json['allocatedBatches'] is List) {
      for (final b in json['allocatedBatches']) {
        if (b is Map) batches.add(AllocatedBatch.fromJson(Map<String, dynamic>.from(b)));
      }
    }

    List<RequestHistoryEntry> hist = [];
    if (json['history'] is List) {
      for (final h in json['history']) {
        if (h is Map) hist.add(RequestHistoryEntry.fromJson(Map<String, dynamic>.from(h)));
      }
    }

    return MilkRequestModel(
      id: json['_id']?.toString() ?? '',
      requestNumber: json['requestNumber']?.toString() ?? 'REQ-N/A',
      recipientName: recName,
      relationToRecipient: json['relationToRecipient']?.toString() ?? 'Mother / Guardian',
      volumeRequested: vol,
      feedingDurationDays: days,
      approvedVolume: (json['approvedVolume'] as num?)?.toDouble(),
      reasonForRequest: json['reason']?.toString() ?? json['reasonForRequest']?.toString() ?? 'N/A',
      hospitalOrAddress: json['hospital']?.toString() ?? 'Pasig City General Hospital',
      additionalRemarks: json['additionalRemarks']?.toString() ?? json['notes']?.toString(),
      doctor: json['doctor']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      dateRequested: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      requester: reqAcc,
      clinicalReview: cRev,
      allocatedBatches: batches,
      history: hist,
      rejectionReason: json['rejectionReason']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }
}

