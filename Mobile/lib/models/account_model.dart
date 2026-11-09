import 'package:intl/intl.dart';

class AccountAuditEntry {
  final String action;
  final String actorName;
  final String? reason;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  AccountAuditEntry({
    required this.action,
    required this.actorName,
    this.reason,
    this.details,
    required this.timestamp,
  });

  String get formattedTimestamp => DateFormat('MMM dd, yyyy hh:mm a').format(timestamp);

  String get actionLabel {
    switch (action) {
      case 'CREATE_ACCOUNT': return 'Account Created';
      case 'DEACTIVATE_ACCOUNT': return 'Account Deactivated';
      case 'REACTIVATE_ACCOUNT': return 'Account Reactivated';
      case 'DELETE_ACCOUNT': return 'Account Deleted';
      case 'CHANGE_ROLE':
        final old = details?['oldRole'] ?? '';
        final nw = details?['newRole'] ?? '';
        return 'Role Changed: $old → $nw';
      default: return action.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
    }
  }

  factory AccountAuditEntry.fromJson(Map<String, dynamic> json) {
    return AccountAuditEntry(
      action: json['action']?.toString() ?? '',
      actorName: json['userName']?.toString() ?? 'Unknown',
      reason: json['reason']?.toString(),
      details: json['details'] is Map ? Map<String, dynamic>.from(json['details']) : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AccountModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String username;
  final String? email;
  final String phone;
  final String role;
  final String status; // 'Active' | 'Deactivated'
  final String? avatarUrl;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final bool mustChangePassword;
  final String? deactivationReason;
  final DateTime? deactivatedAt;
  final bool isDeleted;
  final List<AccountAuditEntry> auditHistory;

  AccountModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.username,
    this.email,
    required this.phone,
    required this.role,
    this.status = 'Active',
    this.avatarUrl,
    this.lastLogin,
    required this.createdAt,
    this.mustChangePassword = false,
    this.deactivationReason,
    this.deactivatedAt,
    this.isDeleted = false,
    this.auditHistory = const [],
  });

  bool get isActive => status == 'Active';
  bool get isDeactivated => status == 'Deactivated';

  String get fullName {
    final parts = [firstName, if (middleName?.isNotEmpty == true) middleName, lastName];
    return parts.join(' ');
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  String get formattedCreatedAt => DateFormat('MMM dd, yyyy').format(createdAt);

  String get formattedLastLogin {
    if (lastLogin == null) return 'Never';
    return DateFormat('MMM dd, yyyy hh:mm a').format(lastLogin!);
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] is Map ? json['name'] as Map : <String, dynamic>{};
    final avatar = json['avatar'];

    List<AccountAuditEntry> history = [];
    if (json['auditHistory'] is List) {
      for (final e in json['auditHistory']) {
        if (e is Map) {
          history.add(AccountAuditEntry.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return AccountModel(
      id: json['_id']?.toString() ?? '',
      firstName: name['first']?.toString() ?? '',
      lastName: name['last']?.toString() ?? '',
      middleName: name['middle']?.toString(),
      username: json['username']?.toString() ?? '',
      email: (json['email'] != null && json['email'].toString().isNotEmpty)
          ? json['email'].toString()
          : null,
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Staff',
      status: json['status']?.toString() ?? 'Active',
      avatarUrl: avatar is Map
          ? avatar['url']?.toString()
          : (avatar is String ? avatar : null),
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      mustChangePassword: json['mustChangePassword'] == true,
      deactivationReason: json['deactivationReason']?.toString(),
      deactivatedAt: json['deactivatedAt'] != null
          ? DateTime.tryParse(json['deactivatedAt'].toString())
          : null,
      isDeleted: json['isDeleted'] == true,
      auditHistory: history,
    );
  }
}

