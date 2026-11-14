class Student {
  final String id;
  final String name;
  final int age;
  final String university;
  final String major;
  final String bio;
  final String imageUrl;
  final List<String> images;
  final List<String> interests;
  final int? height;
  final String? relationshipType;
  final String? zodiac;
  final String? gender;
  final List<String> languages;
  final Map<String, String> lifestyle;
  final String? orientation;
  final bool isPlatinum;
  final int popularityScore;
  final String city;
  final double distance;
  final Map<String, String>? prompts;
  final String preferredMode;

  Student({
    required this.id,
    required this.name,
    required this.age,
    required this.university,
    required this.major,
    required this.bio,
    required this.imageUrl,
    required this.images,
    required this.interests,
    this.height,
    this.relationshipType,
    this.zodiac,
    this.gender,
    this.languages = const [],
    this.lifestyle = const {},
    this.orientation,
    this.isPlatinum = false,
    this.popularityScore = 0,
    required this.city,
    required this.distance,
    this.prompts,
    this.preferredMode = 'Dating',
  });
}

/// Emojis für Interessen (Stichwort -> Emoji).
const Map<String, String> _interestEmojis = {
  'foto': '📸',
  'wander': '🥾',
  'reis': '✈️',
  'techno': '🎛️',
  'coding': '💻',
  'bar': '🍻',
  'gym': '💪',
  'fitness': '💪',
  'startup': '🚀',
  'koch': '🍳',
  'art': '🎨',
  'kunst': '🎨',
  'design': '✏️',
  'yoga': '🧘',
  'kaffee': '☕',
  'café': '☕',
  'psycho': '🧠',
  'buch': '📚',
  'bücher': '📚',
  'lesen': '📖',
  'wein': '🍷',
  'boulder': '🧗',
  'motorsport': '🏎️',
  'jura': '⚖️',
  'basketball': '🏀',
  'gaming': '🎮',
  'architektur': '🏛️',
  'vintage': '🧥',
  'chess': '♟️',
  'schach': '♟️',
  'ai': '🤖',
  'ki': '🤖',
  'piano': '🎹',
  'physik': '⚛️',
  'stern': '🌟',
  'musik': '🎵',
  'fußball': '⚽',
  'tanz': '💃',
  'film': '🎬',
  'party': '🎉',
  'sport': '🏅',
  'natur': '🌿',
  'schwimm': '🏊',
  'rad': '🚴',
  'lauf': '🏃',
  'tennis': '🎾',
  'mode': '👗',
};

/// Auswahl an Interessen (mit Emoji).
const List<String> allInterests = [
  '☕ Kaffee',
  '🎛️ Techno',
  '💪 Gym',
  '🧗 Bouldern',
  '📚 Bib-Hänger',
  '🥗 Vegan',
  '🎮 Gaming',
  '✈️ Reisen',
  '📸 Fotografie',
  '🚶 Spazieren',
  '🍻 Bars',
  '🍷 Wein',
  '🎵 Musik',
  '🎤 Konzerte',
  '🎪 Festivals',
  '🎬 Filme',
  '📺 Serien',
  '🍿 Kino',
  '🍳 Kochen',
  '🍕 Essen gehen',
  '🧁 Backen',
  '⚽ Fußball',
  '🏀 Basketball',
  '🎾 Tennis',
  '🏃 Laufen',
  '🚴 Radfahren',
  '🏊 Schwimmen',
  '🧘 Yoga',
  '⛷️ Skifahren',
  '🏄 Surfen',
  '🥾 Wandern',
  '⛺ Camping',
  '🌿 Natur',
  '🐶 Hunde',
  '🐱 Katzen',
  '🎨 Kunst',
  '🖌️ Zeichnen',
  '✍️ Schreiben',
  '📖 Lesen',
  '🎹 Klavier',
  '🎸 Gitarre',
  '💃 Tanzen',
  '🎭 Theater',
  '🏛️ Museen',
  '💻 Coding',
  '🚀 Startups',
  '🤖 KI',
  '♟️ Schach',
  '🎲 Brettspiele',
  '👗 Mode',
  '🧥 Vintage',
  '🌍 Sprachen',
  '🤝 Ehrenamt',
  '🧠 Psychologie',
  '🎉 Feiern',
  '🏎️ Motorsport',
  '🌅 Sonnenuntergänge',
  '🛍️ Shoppen',
  '🧘‍♂️ Meditation',
];

