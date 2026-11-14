import 'package:camp_meet/core/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _uniController = TextEditingController();
  final _majorController = TextEditingController();

  /// Feste Fragen der Profil-Highlights (die Antworten stehen in `prompts`)
  static const _highlightQuestions = [
    'Mein bester Campus-Lifehack',
    'Mein Lieblingsplatz',
  ];
  final Map<String, TextEditingController> _highlightControllers = {
    for (final q in _highlightQuestions) q: TextEditingController(),
  };

  String _zodiac = 'Wassermann';
  String _relationshipType = 'Monogam';
  String _orientation = 'Hetero';
  String _gender = 'Frau';
  Map<String, String> _lifestyle = {};
  List<String> _languages = [];
  String _height = '182';
  String _preferredMode = 'Dating';

  final List<String> _zodiacOptions = [
    'Widder',
    'Stier',
    'Zwillinge',
    'Krebs',
    'Löwe',
    'Jungfrau',
    'Waage',
    'Skorpion',
    'Schütze',
    'Steinbock',
    'Wassermann',
    'Fische'
  ];

  final List<String> _relationshipOptions = [
    'Monogam',
    'Offene Beziehung',
    'Polyamor',
    'Feste Beziehung',
    'Etwas Lockeres',
    'Noch unklar'
  ];

  final List<String> _genderOptions = ['Frau', 'Mann', 'Non-Binär', 'Anderes'];

  final List<String> _orientationOptions = [
    'Hetero',
    'Schwul',
    'Lesbisch',
    'Bisexuell',
    'Pansexuell',
    'Asexuell',
    'Queer'
  ];

  final List<String> _heightOptions =
      List.generate(81, (index) => (140 + index).toString());
  final List<String> _modeOptions = ['Dating', 'Study Buddy', 'Beides'];

  List<String> _userImages = [];
  List<String> _interests = [];
  bool _initialized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user =
          ref.read(userProfileProvider) ?? UserProfile.defaultProfile();
      _nameController.text = user.name;
      _bioController.text = user.bio;
      _uniController.text = user.university;
      _majorController.text = user.major;
      for (final q in _highlightQuestions) {
        _highlightControllers[q]?.text = user.prompts[q] ?? '';
      }
      _height = (user.height ?? 182).toString();
      _zodiac = user.zodiac ?? 'Wassermann';
      _relationshipType = user.relationshipType ?? 'Monogam';
      _orientation = user.orientation.isNotEmpty ? user.orientation : 'Hetero';
      _gender = _genderOptions.contains(user.gender) ? user.gender : 'Anderes';
      _preferredMode = user.mode;
      _lifestyle = Map.from(user.lifestyle);
      _languages = List.from(user.languages);
      _userImages = List.from(user.images);
      if (_userImages.isEmpty && user.avatarUrl.isNotEmpty) {
        _userImages.add(user.avatarUrl);
      }
      _interests = List.from(user.interests);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _uniController.dispose();
    _majorController.dispose();
    for (final c in _highlightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _removePhoto(int index) {
    if (_userImages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du musst mindestens 1 Profilfoto behalten!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _userImages.removeAt(index);
    });
  }

  Future<void> _addPhoto() async {
    if (_userImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximal 6 Fotos erlaubt.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _userImages.add(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto konnte nicht gewählt werden: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _addInterest() {
    if (_interests.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximal 8 Hashtags erlaubt!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Neuer Hashtag', style: TextStyle(color: context.fg)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: context.fg),
                decoration: InputDecoration(
                  hintText: 'z.B. Kochen, Gaming, Bouldern...',
                  hintStyle: TextStyle(color: context.fgA(0.38)),
                  filled: true,
                  fillColor: context.fgA(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              Text('Vorschläge',
                  style: TextStyle(color: context.fgA(0.54), fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allInterests
                    .where((i) => !_interests.contains(i))
                    .map((i) => GestureDetector(
                          onTap: () {
                            setState(() => _interests.add(i));
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: context.fgA(0.07),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(i,
                                style:
                                    TextStyle(color: context.fg, fontSize: 13)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Abbrechen', style: TextStyle(color: context.fgA(0.54))),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _interests.add(text.startsWith('#') ? text : '#$text');
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B30FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hinzufügen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final uni = _uniController.text.trim();
    final major = _majorController.text.trim();
    final currentPrompts = ref.read(userProfileProvider)?.prompts ?? const {};
    final prompts = <String, String>{
      for (final e in currentPrompts.entries)
        if (!_highlightQuestions.contains(e.key)) e.key: e.value,
      for (final q in _highlightQuestions)
        if (_highlightControllers[q]!.text.trim().isNotEmpty)
          q: _highlightControllers[q]!.text.trim(),
    };

    await ref.read(userProfileProvider.notifier).updateProfile(
          name: name.isNotEmpty ? name : null,
          bio: bio,
          university: uni.isNotEmpty ? uni : null,
          major: major.isNotEmpty ? major : null,
          height: int.tryParse(_height),
          zodiac: _zodiac,
          relationshipType: _relationshipType,
          orientation: _orientation,
          gender: _gender,
          lifestyle: _lifestyle,
          languages: _languages,
          mode: _preferredMode,
          images: _userImages,
          avatarUrl: _userImages.isNotEmpty ? _userImages.first : null,
          interests: _interests,
          prompts: prompts,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil erfolgreich gespeichert! ✨', style: TextStyle()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil bearbeiten',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Speichern',
              style: TextStyle(
                  color: const Color(0xFF9B30FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoGrid(),
            const SizedBox(height: 25),
            _buildInputField('Vorname', _nameController, maxLines: 1),
            const SizedBox(height: 18),
            _buildInputField('Über mich (Bio)', _bioController,
                maxLines: 4,
                hint:
                    'Erzähle etwas über dich, deine Hobbys und deinen Campus-Alltag...'),
            const SizedBox(height: 18),
            _buildInputField('Universität / Hochschule', _uniController,
                maxLines: 1),
            const SizedBox(height: 18),
            _buildInputField('Studiengang', _majorController, maxLines: 1),
            const SizedBox(height: 18),
            for (final q in _highlightQuestions) ...[
              _buildInputField(q, _highlightControllers[q]!,
                  maxLines: 2,
                  hint: 'Deine Antwort (wird als Highlight gezeigt)'),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                    child: _buildDropdownSection(
                        'Größe (cm)',
                        _height,
                        _heightOptions,
                        (val) => setState(() => _height = val))),
                const SizedBox(width: 15),
                Expanded(
                    child: _buildDropdownSection(
                        'Sternzeichen',
                        _zodiac,
                        _zodiacOptions,
                        (val) => setState(() => _zodiac = val))),
              ],
            ),
            const SizedBox(height: 20),
            _buildDropdownSection(
                'Beziehungstyp',
                _relationshipType,
                _relationshipOptions,
                (val) => setState(() => _relationshipType = val)),
            const SizedBox(height: 20),
            _buildDropdownSection('Geschlecht', _gender, _genderOptions,
                (val) => setState(() => _gender = val)),
            const SizedBox(height: 20),
            _buildDropdownSection(
                'Orientierung',
                _orientation,
                _orientationOptions,
                (val) => setState(() => _orientation = val)),
            const SizedBox(height: 20),
            _buildDropdownSection('Gesuchter Modus', _preferredMode,
                _modeOptions, (val) => setState(() => _preferredMode = val)),
            const SizedBox(height: 25),
            _buildInterestsSection(),
            const SizedBox(height: 25),
            Text('Sprachen',
                style: TextStyle(
                    color: context.fgA(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languageOptions.map((l) {
                final selected = _languages.contains(l);
                return FilterChip(
                  label: Text(l,
                      style: TextStyle(color: context.fg, fontSize: 13)),
                  selected: selected,
                  selectedColor: const Color(0xFF9B30FF),
                  backgroundColor: context.fgA(0.07),
                  checkmarkColor: context.fg,
                  side: BorderSide.none,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _languages.add(l);
                    } else {
                      _languages.remove(l);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            Text('Lifestyle',
                style: TextStyle(
                    color: context.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final entry in lifestyleOptions.entries) ...[
              _buildDropdownSection(
                lifestyleQuestions[entry.key] ?? entry.key,
                _lifestyle[entry.key] ?? 'Nicht angegeben',
                ['Nicht angegeben', ...entry.value],
                (val) => setState(() {
                  if (val == 'Nicht angegeben') {
                    _lifestyle.remove(entry.key);
                  } else {
                    _lifestyle[entry.key] = val;
                  }
                }),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fotos & Medien',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.fg)),
            Text('${_userImages.length}/6 Fotos',
                style: TextStyle(color: context.fgA(0.54), fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index < _userImages.length) {
              return _PhotoTile(
                imageUrl: _userImages[index],
                isMain: index == 0,
                onDelete: () => _removePhoto(index),
              );
            } else {
              return GestureDetector(
                onTap: _addPhoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.fgA(0.04),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: context.fgA(0.12), style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Icon(Icons.add, color: context.fgA(0.38), size: 30),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.fgA(0.7))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: context.fg, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.fgA(0.24), fontSize: 14),
            filled: true,
            fillColor: context.fgA(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSection(String title, String value, List<String> options,
      Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: context.fgA(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: context.fgA(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              dropdownColor: context.surface,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: context.fgA(0.54)),
              style: TextStyle(color: context.fg, fontSize: 15),
              items: options.map((String opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) onChanged(newVal);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Interessen & Hashtags',
                style: TextStyle(
                    color: context.fgA(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text('${_interests.length}/8',
                style: TextStyle(color: context.fgA(0.38), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._interests.map((interest) => _InterestChip(
                  label: interest,
                  onDelete: () => setState(() => _interests.remove(interest)),
                )),
            if (_interests.length < 8)
              _InterestChip(
                label: '+ Hinzufügen',
                isAdd: true,
                onTap: _addInterest,
              ),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String imageUrl;
  final bool isMain;
  final VoidCallback onDelete;
  const _PhotoTile(
      {required this.imageUrl, this.isMain = false, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: imageUrl.startsWith('http')
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Image.file(File(imageUrl), fit: BoxFit.cover),
          ),
        ),
        if (isMain)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9B30FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Hauptbild',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: context.fg, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isAdd;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _InterestChip({
    required this.label,
    this.isAdd = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isAdd
              ? context.fgA(0.08)
              : const Color(0xFF9B30FF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isAdd ? context.fgA(0.24) : const Color(0xFF9B30FF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAdd ? label : interestWithEmoji(label),
              style: TextStyle(
                color: context.fg,
                fontSize: 13,
                fontWeight: isAdd ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (!isAdd && onDelete != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, color: context.fgA(0.7), size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
