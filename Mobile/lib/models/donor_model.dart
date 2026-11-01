class HomeAddress {
  final String street;
  final String brgy;
  final String city;

  HomeAddress({
    required this.street,
    required this.brgy,
    required this.city,
  });

  String get fullAddress => '$street, Brgy. $brgy, $city';

  factory HomeAddress.fromJson(Map<String, dynamic> json) {
    return HomeAddress(
      street: json['street'] ?? '',
      brgy: json['brgy'] ?? '',
      city: json['city'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'brgy': brgy,
      'city': city,
    };
  }
}

class ChildInfo {
  final String name;
  final DateTime? dateOfBirth;
  final String? birthWeight;
  final int? ageValue;
  final String? ageUnit;

  ChildInfo({
    required this.name,
    this.dateOfBirth,
    this.birthWeight,
    this.ageValue,
    this.ageUnit,
  });

  factory ChildInfo.fromJson(Map<String, dynamic> json) {
    int? val;
    String? unit;
    if (json['age'] is Map) {
      val = json['age']['value'] is num ? (json['age']['value'] as num).toInt() : null;
      unit = json['age']['unit'];
    }
    return ChildInfo(
      name: json['name'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
      birthWeight: json['birth_weight']?.toString(),
      ageValue: val,
      ageUnit: unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (birthWeight != null) 'birth_weight': birthWeight,
      if (ageValue != null)
        'age': {
          'value': ageValue,
          'unit': ageUnit ?? 'months',
        },
    };
  }
}

class DonationRecord {
  final String id;
  final String donationType;
  final String? eventTitle;
  final DateTime? eventDate;
  final double totalVolume;

  DonationRecord({
    required this.id,
    required this.donationType,
    this.eventTitle,
    this.eventDate,
    required this.totalVolume,
  });

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    String? title;
    DateTime? date;

    if (json['milkLettingEvent'] is Map) {
      final mle = json['milkLettingEvent'];
      title = mle['activity'];
      if (mle['actDetails'] is Map && mle['actDetails']['date'] != null) {
        date = DateTime.tryParse(mle['actDetails']['date']);
      }
    }

    final vol = json['totalVolume'] != null
        ? (json['totalVolume'] as num).toDouble()
        : 0.0;

    return DonationRecord(
      id: json['_id'] ?? '',
      donationType: json['donationType'] ?? 'Public',
      eventTitle: title,
      eventDate: date,
      totalVolume: vol,
    );
  }
}

class DonorModel {
  final String id;
  final HomeAddress homeAddress;
  final DateTime? birthday;
  final String? contactNumber;
  final String? occupation;
  final String donorType;
  final String eligibility;
  final bool verified;
  // Populated when user account is linked
  final String? userName;
  final String? userId;
  final String? staffId;
  final String? staffName;
  final Map<String, dynamic>? screening;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final List<ChildInfo> children;
  final List<DonationRecord> donations;
  // The actual name fields from the Donor schema (name.first / name.middle / name.last)
  final String? nameFirst;
  final String? nameMiddle;
  final String? nameLast;

  DonorModel({
    required this.id,
    required this.homeAddress,
    this.birthday,
    this.contactNumber,
    this.occupation,
    required this.donorType,
    required this.eligibility,
    required this.verified,
    this.userName,
    this.userId,
    this.staffId,
    this.staffName,
    this.screening,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
    required this.children,
    required this.donations,
    this.nameFirst,
    this.nameMiddle,
    this.nameLast,
  });

  bool get isClaimed => userId != null && userId!.isNotEmpty;
  String get claimStatus => isClaimed ? 'Claimed / Linked' : 'Unclaimed';

  bool get isEligible =>
      eligibility.toLowerCase() == 'eligible' || eligibility.toLowerCase() == 'accepted';

  double get totalDonatedVolume =>
      donations.fold(0.0, (acc, item) => acc + item.totalVolume);

  /// Priority: linked user name > donor's own name > child reference > ID fallback
  String get displayName {
    if (userName?.isNotEmpty == true) return userName!;
    final first = nameFirst?.trim() ?? '';
    final last = nameLast?.trim() ?? '';
    if (first.isNotEmpty || last.isNotEmpty) {
      return '$first $last'.trim();
    }
    if (children.isNotEmpty && children.first.name.isNotEmpty) {
      return 'Mother of ${children.first.name}';
    }
    return 'Donor #$id';
  }

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List? ?? [];
    final rawDonations = json['donations'] as List? ?? [];

    // Parse linked User account
    String? uName;
    String? uId;
    if (json['user'] is Map) {
      final u = json['user'] as Map<String, dynamic>;
      uId = u['_id']?.toString();
      if (u['name'] is Map) {
        uName = '${u['name']['first'] ?? ''} ${u['name']['last'] ?? ''}'.trim();
      } else if (u['username'] != null) {
        uName = u['username']?.toString();
      }
    } else if (json['user'] is String) {
      uId = json['user'] as String;
    }

    // Parse responsible staff
    String? sName;
    String? sId;
    if (json['staff'] is Map) {
      final s = json['staff'] as Map<String, dynamic>;
      sId = s['_id']?.toString();
      if (s['name'] is Map) {
        sName = '${s['name']['first'] ?? ''} ${s['name']['last'] ?? ''}'.trim();
      } else if (s['username'] != null) {
        sName = s['username']?.toString();
      }
    } else if (json['staff'] is String) {
      sId = json['staff'] as String;
    }

    // Parse the donor's real name (name.first / name.middle / name.last from schema)
    String? nFirst;
    String? nMiddle;
    String? nLast;
    if (json['name'] is Map) {
      final nm = json['name'] as Map<String, dynamic>;
      nFirst = nm['first']?.toString();
      nMiddle = nm['middle']?.toString();
      nLast = nm['last']?.toString();
    }

    return DonorModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      homeAddress: json['home_address'] is Map<String, dynamic>
          ? HomeAddress.fromJson(json['home_address'])
          : HomeAddress(street: '', brgy: '', city: ''),
      birthday: json['birthday'] != null ? DateTime.tryParse(json['birthday'].toString()) : null,
      contactNumber: (json['contact_number'] ?? json['contactNumber'] ?? json['phone'])?.toString(),
      occupation: json['occupation']?.toString(),
      donorType: json['donorType']?.toString() ?? 'Community',
      eligibility: json['eligibility']?.toString() ?? 'Pending Review',
      verified: json['verified'] == true,
      userName: uName,
      userId: uId,
      staffId: sId,
      staffName: sName,
      screening: json['screening'] is Map<String, dynamic>
          ? json['screening'] as Map<String, dynamic>
          : null,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      children: rawChildren.map((c) => ChildInfo.fromJson(c as Map<String, dynamic>)).toList(),
      donations: rawDonations.map((d) => DonationRecord.fromJson(d as Map<String, dynamic>)).toList(),
      nameFirst: nFirst,
      nameMiddle: nMiddle,
      nameLast: nLast,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': {
        'first': nameFirst ?? '',
        'middle': nameMiddle ?? '',
        'last': nameLast ?? '',
      },
      'home_address': homeAddress.toJson(),
      'donorType': donorType,
      'eligibility': eligibility,
      'verified': verified,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (occupation != null) 'occupation': occupation,
      if (birthday != null) 'birthday': birthday!.toIso8601String(),
      if (userId != null) 'user': userId,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}
