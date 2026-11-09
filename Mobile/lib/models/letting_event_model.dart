class EventVenue {
  final String name;
  final String street;
  final String barangay;
  final String city;

  EventVenue({
    required this.name,
    required this.street,
    required this.barangay,
    required this.city,
  });

  String get fullAddress {
    if (street.isEmpty && barangay.isEmpty) return name;
    return '$name, $street, Brgy. $barangay, $city'.replaceAll(RegExp(r',\s*,'), ',').trim();
  }

  factory EventVenue.fromJson(dynamic json) {
    if (json is String) {
      return EventVenue(
        name: json,
        street: '',
        barangay: '',
        city: 'Pasig City',
      );
    }
    if (json is Map<String, dynamic>) {
      return EventVenue(
        name: json['name'] ?? 'Pasig City Human Milk Bank',
        street: json['street'] ?? '',
        barangay: json['barangay'] ?? '',
        city: json['city'] ?? 'Pasig City',
      );
    }
    return EventVenue(
      name: 'Pasig City Human Milk Bank',
      street: '',
      barangay: '',
      city: 'Pasig City',
    );
  }
}

class EventTime {
  final String start;
  final String end;

  EventTime({required this.start, required this.end});

  factory EventTime.fromJson(Map<String, dynamic> json) {
    return EventTime(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}

class EventDetails {
  final DateTime date;
  final EventTime time;

  EventDetails({required this.date, required this.time});

  factory EventDetails.fromJson(Map<String, dynamic> json) {
    return EventDetails(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      time: json['time'] is Map<String, dynamic>
          ? EventTime.fromJson(json['time'])
          : EventTime(start: '8:00 AM', end: '4:00 PM'),
    );
  }
}

class LettingEventModel {
  final String id;
  final String activity;
  final EventDetails details;
  final EventVenue venue;

  LettingEventModel({
    required this.id,
    required this.activity,
    required this.details,
    required this.venue,
  });

  factory LettingEventModel.fromJson(Map<String, dynamic> json) {
    return LettingEventModel(
      id: json['_id'] ?? '',
      activity: json['activity'] ?? 'Milk Letting Activity',
      details: json['actDetails'] is Map<String, dynamic>
          ? EventDetails.fromJson(json['actDetails'])
          : EventDetails(date: DateTime.now(), time: EventTime(start: '', end: '')),
      venue: EventVenue.fromJson(json['venue']),
    );
  }
}

