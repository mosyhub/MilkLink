import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleModel {
  final String id;
  final String kind; // 'Event' or 'Pickup'
  final String title;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? dateRange;
  final String startTime; // 24h format "HH:mm"
  final String endTime;   // 24h format "HH:mm"
  final String? time;
  final String location;
  final String description;
  final String donorName;
  final String pickupAddress;
  final String contactNumber;
  final String pickupStatus; // 'Pending', 'Scheduled', 'Picked Up', 'Cancelled'
  final String status;       // 'Pending', 'Scheduled', 'Approved', 'Completed', 'Cancelled'
  final double totalVolume;
  final bool isDeleted;
  final DateTime? createdAt;

  ScheduleModel({
    required this.id,
    required this.kind,
    this.title = '',
    this.date,
    this.startDate,
    this.endDate,
    this.dateRange,
    this.startTime = '',
    this.endTime = '',
    this.time,
    this.location = '',
    this.description = '',
    this.donorName = '',
    this.pickupAddress = '',
    this.contactNumber = '',
    this.pickupStatus = 'Pending',
    this.status = 'Pending',
    this.totalVolume = 0.0,
    this.isDeleted = false,
    this.createdAt,
  });

  bool get isPickup => kind == 'Pickup';
  bool get isEvent => kind == 'Event';

  bool get isCancelled => isPickup ? pickupStatus == 'Cancelled' : status == 'Cancelled';
  bool get isActive => !isDeleted && !isCancelled;

  String get displayName => isPickup ? (donorName.isNotEmpty ? donorName : 'Unnamed Donor') : (title.isNotEmpty ? title : 'Untitled Event');
  String get displayAddress => isPickup ? pickupAddress : location;
  String get effectiveStatus => isPickup ? pickupStatus : status;

  // Time in minutes
  int? get startMinutes => parseTimeToMinutes(startTime);
  int? get endMinutes => parseTimeToMinutes(endTime);

  String get displayTimeRange {
    final s12 = formatTime12(startTime);
    final e12 = formatTime12(endTime);
    if (s12.isNotEmpty && e12.isNotEmpty) {
      return '$s12 - $e12';
    }
    if (time != null && time!.isNotEmpty) return time!;
    return 'Time not set';
  }

  String get displayDate {
    final df = DateFormat('MMM dd, yyyy');
    if (isPickup) {
      final s = startDate ?? date;
      final e = endDate ?? startDate ?? date;
      if (s != null && e != null) {
        if (s.year == e.year && s.month == e.month && s.day == e.day) {
          return df.format(s);
        }
        return '${df.format(s)} - ${df.format(e)}';
      }
      if (dateRange != null && dateRange!.isNotEmpty) return dateRange!;
    }
    if (date != null) return df.format(date!);
    if (startDate != null) return df.format(startDate!);
    return 'Date not set';
  }

  List<String> get datesCovered {
    final list = <String>[];
    final s = startDate ?? date;
    final e = endDate ?? startDate ?? date;
    if (s == null) return list;
    final end = e ?? s;

    DateTime cur = DateTime(s.year, s.month, s.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cur.isAfter(last)) {
      list.add(DateFormat('yyyy-MM-dd').format(cur));
      cur = cur.add(const Duration(days: 1));
    }
    return list;
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    String parseTimePart(String? t, int index) {
      if (t == null || !t.contains('-')) return '';
      final parts = t.split('-');
      if (index < parts.length) return parts[index].trim();
      return '';
    }

    String sTime = json['startTime']?.toString() ?? '';
    String eTime = json['endTime']?.toString() ?? '';
    final legacyTime = json['time']?.toString() ?? '';

    if (sTime.isEmpty && legacyTime.isNotEmpty) {
      sTime = parseTimePart(legacyTime, 0);
      eTime = parseTimePart(legacyTime, 1);
    }

    final d = parseDate(json['date'] ?? json['dates']);
    final sd = parseDate(json['startDate']) ?? d;
    final ed = parseDate(json['endDate']) ?? sd;

    return ScheduleModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'Event',
      title: json['title']?.toString() ?? '',
      date: d,
      startDate: sd,
      endDate: ed,
      dateRange: json['dateRange']?.toString(),
      startTime: normalizeTimeTo24(sTime),
      endTime: normalizeTimeTo24(eTime),
      time: legacyTime.isNotEmpty ? legacyTime : null,
      location: json['location']?.toString() ?? json['address']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      donorName: json['donorName']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString() ?? json['address']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      pickupStatus: json['pickupStatus']?.toString() ?? 'Pending',
      status: json['status']?.toString() ?? 'Pending',
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      isDeleted: json['isDeleted'] == true,
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'kind': kind,
      'title': title,
      if (date != null) 'date': DateFormat('yyyy-MM-dd').format(date!),
      if (date != null) 'dates': DateFormat('yyyy-MM-dd').format(date!),
      if (startDate != null) 'startDate': DateFormat('yyyy-MM-dd').format(startDate!),
      if (endDate != null) 'endDate': DateFormat('yyyy-MM-dd').format(endDate!),
      if (dateRange != null) 'dateRange': dateRange,
      'startTime': startTime,
      'endTime': endTime,
      'time': '$startTime - $endTime',
      'location': location,
      'address': isPickup ? pickupAddress : location,
      'description': description,
      'donorName': donorName,
      'pickupAddress': pickupAddress,
      'contactNumber': contactNumber,
      'pickupStatus': pickupStatus,
      'status': status,
      'totalVolume': totalVolume,
    };
  }

  // --- Helper utility methods ---

  static int? parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final s = timeStr.trim();
    // 12-hour: 9:00 AM, 09:30 PM
    final reg12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
    final m12 = reg12.firstMatch(s);
    if (m12 != null) {
      int h = int.parse(m12.group(1)!);
      final int m = int.parse(m12.group(2)!);
      final String mod = m12.group(3)!.toUpperCase();
      if (mod == 'PM' && h < 12) h += 12;
      if (mod == 'AM' && h == 12) h = 0;
      return h * 60 + m;
    }
    // 24-hour: 09:00, 14:30
    final reg24 = RegExp(r'^(\d{1,2}):(\d{2})$');
    final m24 = reg24.firstMatch(s);
    if (m24 != null) {
      final int h = int.parse(m24.group(1)!);
      final int m = int.parse(m24.group(2)!);
      return h * 60 + m;
    }
    return null;
  }

  static String normalizeTimeTo24(String? timeStr) {
    final mins = parseTimeToMinutes(timeStr);
    if (mins == null) return timeStr ?? '';
    final h = (mins ~/ 60).toString().padLeft(2, '0');
    final m = (mins % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatTime12(String? timeStr) {
    final mins = parseTimeToMinutes(timeStr);
    if (mins == null) return timeStr ?? '';
    int h = mins ~/ 60;
    final int m = mins % 60;
    final String ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    final mStr = m.toString().padLeft(2, '0');
    return '$h:$mStr $ampm';
  }

  static String minutesToTime24(int totalMinutes) {
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String minutesToTime12(int totalMinutes) {
    int h = totalMinutes ~/ 60;
    final int m = totalMinutes % 60;
    final String ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    final mStr = m.toString().padLeft(2, '0');
    return '$h:$mStr $ampm';
  }
}

class ConflictResult {
  final bool hasConflict;
  final String message;
  final String type;
  final String name;
  final String date;
  final String timeRange;
  final String suggestedSlot;
  final String suggestedStart24;
  final String suggestedEnd24;

  ConflictResult({
    required this.hasConflict,
    this.message = '',
    this.type = '',
    this.name = '',
    this.date = '',
    this.timeRange = '',
    this.suggestedSlot = '',
    this.suggestedStart24 = '',
    this.suggestedEnd24 = '',
  });

  factory ConflictResult.noConflict() => ConflictResult(hasConflict: false);
}

class OverlapChecker {
  static ConflictResult check({
    required List<ScheduleModel> activeSchedules,
    required String kind,
    required String titleOrDonor,
    required List<String> targetDates,
    required String startTime24,
    required String endTime24,
    String? excludeId,
  }) {
    final newStart = ScheduleModel.parseTimeToMinutes(startTime24);
    final newEnd = ScheduleModel.parseTimeToMinutes(endTime24);
    if (newStart == null || newEnd == null || targetDates.isEmpty) {
      return ConflictResult.noConflict();
    }
    if (newEnd <= newStart) {
      return ConflictResult(
        hasConflict: true,
        message: 'End Time must be later than Start Time.',
      );
    }

    final duration = newEnd - newStart;

    final candidates = activeSchedules.where((s) {
      if (excludeId != null && s.id == excludeId) return false;
      return s.isActive;
    }).toList();

    for (final dateStr in targetDates) {
      final dateSchedules = candidates.where((s) => s.datesCovered.contains(dateStr)).toList();

      for (final existing in dateSchedules) {
        final exStart = existing.startMinutes;
        final exEnd = existing.endMinutes;
        if (exStart == null || exEnd == null) continue;

        // Overlap condition: new.start < existing.end AND new.end > existing.start
        if (newStart < exEnd && newEnd > exStart) {
          final type = existing.isEvent ? 'Event' : 'Pickup';
          final name = existing.displayName;
          final timeRange = existing.displayTimeRange;

          // Find booked intervals on this date
          final intervals = dateSchedules
              .map((s) => [s.startMinutes!, s.endMinutes!])
              .toList()
            ..sort((a, b) => a[0].compareTo(b[0]));

          // Suggest next free slot starting after existing end
          int candidateStart = exEnd;
          String suggestedSlot = '';
          String sugStart24 = '';
          String sugEnd24 = '';

          while (candidateStart + duration <= 1440) {
            final candidateEnd = candidateStart + duration;
            final overlaps = intervals.any((i) => candidateStart < i[1] && candidateEnd > i[0]);
            if (!overlaps) {
              sugStart24 = ScheduleModel.minutesToTime24(candidateStart);
              sugEnd24 = ScheduleModel.minutesToTime24(candidateEnd);
              suggestedSlot = '${ScheduleModel.minutesToTime12(candidateStart)} - ${ScheduleModel.minutesToTime12(candidateEnd)}';
              break;
            } else {
              final hit = intervals.firstWhere((i) => candidateStart < i[1] && candidateEnd > i[0]);
              candidateStart = hit[1];
            }
          }

          if (suggestedSlot.isEmpty) {
            candidateStart = 480; // 8:00 AM
            while (candidateStart + duration <= exStart) {
              final candidateEnd = candidateStart + duration;
              final overlaps = intervals.any((i) => candidateStart < i[1] && candidateEnd > i[0]);
              if (!overlaps) {
                sugStart24 = ScheduleModel.minutesToTime24(candidateStart);
                sugEnd24 = ScheduleModel.minutesToTime24(candidateEnd);
                suggestedSlot = '${ScheduleModel.minutesToTime12(candidateStart)} - ${ScheduleModel.minutesToTime12(candidateEnd)}';
                break;
              } else {
                final hit = intervals.firstWhere((i) => candidateStart < i[1] && candidateEnd > i[0]);
                candidateStart = hit[1];
              }
            }
          }

          final msg = 'Conflict with $type \'$name\' on $dateStr ($timeRange).' +
              (suggestedSlot.isNotEmpty ? ' Next free slot: $suggestedSlot' : '');

          return ConflictResult(
            hasConflict: true,
            message: msg,
            type: type,
            name: name,
            date: dateStr,
            timeRange: timeRange,
            suggestedSlot: suggestedSlot,
            suggestedStart24: sugStart24,
            suggestedEnd24: sugEnd24,
          );
        }
      }
    }

    return ConflictResult.noConflict();
  }
}

