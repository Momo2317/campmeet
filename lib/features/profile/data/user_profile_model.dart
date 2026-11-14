import 'dart:convert';
import 'package:camp_meet/features/discovery/data/student_model.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final int age;
  final String university;
  final String major;
  final int semester;
  final String gender;
  final List<String> languages;
  final Map<String, String> lifestyle;
  final String orientation;
  final String mode; // 'Dating' or 'Study Buddy'
  final String relationshipIntent;
  final String bio;
  final String avatarUrl;
  final List<String> images;
  final List<String> interests;
  final Map<String, String> prompts;
  final int? height;
  final String? relationshipType;
  final String? zodiac;
  final String city;
  final bool isVerified;
  final bool isPlatinum;
  final int superLikes;
  final int boosts;
  final DateTime createdAt;
  final String? verificationMethod; // 'email', 'student_id', or null
  final DateTime? verificationDate; // When was the user verified
  final String?
      verificationRequestId; // Reference to verification request (for student_id)

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.university,
    required this.major,
    this.semester = 1,
    this.gender = 'Frau',
    this.languages = const [],
    this.lifestyle = const {},
    this.orientation = 'Heterosexuell',
    this.mode = 'Dating',
    this.relationshipIntent = 'Feste Beziehung',
    this.bio = '',
    required this.avatarUrl,
    required this.images,
    required this.interests,
    this.prompts = const {},
    this.height = 175,
    this.relationshipType = 'Monogam',
    this.zodiac = 'Wassermann',
    this.city = 'Berlin',
    this.isVerified = false,
    this.isPlatinum = false,
    this.superLikes = 0,
    this.boosts = 0,
    this.verificationMethod,
    this.verificationDate,
    this.verificationRequestId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? university,
    String? major,
    int? semester,
    String? gender,
    List<String>? languages,
    Map<String, String>? lifestyle,
    String? orientation,
    String? mode,
    String? relationshipIntent,
    String? bio,
    String? avatarUrl,
    List<String>? images,
    List<String>? interests,
    Map<String, String>? prompts,
    int? height,
    String? relationshipType,
    String? zodiac,
    String? city,
    bool? isVerified,
    bool? isPlatinum,
    int? superLikes,
    int? boosts,
    String? verificationMethod,
    DateTime? verificationDate,
    String? verificationRequestId,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      university: university ?? this.university,
      major: major ?? this.major,
      semester: semester ?? this.semester,
      gender: gender ?? this.gender,
      languages: languages ?? this.languages,
      lifestyle: lifestyle ?? this.lifestyle,
      orientation: orientation ?? this.orientation,
      mode: mode ?? this.mode,
      relationshipIntent: relationshipIntent ?? this.relationshipIntent,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      images: images ?? this.images,
      interests: interests ?? this.interests,
      prompts: prompts ?? this.prompts,
      height: height ?? this.height,
      relationshipType: relationshipType ?? this.relationshipType,
      zodiac: zodiac ?? this.zodiac,
      city: city ?? this.city,
      isVerified: isVerified ?? this.isVerified,
      isPlatinum: isPlatinum ?? this.isPlatinum,
      superLikes: superLikes ?? this.superLikes,
      boosts: boosts ?? this.boosts,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationDate: verificationDate ?? this.verificationDate,
      verificationRequestId:
          verificationRequestId ?? this.verificationRequestId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'university': university,
      'major': major,
      'semester': semester,
      'gender': gender,
      'languages': languages,
      'lifestyle': lifestyle,
      'orientation': orientation,
      'mode': mode,
      'relationshipIntent': relationshipIntent,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'images': images,
      'interests': interests,
      'prompts': prompts,
      'height': height,
      'relationshipType': relationshipType,
      'zodiac': zodiac,
      'city': city,
      'isVerified': isVerified,
      'isPlatinum': isPlatinum,
      'superLikes': superLikes,
      'boosts': boosts,
      'verificationMethod': verificationMethod,
      'verificationDate': verificationDate?.toIso8601String(),
      'verificationRequestId': verificationRequestId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? 'user_default',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age']?.toInt() ?? 20,
      university: map['university'] ?? '',
      major: map['major'] ?? '',
      semester: map['semester']?.toInt() ?? 1,
      gender: map['gender'] ?? 'Frau',
      languages: List<String>.from(map['languages'] ?? []),
      lifestyle: Map<String, String>.from(map['lifestyle'] ?? {}),
      orientation: map['orientation'] ?? 'Heterosexuell',
      mode: map['mode'] ?? 'Dating',
      relationshipIntent: map['relationshipIntent'] ?? 'Feste Beziehung',
      bio: map['bio'] ?? '',
      avatarUrl: map['avatarUrl'] ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      images: List<String>.from(map['images'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      prompts: Map<String, String>.from(map['prompts'] ?? {}),
      height: map['height']?.toInt(),
      relationshipType: map['relationshipType'],
      zodiac: map['zodiac'],
      city: map['city'] ?? 'Berlin',
      isVerified: map['isVerified'] ?? false,
      isPlatinum: map['isPlatinum'] ?? false,
      superLikes: map['superLikes']?.toInt() ?? 0,
      boosts: map['boosts']?.toInt() ?? 0,
      verificationMethod: map['verificationMethod'],
      verificationDate: map['verificationDate'] != null
          ? DateTime.tryParse(map['verificationDate'])
          : null,
      verificationRequestId: map['verificationRequestId'],
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));

  Student toStudent() {
    return Student(
      id: id,
      name: name,
      age: age,
      university: university,
      major: major,
      bio: bio.isNotEmpty ? bio : 'Student an der $university.',
      imageUrl: avatarUrl,
      images: images.isNotEmpty ? images : [avatarUrl],
      interests: interests,
      city: city,
      distance: 0.5,
      height: height,
      relationshipType: relationshipType,
      zodiac: zodiac,
      gender: gender,
      languages: languages,
      lifestyle: lifestyle,
      orientation: orientation,
      isPlatinum: isPlatinum,
      prompts: prompts,
      preferredMode: mode,
    );
  }

  static UserProfile defaultProfile() {
    return UserProfile(
      id: 'default_me',
      name: 'Mehmet',
      email: 'mehmet@tu-berlin.de',
      age: 22,
      university: 'TU Berlin',
      major: 'Informatik',
      semester: 4,
      gender: 'Mann',
      orientation: 'Heterosexuell',
      mode: 'Dating',
      relationshipIntent: 'Feste Beziehung',
      bio:
          'Lerne gerne in der Hauptbibliothek, trinke zu viel Kaffee und bouldere am Wochenende! 🧗‍♂️☕️💻',
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      images: [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      ],
      interests: ['Coding 💻', 'Kaffee ☕', 'Gym 💪', 'Bouldern 🧗'],
      prompts: {
        'Mein bester Campus-Lifehack':
            'Immer vor 11:30 in die Mensa gehen, um nicht anzustehen!',
        'Mein Lieblingsplatz': 'Der Campus-Garten hinter dem Informatikgebäude',
      },
      height: 182,
      relationshipType: 'Monogam',
      zodiac: 'Wassermann',
      city: 'Berlin',
      isVerified: true, // Default profile is verified for testing
      verificationMethod: 'email',
    );
  }
}
