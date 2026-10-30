class UserName {
  final String first;
  final String? middle;
  final String last;

  UserName({
    required this.first,
    this.middle,
    required this.last,
  });

  String get fullName {
    if (middle != null && middle!.isNotEmpty) {
      return '$first $middle $last';
    }
    return '$first $last';
  }

  factory UserName.fromJson(Map<String, dynamic> json) {
    return UserName(
      first: json['first'] ?? '',
      middle: json['middle'],
      last: json['last'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first': first,
      if (middle != null) 'middle': middle,
      'last': last,
    };
  }
}

class UserModel {
  final String id;
  final UserName name;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
  });

  bool get isDonorOrMother => role == 'User';
  bool get isStaff => role == 'Staff';
  bool get isAdmin => role == 'Admin' || role == 'SuperAdmin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] is Map<String, dynamic>
          ? UserName.fromJson(json['name'])
          : UserName(first: '', last: ''),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'User',
      avatarUrl: json['avatar'] is Map ? json['avatar']['url'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name.toJson(),
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}

