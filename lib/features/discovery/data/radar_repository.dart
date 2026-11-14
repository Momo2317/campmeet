import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kRadarPinsKey = 'campmeet_radar_pins';

class RadarPin {
  final String id;
  final String title;
  final String description;
  final String category; // 'events', 'study', 'anschluss'
  final double latitude;
  final double longitude;
  final String creatorName;
  final DateTime createdAt;
  final int participantCount;
  final List<String> joinedUserIds;
  final String? timeString;

  RadarPin({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.creatorName,
    DateTime? createdAt,
    this.participantCount = 1,
    this.joinedUserIds = const [],
    this.timeString,
  }) : createdAt = createdAt ?? DateTime.now();

  RadarPin copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? latitude,
    double? longitude,
    String? creatorName,
    DateTime? createdAt,
    int? participantCount,
    List<String>? joinedUserIds,
    String? timeString,
  }) {
    return RadarPin(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      participantCount: participantCount ?? this.participantCount,
      joinedUserIds: joinedUserIds ?? this.joinedUserIds,
      timeString: timeString ?? this.timeString,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'creatorName': creatorName,
      'createdAt': createdAt.toIso8601String(),
      'participantCount': participantCount,
      'joinedUserIds': joinedUserIds,
      'timeString': timeString,
    };
  }

  factory RadarPin.fromMap(Map<String, dynamic> map) {
    return RadarPin(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'events',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      creatorName: map['creatorName'] ?? 'Student',
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      participantCount: map['participantCount']?.toInt() ?? 1,
      joinedUserIds: List<String>.from(map['joinedUserIds'] ?? []),
      timeString: map['timeString'],
    );
  }
}

final radarPinsProvider =
    NotifierProvider<RadarPinsNotifier, List<RadarPin>>(() {
  return RadarPinsNotifier();
});

class RadarPinsNotifier extends Notifier<List<RadarPin>> {
  SharedPreferences? _prefs;

  @override
  List<RadarPin> build() {
    _loadPins();
    return _initialDefaultPins();
  }

  List<RadarPin> _initialDefaultPins() {
    return [
      RadarPin(
        id: 'pin_1',
        title: 'Mensa-Party & After-Hour',
        description:
            'Große Semester-Auftakt-Party der Fachschaft. Musik, Drinks & lockere Leute!',
        category: 'events',
        latitude: 52.5115,
        longitude: 13.3255,
        creatorName: 'Fachschaft IT',
        participantCount: 42,
        timeString: 'Heute ab 21:30 Uhr',
      ),
      RadarPin(
        id: 'pin_2',
        title: 'Mathe 1 & Algorithmen Lerngruppe',
        description:
            'Suchen noch 2 Leute zur Klausurvorbereitung. Sitzen im 2. Stock der Hauptbibliothek.',
        category: 'study',
        latitude: 52.5132,
        longitude: 13.3280,
        creatorName: 'Leon (4. Sem)',
        participantCount: 3,
        timeString: 'Jetzt bis 18:00 Uhr',
      ),
      RadarPin(
        id: 'pin_3',
        title: 'Campus-Kino Open Air',
        description: 'Popcorn und ein Klassiker auf der Wiese vor Hörsaal 1.',
        category: 'events',
        latitude: 52.5122,
        longitude: 13.3268,
        creatorName: 'Kino-Initiative',
        participantCount: 28,
        timeString: 'Heute 19:30 Uhr',
      ),
      RadarPin(
        id: 'pin_4',
        title: 'Spontaner Kaffee am Campus-Garten',
        description:
            'Pause zwischen den Vorlesungen. Wer Lust hat auf einen Plausch in der Sonne, kommt vorbei!',
        category: 'anschluss',
        latitude: 52.5105,
        longitude: 13.3295,
        creatorName: 'Mia',
        participantCount: 4,
        timeString: 'Vor 15 Minuten',
      ),
    ];
  }

  Future<void> _loadPins() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = _prefs?.getString(_kRadarPinsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List list = json.decode(jsonStr);
        final loaded = list.map((m) => RadarPin.fromMap(m)).toList();
        if (loaded.isNotEmpty) {
          state = loaded;
        }
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = json.encode(state.map((p) => p.toMap()).toList());
    await _prefs?.setString(_kRadarPinsKey, jsonStr);
  }

  Future<void> addPin(RadarPin pin) async {
    state = [pin, ...state];
    await _persist();
  }

  Future<void> toggleJoinPin(String pinId, String userId) async {
    state = state.map((p) {
      if (p.id == pinId) {
        final alreadyJoined = p.joinedUserIds.contains(userId);
        final updatedJoined = alreadyJoined
            ? p.joinedUserIds.where((id) => id != userId).toList()
            : [...p.joinedUserIds, userId];
        final newCount =
            alreadyJoined ? p.participantCount - 1 : p.participantCount + 1;
        return p.copyWith(
          participantCount: newCount < 1 ? 1 : newCount,
          joinedUserIds: updatedJoined,
        );
      }
      return p;
    }).toList();
    await _persist();
  }

  Future<void> deletePin(String pinId) async {
    state = state.where((p) => p.id != pinId).toList();
    await _persist();
  }
}