/// Gibt ein Interesse immer mit Emoji vorne zurück (z.B. "💻 Coding").
String interestWithEmoji(String raw) {
  var text = raw.trim();
  if (text.startsWith('#')) text = text.substring(1).trim();
  if (text.isEmpty) return text;

  bool isEmojiRune(int r) => r >= 0x2190 || r == 0x200D;

  // Emoji bereits vorne -> unverändert
  if (isEmojiRune(text.runes.first)) return text;

  // Emoji am Ende abtrennen
  final runes = text.runes.toList();
  var end = runes.length;
  while (end > 0 && (isEmojiRune(runes[end - 1]) || runes[end - 1] == 0x20)) {
    end--;
  }
  final clean = String.fromCharCodes(runes.sublist(0, end)).trim();
  final tail = String.fromCharCodes(runes.sublist(end)).trim();
  if (tail.isNotEmpty) return '$tail $clean';

  final lower = clean.toLowerCase();
  for (final e in _interestEmojis.entries) {
    if (lower.contains(e.key)) return '${e.value} $clean';
  }
  return '✨ $clean';
}

/// Auswählbare Sprachen.
const List<String> languageOptions = [
  'Deutsch',
  'Englisch',
  'Türkisch',
  'Spanisch',
  'Französisch',
  'Italienisch',
  'Arabisch',
  'Russisch',
  'Polnisch',
  'Portugiesisch',
  'Chinesisch',
  'Japanisch',
  'Koreanisch',
  'Hindi',
  'Niederländisch',
  'Griechisch',
  'Ukrainisch',
];

/// Lifestyle-Kategorien mit auswählbaren Optionen.
const Map<String, List<String>> lifestyleOptions = {
  'Trinken': ['Nie', 'Gelegentlich', 'Gesellig', 'Gerne'],
  'Rauchen': ['Nichtraucher', 'Gelegentlich', 'Gesellig', 'Raucher'],
  'Sport': ['Täglich', 'Oft', 'Manchmal', 'Selten'],
  'Social Media': ['Kaum', 'Moderat', 'Aktiv', 'Sehr aktiv'],
  'Ernährung': ['Alles', 'Vegetarisch', 'Vegan', 'Pescetarisch'],
  'Haustiere': ['Hund', 'Katze', 'Keine', 'Mag Tiere'],
  'Schlafrhythmus': ['Frühaufsteher', 'Nachteule', 'Flexibel'],
};

/// Fragen, die im Profil-Editor zu den Lifestyle-Kategorien gestellt werden.
const Map<String, String> lifestyleQuestions = {
  'Trinken': 'Wie oft trinkst du Alkohol?',
  'Rauchen': 'Wie oft rauchst du?',
  'Sport': 'Wie oft machst du Sport?',
  'Social Media': 'Wie aktiv bist du auf Social Media?',
  'Ernährung': 'Wie ernährst du dich?',
  'Haustiere': 'Hast du Haustiere oder magst du Tiere?',
  'Schlafrhythmus': 'Bist du Frühaufsteher oder Nachteule?',
};

