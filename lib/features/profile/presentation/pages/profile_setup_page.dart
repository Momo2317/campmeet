import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/core/services/firebase_auth_service.dart';
import 'package:camp_meet/features/home/app_home.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  int _currentStep = 0;

  // Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registering = false;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _uniController = TextEditingController();
  final _majorController = TextEditingController();
  final _semesterController = TextEditingController();
  final _prompt1Controller = TextEditingController();
  final _prompt2Controller = TextEditingController();

  String _selectedGender = 'Frau';
  String _selectedOrientation = 'Heterosexuell';
  String _selectedMode = 'Dating';
  String _selectedIntent = 'Feste Beziehung';
  final List<String> _selectedInterests = [];
  final List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _availableInterests = allInterests;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _uniController.dispose();
    _majorController.dispose();
    _semesterController.dispose();
    _prompt1Controller.dispose();
    _prompt2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          if (index < _photos.length) {
            _photos[index] = file.path;
          } else {
            _photos.add(file.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto konnte nicht geladen werden: $e'),
            backgroundColor: const Color(0xFFFF4B6E),
          ),
        );
      }
    }
  }

  void _validateAndProceed() async {
    if (_currentStep == 0) {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _showError('Bitte gib eine gültige E-Mail-Adresse ein.');
        return;
      }
      if (_passwordController.text.length < 8) {
        _showError('Das Passwort muss mindestens 8 Zeichen lang sein.');
        return;
      }
    } else if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Bitte gib deinen Vornamen ein.');
        return;
      }
      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 17 || age > 99) {
        _showError('Bitte gib ein gültiges Alter (mind. 17) ein.');
        return;
      }
    } else if (_currentStep == 3) {
      if (_uniController.text.trim().isEmpty) {
        _showError('Bitte gib deine Universität oder Hochschule an.');
        return;
      }
    }

    if (_currentStep < 7) {
      setState(() => _currentStep++);
    } else {
      // 💾 Profil erstellen und speichern
      final defaultAvatars = [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
      ];
      final finalPhotos = _photos.isNotEmpty ? _photos : defaultAvatars;

      // 🔐 Echtes Konto anlegen (unverifiziert, Bestätigungsmail wird gesendet)
      if (_registering) return;
      setState(() => _registering = true);
      String uid;
      try {
        uid = await FirebaseAuthService().signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _registering = false;
          _currentStep = 0;
        });
        _showError(e.message);
        return;
      }

      final newProfile = UserProfile(
        id: uid,
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Student',
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : 'student@uni.de',
        age: int.tryParse(_ageController.text.trim()) ?? 21,
        university: _uniController.text.trim().isNotEmpty
            ? _uniController.text.trim()
            : 'TU Berlin',
        major: _majorController.text.trim().isNotEmpty
            ? _majorController.text.trim()
            : 'Informatik',
        semester: int.tryParse(_semesterController.text.trim()) ?? 1,
        gender: _selectedGender,
        orientation: _selectedOrientation,
        mode: _selectedMode,
        relationshipIntent: _selectedIntent,
        avatarUrl: finalPhotos.first,
        images: finalPhotos,
        interests: _selectedInterests.isNotEmpty
            ? _selectedInterests
            : ['Kaffee ☕', 'Gym 💪', 'Coding 💻'],
        prompts: {
          'Mein Lieblingsort auf dem Campus':
              _prompt1Controller.text.trim().isNotEmpty
                  ? _prompt1Controller.text.trim()
                  : 'Die Bibliothek im 3. Stock',
          'Mensa-Kaffee oder Energydrink?':
              _prompt2Controller.text.trim().isNotEmpty
                  ? _prompt2Controller.text.trim()
                  : 'Definitiv Eiskaffee!',
        },
      );

      await ref.read(userProfileProvider.notifier).saveProfile(newProfile);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AppHome()),
        (route) => false,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle()),
        backgroundColor: const Color(0xFFFF4B6E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text('Profil erstellen',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 20, color: context.fg)),
        centerTitle: true,
        backgroundColor: context.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left,
              size: 24, color: Color(0xFF9B30FF)),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 8,
            backgroundColor: context.fgA(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B30FF)),
            minHeight: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStepContent(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B30FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 7 ? 'Los geht\'s' : 'Weiter',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      if (_currentStep < 7) ...[
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.arrow_right, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailVerification();
      case 1:
        return _buildBasicInfo();
      case 2:
        return _buildGenderAndOrientation();
      case 3:
        return _buildAcademicInfo();
      case 4:
        return _buildModeAndIntent();
      case 5:
        return _buildPhotoUpload();
      case 6:
        return _buildInterests();
      case 7:
        return _buildPrompts();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailVerification() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deine Uni-Mail',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(
            'CampMeet ist exklusiv für Studierende. Du benötigst eine gültige .edu oder Uni-E-Mail-Adresse für die Verifizierung.',
            style: TextStyle(fontSize: 16, color: context.fgA(0.7)),
          ),
          const SizedBox(height: 30),
          _TextField(
            controller: _emailController,
            label: 'E-Mail Adresse',
            hint: 'name@student.uni.de',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _TextField(
            controller: _passwordController,
            label: 'Passwort',
            hint: 'Mindestens 8 Zeichen',
            obscureText: true,
          ),
          const SizedBox(height: 14),
          Text(
            'Wir senden dir einen Bestätigungslink. Mit einer bestätigten Uni-Mail wirst du automatisch verifiziert, sonst kannst du dich mit deinem Studentenausweis verifizieren. Bis dahin ist nur WG & Zimmer freigeschaltet.',
            style: TextStyle(fontSize: 13, color: context.fgA(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wie heißt du?',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 20),
          _TextField(
            controller: _nameController,
            label: 'Vorname',
            hint: 'z.B. Mehmet oder Chloe',
          ),
          const SizedBox(height: 20),
          _TextField(
            controller: _ageController,
            label: 'Alter',
            hint: 'z.B. 21',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderAndOrientation() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Identität & Suche',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(
            'Das wichtigste Kriterium für perfekte Matches.',
            style: TextStyle(fontSize: 16, color: context.fgA(0.7)),
          ),
          const SizedBox(height: 30),
          Text('Mein Geschlecht',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.fg)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['Frau', 'Mann', 'Non-Binär', 'Anderes']
                .map((g) => _SelectChip(
                      label: g,
                      isSelected: _selectedGender == g,
                      onTap: () => setState(() => _selectedGender = g),
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
          Text('Ich suche',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.fg)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['Heterosexuell', 'Homosexuell', 'Bisexuell', 'Anderes']
                .map((o) => _SelectChip(
                      label: o,
                      isSelected: _selectedOrientation == o,
                      onTap: () => setState(() => _selectedOrientation = o),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wo studierst du?',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(
            'Dein Campus-Faktor verbindet dich mit anderen an deiner Uni.',
            style: TextStyle(fontSize: 16, color: context.fgA(0.7)),
          ),
          const SizedBox(height: 30),
          _TextField(
            controller: _uniController,
            label: 'Universität',
            hint: 'z.B. TU Berlin oder Stanford',
          ),
          const SizedBox(height: 20),
          _TextField(
            controller: _majorController,
            label: 'Studiengang',
            hint: 'z.B. Informatik oder Biologie',
          ),
          const SizedBox(height: 20),
          _TextField(
            controller: _semesterController,
            label: 'Semester',
            hint: 'z.B. 1 oder 4',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildModeAndIntent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wonach suchst du?',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(
            'Du kannst das später jederzeit anpassen.',
            style: TextStyle(fontSize: 16, color: context.fgA(0.7)),
          ),
          const SizedBox(height: 30),
          Text('Dein Modus',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.fg)),
          const SizedBox(height: 15),
          _ModeCard(
            title: 'Dating',
            description: 'Finde dein Match und entdecke neue Leute.',
            isSelected: _selectedMode == 'Dating',
            onTap: () => setState(() => _selectedMode = 'Dating'),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            title: 'Study Buddy',
            description: 'Partner zum Lernen und für Uni-Projekte.',
            isSelected: _selectedMode == 'Study Buddy',
            onTap: () => setState(() => _selectedMode = 'Study Buddy'),
          ),
          const SizedBox(height: 30),
          if (_selectedMode == 'Dating') ...[
            Text('Beziehungsabsicht',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.fg)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                'Feste Beziehung',
                'Was Lockeres',
                'Neue Freunde',
                'Noch nicht sicher'
              ]
                  .map((i) => _SelectChip(
                        label: i,
                        isSelected: _selectedIntent == i,
                        onTap: () => setState(() => _selectedIntent = i),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zeig dich!',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(
            'Lade deine besten Fotos hoch oder tippe auf ein Feld, um ein Bild auszuwählen.',
            style:
                TextStyle(fontSize: 16, color: context.fgA(0.7), height: 1.4),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPhotoBox(index: 0, isMain: true),
              _buildPhotoBox(index: 1),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPhotoBox(index: 2),
              _buildPhotoBox(index: 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox({required int index, bool isMain = false}) {
    final hasPhoto = index < _photos.length;
    final photoPath = hasPhoto ? _photos[index] : null;

    return GestureDetector(
      onTap: () => _pickPhoto(index),
      child: Container(
        width: 140,
        height: 190,
        decoration: BoxDecoration(
          color: context.fgA(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMain ? const Color(0xFF9B30FF) : context.fgA(0.24),
            width: isMain ? 2 : 1,
          ),
          image: photoPath != null
              ? DecorationImage(
                  image: photoPath.startsWith('http')
                      ? NetworkImage(photoPath) as ImageProvider
                      : FileImage(File(photoPath)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: photoPath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.camera_fill,
                      size: 32, color: context.fgA(0.38)),
                  const SizedBox(height: 8),
                  Text(
                    isMain ? 'Hauptfoto' : 'Foto hinzufügen',
                    style: TextStyle(
                      color:
                          isMain ? const Color(0xFF9B30FF) : context.fgA(0.38),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.pencil,
                      size: 16, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildInterests() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deine Interessen',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(
            'Wähle 3-5 Interessen aus, damit andere schnell gemeinsame Themen mit dir finden.',
            style: TextStyle(fontSize: 16, color: context.fgA(0.7)),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      if (_selectedInterests.length < 5) {
                        _selectedInterests.add(interest);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Maximal 5 Interessen erlaubt.',
                                style: TextStyle(color: context.fg)),
                            backgroundColor: const Color(0xFFFF4B6E),
                          ),
                        );
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF9B30FF)
                        : context.fgA(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF9B30FF)
                            : context.fgA(0.1)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: const Color(0xFF9B30FF).withOpacity(0.3),
                                blurRadius: 8)
                          ]
                        : [],
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? Colors.white : context.fgA(0.7),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          Text('${_selectedInterests.length}/5 ausgewählt',
              style: TextStyle(color: context.fgA(0.54), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPrompts() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Icebreaker',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(
            'Beantworte kurze Fragen, damit andere leichter ins Gespräch einsteigen können!',
            style: TextStyle(fontSize: 16, color: context.fgA(0.7)),
          ),
          const SizedBox(height: 30),
          _TextField(
            controller: _prompt1Controller,
            label: 'Mein Lieblingsort auf dem Campus...',
            hint: 'z.B. Die Bibliothek im 3. Stock',
          ),
          const SizedBox(height: 20),
          _TextField(
            controller: _prompt2Controller,
            label: 'Mensa-Kaffee oder Energydrink?',
            hint: 'z.B. Definitiv Eiskaffee!',
          ),
        ],
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9B30FF).withOpacity(0.15)
              : context.fgA(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSelected ? const Color(0xFF9B30FF) : context.fgA(0.1),
              width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? context.fg : context.fgA(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9B30FF).withOpacity(0.15)
              : context.fgA(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9B30FF) : context.fgA(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.fg)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description,
                        style:
                            TextStyle(fontSize: 14, color: context.fgA(0.6))),
                  ]
                ],
              ),
            ),
            if (isSelected)
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF9B30FF)),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool obscureText;

  const _TextField({
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                color: context.fgA(0.7),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: !obscureText,
          enableSuggestions: !obscureText,
          style: TextStyle(color: context.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.fgA(0.24)),
            filled: true,
            fillColor: context.fgA(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
