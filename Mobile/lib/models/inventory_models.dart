import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CollectionModel {
  final String id;
  final String collectionType;
  final DateTime collectionDate;
  final String status;
  final double volume;
  final String reasonForCorrection;
  final bool isDeleted;
  final DateTime? deletedAt;

  // Linked pickup schedule fields (read from privDetails, not duplicated)
  final String pickupScheduleId;
  final String donorName;
  final String dateRange;
  final String pickupAddress;
  final String contactNumber;
  final String pickupStatus;
  final double totalVolume;
  final String timeWindow;

  CollectionModel({
    required this.id,
    this.collectionType = 'Private',
    required this.collectionDate,
    this.status = 'Pending',
    this.volume = 0.0,
    this.reasonForCorrection = '',
    this.isDeleted = false,
    this.deletedAt,
    this.pickupScheduleId = '',
    this.donorName = '',
    this.dateRange = '',
    this.pickupAddress = '',
    this.contactNumber = '',
    this.pickupStatus = 'Pending',
    this.totalVolume = 0.0,
    this.timeWindow = '',
  });

  String get displayName => donorName.isNotEmpty ? donorName : 'Private Donor';
  double get effectiveVolume => volume > 0 ? volume : totalVolume;

  String get formattedCollectionDate => DateFormat('MMM dd, yyyy').format(collectionDate);

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final priv = json['privDetails'] is Map ? Map<String, dynamic>.from(json['privDetails']) : null;
    final donorIdObj = priv?['donorDetails'] is Map ? priv!['donorDetails']['donorId'] : null;
    final userObj = donorIdObj is Map ? donorIdObj['user'] : null;

    String dName = priv?['donorName']?.toString() ?? '';
    if (dName.isEmpty && userObj is Map) {
      dName = userObj['name']?.toString() ?? '';
    }

    String dRange = priv?['dateRange']?.toString() ?? '';
    if (dRange.isEmpty && priv != null) {
      final s = priv['startDate'] ?? priv['dates'];
      final e = priv['endDate'] ?? priv['dates'];
      if (s != null && e != null) {
        final sFmt = DateFormat('MMM dd, yyyy').format(DateTime.tryParse(s.toString()) ?? DateTime.now());
        final eFmt = DateFormat('MMM dd, yyyy').format(DateTime.tryParse(e.toString()) ?? DateTime.now());
        dRange = sFmt == eFmt ? sFmt : '$sFmt - $eFmt';
      }
    }

    return CollectionModel(
      id: json['_id']?.toString() ?? '',
      collectionType: json['collectionType']?.toString() ?? 'Private',
      collectionDate: parseDate(json['collectionDate']),
      status: json['status']?.toString() ?? 'Pending',
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      reasonForCorrection: json['reasonForCorrection']?.toString() ?? '',
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt'] != null ? parseDate(json['deletedAt']) : null,
      pickupScheduleId: priv?['_id']?.toString() ?? '',
      donorName: dName,
      dateRange: dRange,
      pickupAddress: priv?['pickupAddress']?.toString() ?? priv?['address']?.toString() ?? '',
      contactNumber: priv?['contactNumber']?.toString() ?? '',
      pickupStatus: priv?['pickupStatus']?.toString() ?? 'Pending',
      totalVolume: (priv?['totalVolume'] as num?)?.toDouble() ?? 0.0,
      timeWindow: priv?['time']?.toString() ?? '',
    );
  }
}

class FridgeModel {
  final String id;
  final String name;
  final String fridgeType; // 'Unpasteurized' or 'Pasteurized'
  final int totalVolume;   // ml, computed
  final int entryCount;
  final int nearExpiryCount;
  final int expiredCount;
  final bool isDeleted;
  final DateTime createdAt;

  FridgeModel({
    required this.id,
    required this.name,
    required this.fridgeType,
    this.totalVolume = 0,
    this.entryCount = 0,
    this.nearExpiryCount = 0,
    this.expiredCount = 0,
    this.isDeleted = false,
    required this.createdAt,
  });

  bool get isUnpasteurized => fridgeType == 'Unpasteurized';
  bool get isPasteurized => fridgeType == 'Pasteurized';

  factory FridgeModel.fromJson(Map<String, dynamic> json) {
    return FridgeModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Refrigerator',
      fridgeType: json['fridgeType']?.toString() ?? 'Unpasteurized',
      totalVolume: (json['totalVolume'] as num?)?.toInt() ?? 0,
      entryCount: (json['entryCount'] as num?)?.toInt() ?? 0,
      nearExpiryCount: (json['nearExpiryCount'] as num?)?.toInt() ?? 0,
      expiredCount: (json['expiredCount'] as num?)?.toInt() ?? 0,
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FridgeEntryModel {
  final String id;
  final String fridgeId;
  final String donorName;
  final List<String> donorNames;
  final int volume;
  final DateTime? expiration;
  final bool isExpired;
  final bool isNearExpiry;
  final bool isPasteurizable;
  final int? batchNumber;
  final int? poolNumber;
  final int? bottleType;
  final int availableBottles;
  final String status;
  final bool isDeleted;
  final bool isPasteurized;
  final bool isRequested;
  final String reasonForChange;

  FridgeEntryModel({
    required this.id,
    required this.fridgeId,
    required this.donorName,
    this.donorNames = const [],
    this.volume = 0,
    this.expiration,
    this.isExpired = false,
    this.isNearExpiry = false,
    this.isPasteurizable = true,
    this.batchNumber,
    this.poolNumber,
    this.bottleType,
    this.availableBottles = 0,
    this.status = 'Available',
    this.isDeleted = false,
    this.isPasteurized = false,
    this.isRequested = false,
    this.reasonForChange = '',
  });

  String get displayDonorName {
    if (donorNames.isNotEmpty) return donorNames.join(', ');
    return donorName.isNotEmpty ? donorName : 'Unknown Donor';
  }

  String get formattedExpiration {
    if (expiration == null) return 'No expiry date';
    return DateFormat('MMM dd, yyyy').format(expiration!);
  }

  int get daysUntilExpiration {
    if (expiration == null) return 999;
    final now = DateTime.now();
    return expiration!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  factory FridgeEntryModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final dNames = (json['donorNames'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return FridgeEntryModel(
      id: json['_id']?.toString() ?? '',
      fridgeId: json['fridge']?.toString() ?? '',
      donorName: json['donorName']?.toString() ?? '',
      donorNames: dNames,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      expiration: parseDate(json['expiration']),
      isExpired: json['isExpired'] == true,
      isNearExpiry: json['isNearExpiry'] == true,
      isPasteurizable: json['isPasteurizable'] == true,
      batchNumber: (json['batchNumber'] as num?)?.toInt(),
      poolNumber: (json['poolNumber'] as num?)?.toInt(),
      bottleType: (json['bottleType'] as num?)?.toInt(),
      availableBottles: (json['availableBottles'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'Available',
      isDeleted: json['isDeleted'] == true,
      isPasteurized: json['isPasteurized'] == true,
      isRequested: json['isRequested'] == true,
      reasonForChange: json['reasonForChange']?.toString() ?? '',
    );
  }
}

