import 'dart:convert';

enum WgStatus { active, rented }

const List<String> kWgAmenities = [
  'Möbliert',
  'WLAN',
  'Waschmaschine',
  'Spülmaschine',
  'Balkon',
  'Aufzug',
  'Fahrradkeller',
  'Haustiere erlaubt',
  'Rauchfrei',
];

const List<String> kWgReportReasons = [
  'Betrug / verdächtig',
  'Unangemessener Inhalt',
  'Falsche Angaben',
  'Spam / Werbung',
];

const int kWgListingDays = 30;

String wgDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class WgListing {
  final String id;
  final String ownerId;
  final String title;
  final String city;
  final String district;
  final int sizeSqm;
  final int warmRent;
  final int? deposit;
  final DateTime availableFrom;
  final DateTime? availableUntil; // null = unbefristet
  final int flatmates;
  final String roomDescription;
  final String flatDescription;
  final List<String> amenities;
  final List<String> images;
  final WgStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const WgListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.city,
    this.district = '',
    required this.sizeSqm,
    required this.warmRent,
    this.deposit,
    required this.availableFrom,
    this.availableUntil,
    required this.flatmates,
    required this.roomDescription,
    this.flatDescription = '',
    this.amenities = const [],
    this.images = const [],
    this.status = WgStatus.active,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isTemporary => availableUntil != null;
  bool isExpired([DateTime? now]) =>
      !(now ?? DateTime.now()).isBefore(expiresAt);

  /// Erscheint in der öffentlichen Suche.
  bool isActive([DateTime? now]) =>
      status == WgStatus.active && !isExpired(now);

  int daysLeft([DateTime? now]) =>
      expiresAt.difference(now ?? DateTime.now()).inDays;

  WgListing copyWith({
    String? title,
    String? city,
    String? district,
    int? sizeSqm,
    int? warmRent,
    int? deposit,
    bool clearDeposit = false,
    DateTime? availableFrom,
    DateTime? availableUntil,
    bool clearUntil = false,
    int? flatmates,
    String? roomDescription,
    String? flatDescription,
    List<String>? amenities,
    List<String>? images,
    WgStatus? status,
    DateTime? expiresAt,
  }) =>
      WgListing(
        id: id,
        ownerId: ownerId,
        title: title ?? this.title,
        city: city ?? this.city,
        district: district ?? this.district,
        sizeSqm: sizeSqm ?? this.sizeSqm,
        warmRent: warmRent ?? this.warmRent,
        deposit: clearDeposit ? null : (deposit ?? this.deposit),
        availableFrom: availableFrom ?? this.availableFrom,
        availableUntil:
            clearUntil ? null : (availableUntil ?? this.availableUntil),
        flatmates: flatmates ?? this.flatmates,
        roomDescription: roomDescription ?? this.roomDescription,
        flatDescription: flatDescription ?? this.flatDescription,
        amenities: amenities ?? this.amenities,
        images: images ?? this.images,
        status: status ?? this.status,
        createdAt: createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'city': city,
        'district': district,
        'sizeSqm': sizeSqm,
        'warmRent': warmRent,
        'deposit': deposit,
        'availableFrom': availableFrom.toIso8601String(),
        'availableUntil': availableUntil?.toIso8601String(),
        'flatmates': flatmates,
        'roomDescription': roomDescription,
        'flatDescription': flatDescription,
        'amenities': amenities,
        'images': images,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory WgListing.fromMap(Map<String, dynamic> m) => WgListing(
        id: m['id'] as String,
        ownerId: m['ownerId'] as String,
        title: m['title'] as String,
        city: m['city'] as String,
        district: (m['district'] ?? '') as String,
        sizeSqm: m['sizeSqm'] as int,
        warmRent: m['warmRent'] as int,
        deposit: m['deposit'] as int?,
        availableFrom: DateTime.parse(m['availableFrom'] as String),
        availableUntil: m['availableUntil'] == null
            ? null
            : DateTime.parse(m['availableUntil'] as String),
        flatmates: m['flatmates'] as int,
        roomDescription: m['roomDescription'] as String,
        flatDescription: (m['flatDescription'] ?? '') as String,
        amenities: List<String>.from(m['amenities'] ?? const []),
        images: List<String>.from(m['images'] ?? const []),
        status: m['status'] == 'rented' ? WgStatus.rented : WgStatus.active,
        createdAt: DateTime.parse(m['createdAt'] as String),
        expiresAt: DateTime.parse(m['expiresAt'] as String),
      );

  static String encodeList(List<WgListing> l) =>
      json.encode(l.map((e) => e.toMap()).toList());
  static List<WgListing> decodeList(String s) => (json.decode(s) as List)
      .map((e) => WgListing.fromMap(Map<String, dynamic>.from(e)))
      .toList();
}
