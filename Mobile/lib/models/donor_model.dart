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
  final List<ChildInfo> children;
  final List<DonationRecord> donations;

  DonorModel({
    required this.id,
    required this.homeAddress,
    this.birthday,
    this.contactNumber,
    this.occupation,
    required this.donorType,
    required this.eligibility,
    required this.verified,
    required this.children,
    required this.donations,
  });

  bool get isEligible =>
      eligibility.toLowerCase() == 'eligible' || eligibility.toLowerCase() == 'accepted';

  double get totalDonatedVolume =>
      donations.fold(0.0, (acc, item) => acc + item.totalVolume);

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List? ?? [];
    final rawDonations = json['donations'] as List? ?? [];

    return DonorModel(
      id: json['_id'] ?? '',
      homeAddress: json['home_address'] is Map<String, dynamic>
          ? HomeAddress.fromJson(json['home_address'])
          : HomeAddress(street: '', brgy: '', city: ''),
      birthday: json['birthday'] != null ? DateTime.tryParse(json['birthday']) : null,
      contactNumber: json['contact_number'],
      occupation: json['occupation'],
      donorType: json['donorType'] ?? 'Community',
      eligibility: json['eligibility'] ?? 'Pending',
      verified: json['verified'] ?? false,
      children: rawChildren.map((c) => ChildInfo.fromJson(c)).toList(),
      donations: rawDonations.map((d) => DonationRecord.fromJson(d)).toList(),
    );
  }
}