final List<Student> mockStudents = [
  Student(
    id: '1',
    name: 'Chloe Evans',
    age: 21,
    university: 'Stanford University',
    major: 'Biology',
    bio:
        'Wildlife-Fotografie, Wandern und neue Cafés am Campus entdecken. Suche jemanden für spontane Abenteuer! 🌿☕️📸',
    imageUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
    images: [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
    ],
    interests: ['Fotografie', 'Wandern', 'Reisen'],
    height: 168,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Skorpion',
    gender: 'Frau',
    languages: ['Deutsch', 'Englisch'],
    lifestyle: {
      'Trinken': 'Nie',
      'Rauchen': 'Gelegentlich',
      'Sport': 'Manchmal',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Alles',
      'Haustiere': 'Katze',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 98,
    city: 'Palo Alto',
    distance: 2.5,
    prompts: {
      'Meine peinlichste Vorlesungs-Story':
          'Bin vor 200 Leuten auf der Mensa-Treppe ausgerutscht. Mein Kaffee flog durch den Saal. ☕️😭',
      'Kaffee oder Energydrink?': 'Kaffee, auf jeden Fall!',
    },
  ),
  Student(
    id: '2',
    name: 'Mia Hoffmann',
    age: 22,
    university: 'TU Berlin',
    major: 'Medieninformatik',
    bio:
        'Zwischen Coding-Deadlines und Techno-Wochenenden in Berlin. Zeig mir deine beste Spotify-Playlist! 🎧💻🖤',
    imageUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
    images: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
    ],
    interests: ['Techno 🎛️', 'Coding 💻', 'Bars 🍻'],
    height: 172,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Zwillinge',
    gender: 'Frau',
    languages: ['Deutsch', 'Englisch', 'Türkisch'],
    lifestyle: {
      'Trinken': 'Gelegentlich',
      'Rauchen': 'Raucher',
      'Sport': 'Oft',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Vegetarisch',
      'Haustiere': 'Mag Tiere',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 96,
    city: 'Berlin',
    distance: 1.8,
    prompts: {
      'Mein Lieblingsort am Campus':
          'Die Dachterrasse des Telefunken-Hochhauses bei Sonnenuntergang 🌅',
    },
  ),
  Student(
    id: '3',
    name: 'Leon Weber',
    age: 24,
    university: 'TU Berlin',
    major: 'Wirtschaftsingenieurwesen',
    bio:
        'Gym, Start-ups und Espresso. Suche jemanden, der mit mir am Campus lernt oder abends kocht. 🏋️‍♂️🍝',
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
    images: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=800',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
    ],
    interests: ['Gym 💪', 'Startups 🚀', 'Kochen 🍳'],
    height: 188,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Widder',
    gender: 'Mann',
    languages: ['Deutsch', 'Englisch', 'Spanisch'],
    lifestyle: {
      'Trinken': 'Gesellig',
      'Rauchen': 'Gelegentlich',
      'Sport': 'Täglich',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Vegan',
      'Haustiere': 'Katze',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 94,
    city: 'Berlin',
    distance: 3.2,
    prompts: {
      'Bester Mensa-Hack': 'Mittwochs immer früher zur Currywurst anstehen!',
    },
  ),
  Student(
    id: '4',
    name: 'Sophia Chen',
    age: 22,
    university: 'Stanford University',
    major: 'Architecture',
    bio:
        'Designing the future one sketch at a time. Art galleries are my second home. 🎨🏛️',
    imageUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
    images: [
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
    ],
    interests: ['Art', 'Design', 'Yoga'],
    height: 165,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Stier',
    gender: 'Frau',
    languages: ['Deutsch', 'Französisch'],
    lifestyle: {
      'Trinken': 'Gerne',
      'Rauchen': 'Raucher',
      'Sport': 'Selten',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Pescetarisch',
      'Haustiere': 'Mag Tiere',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Bisexuell',
    isPlatinum: true,
    popularityScore: 93,
    city: 'Mountain View',
    distance: 5.8,
  ),
  Student(
    id: '5',
    name: 'Michael Becker',
    age: 23,
    university: 'Berkeley',
    major: 'Architecture',
    bio:
        'Architektur-Student in Berkeley. Ich liebe minimalistisches Design, Specialty Coffee und Vinyl. ☕️📐',
    imageUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
    images: [
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=800',
    ],
    interests: ['Design', 'Kaffee', 'Reisen'],
    height: 182,
    relationshipType: 'Etwas Lockeres',
    zodiac: 'Zwillinge',
    gender: 'Mann',
    languages: ['Deutsch', 'Englisch', 'Italienisch'],
    lifestyle: {
      'Trinken': 'Nie',
      'Rauchen': 'Gelegentlich',
      'Sport': 'Manchmal',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Alles',
      'Haustiere': 'Katze',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 91,
    city: 'San Francisco',
    distance: 15.2,
  ),
  Student(
    id: '6',
    name: 'Elena Rostova',
    age: 21,
    university: 'LMU München',
    major: 'Psychologie',
    bio:
        'Warum Menschen tun, was sie tun. Liebt tiefe Gespräche nachts um 2 Uhr und Spaziergänge im Englischen Garten 🍂📖',
    imageUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
    images: [
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
    ],
    interests: ['Psychologie', 'Bücher 📚', 'Wein 🍷'],
    height: 169,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Fische',
    gender: 'Frau',
    languages: ['Deutsch', 'Russisch', 'Englisch'],
    lifestyle: {
      'Trinken': 'Gelegentlich',
      'Rauchen': 'Raucher',
      'Sport': 'Oft',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Vegetarisch',
      'Haustiere': 'Mag Tiere',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 89,
    city: 'München',
    distance: 8.4,
  ),
  Student(
    id: '7',
    name: 'David Krause',
    age: 25,
    university: 'TU Berlin',
    major: 'Maschinenbau',
    bio:
        'Formel Student Rennteam & Bouldern. Wenn ich nicht in der Werkstatt bin, koche ich gerne aufwendig. 🏎️🧗‍♂️',
    imageUrl:
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
    images: [
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=800',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
    ],
    interests: ['Bouldern 🧗', 'Motorsport', 'Kochen 🍝'],
    height: 184,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Löwe',
    gender: 'Mann',
    languages: ['Deutsch', 'Englisch', 'Arabisch'],
    lifestyle: {
      'Trinken': 'Gesellig',
      'Rauchen': 'Gelegentlich',
      'Sport': 'Täglich',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Vegan',
      'Haustiere': 'Katze',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 87,
    city: 'Berlin',
    distance: 4.1,
  ),
  Student(
    id: '8',
    name: 'Sarah Lindner',
    age: 22,
    university: 'HU Berlin',
    major: 'Rechtswissenschaften',
    bio:
        'Jura-Studentin mit Hang zu gutem Humor und noch besserem Espresso. Lass uns die Bib gegen eine Bar tauschen ⚖️🥂',
    imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
    images: [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
    ],
    interests: ['Jura', 'Bars 🍻', 'Fitness 💪'],
    height: 167,
    relationshipType: 'Monogam',
    zodiac: 'Waage',
    gender: 'Frau',
    languages: ['Deutsch', 'Polnisch'],
    lifestyle: {
      'Trinken': 'Gerne',
      'Rauchen': 'Raucher',
      'Sport': 'Selten',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Pescetarisch',
      'Haustiere': 'Mag Tiere',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 85,
    city: 'Berlin',
    distance: 2.9,
  ),
  Student(
    id: '9',
    name: 'Lucas Meier',
    age: 23,
    university: 'MIT',
    major: 'Data Science',
    bio:
        'Big Data & Basketball. Suche eine(n) Sparring-Partner(in) für lange Abende und gute Gespräche 🏀📊',
    imageUrl:
        'https://images.unsplash.com/photo-1463453091185-61582044d556?w=800',
    images: [
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=800',
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
    ],
    interests: ['Basketball 🏀', 'Coding 💻', 'Gaming 🎮'],
    height: 191,
    relationshipType: 'Offen für alles',
    zodiac: 'Schütze',
    gender: 'Mann',
    languages: ['Deutsch', 'Englisch', 'Portugiesisch'],
    lifestyle: {
      'Trinken': 'Nie',
      'Rauchen': 'Gelegentlich',
      'Sport': 'Manchmal',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Alles',
      'Haustiere': 'Katze',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 84,
    city: 'Cambridge',
    distance: 1.2,
  ),
  Student(
    id: '10',
    name: 'Hannah Vogt',
    age: 21,
    university: 'TU Berlin',
    major: 'Architektur',
    bio:
        'Modellbau, Skizzenbücher und Second-Hand-Läden. Lass uns Berlin erkunden! 🏛️☕️🌿',
    imageUrl:
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
    images: [
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
    ],
    interests: ['Architektur', 'Vintage 🧥', 'Cafés ☕'],
    height: 171,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Krebs',
    gender: 'Frau',
    languages: ['Deutsch', 'Englisch', 'Chinesisch'],
    lifestyle: {
      'Trinken': 'Gelegentlich',
      'Rauchen': 'Raucher',
      'Sport': 'Oft',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Vegetarisch',
      'Haustiere': 'Mag Tiere',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: true,
    popularityScore: 83,
    city: 'Berlin',
    distance: 3.5,
  ),
  Student(
    id: '11',
    name: 'James Wilson',
    age: 23,
    university: 'Stanford University',
    major: 'Computer Science',
    bio:
        'Coding by day, chess by night. Looking for someone to challenge me in both! 💻♟️',
    imageUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
    images: [
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
      'https://images.unsplash.com/photo-1463453091185-61582044d556?w=800',
    ],
    interests: ['Chess', 'AI', 'Piano'],
    height: 185,
    relationshipType: 'Offen für alles',
    zodiac: 'Löwe',
    gender: 'Mann',
    languages: ['Deutsch', 'Spanisch', 'Englisch'],
    lifestyle: {
      'Trinken': 'Gesellig',
      'Rauchen': 'Gelegentlich',
      'Sport': 'Täglich',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Vegan',
      'Haustiere': 'Katze',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: false,
    popularityScore: 78,
    city: 'San Jose',
    distance: 12.0,
  ),
  Student(
    id: '12',
    name: 'Emily Watson',
    age: 20,
    university: 'MIT',
    major: 'Physics',
    bio:
        'Physik-Studentin am MIT. Nerdige Witze und lange Spaziergänge unter den Sternen 🌌🔭',
    imageUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
    images: [
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
    ],
    interests: ['Physik', 'Lesen', 'Sterne'],
    height: 170,
    relationshipType: 'Feste Beziehung',
    zodiac: 'Wassermann',
    gender: 'Frau',
    languages: ['Deutsch', 'Englisch', 'Japanisch'],
    lifestyle: {
      'Trinken': 'Gerne',
      'Rauchen': 'Raucher',
      'Sport': 'Selten',
      'Social Media': 'Sehr aktiv',
      'Ernährung': 'Pescetarisch',
      'Haustiere': 'Mag Tiere',
      'Schlafrhythmus': 'Flexibel'
    },
    orientation: 'Heterosexuell',
    isPlatinum: false,
    popularityScore: 74,
    city: 'Cambridge',
    distance: 0.5,
  ),
];
