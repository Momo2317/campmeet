import 'dart:io';
import 'package:camp_meet/core/services/firebase_auth_service.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/features/verification/data/verification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Kachel "Profil verifizieren" mit Studentenausweis-Upload (für die Profilseite).
class VerificationTile extends ConsumerStatefulWidget {
  const VerificationTile({super.key});

  @override
  ConsumerState<VerificationTile> createState() => _VerificationTileState();
}

class _VerificationTileState extends ConsumerState<VerificationTile> {
  String _verificationStatus = 'unverified';

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
    ref.read(userProfileProvider.notifier).refreshVerification();
  }

  Future<void> _loadVerificationStatus() async {
    final userId = FirebaseAuthService().currentUserId;
    if (userId == null) return;
    try {
      final request =
          await VerificationService().getVerificationRequest(userId);
      if (!mounted || request == null) return;
      setState(() {
        _verificationStatus = switch (request.status) {
          VerificationStatus.pending => 'pending',
          VerificationStatus.approved => 'verified',
          VerificationStatus.rejected => 'unverified',
        };
      });
    } catch (e) {
      debugPrint('Verifizierungsstatus nicht ladbar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPending = _verificationStatus == 'pending';
    bool isVerified = _verificationStatus == 'verified';

    return GestureDetector(
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF27AE60).withOpacity(0.5)
                : (isPending
                    ? Colors.orangeAccent.withOpacity(0.5)
                    : context.fgA(0.1)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isVerified
                    ? const LinearGradient(
                        colors: [Color(0xFF27AE60), Color(0xFF2ECC71)])
                    : (isPending
                        ? const LinearGradient(
                            colors: [Colors.orange, Colors.orangeAccent])
                        : AppTheme.primaryGradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isVerified
                    ? Icons.verified
                    : (isPending
                        ? Icons.pending_actions
                        : Icons.badge_outlined),
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified
                        ? 'Profil verifiziert ✓'
                        : (isPending
                            ? 'Wird geprüft ⏳'
                            : 'Profil verifizieren'),
                    style: TextStyle(
                        color: context.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVerified
                        ? 'Dein Studentenausweis wurde vom Support bestätigt'
                        : (isPending
                            ? 'Unser Team prüft deinen Studentenausweis (ca. 24h)'
                            : 'Lade ein Foto deines Studentenausweises hoch'),
                    style: TextStyle(color: context.fgA(0.54), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isVerified && !isPending)
              ElevatedButton(
                onPressed: () => _showVerificationSheet(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: const Color(0xFF9B30FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Starten', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  void _showVerificationSheet(BuildContext context) {
    XFile? picked;
    var uploading = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> pick(ImageSource source) async {
            final image =
                await ImagePicker().pickImage(source: source, imageQuality: 90);
            if (image != null) setSheet(() => picked = image);
          }

          Future<void> submit() async {
            final image = picked;
            if (image == null) return;
            setSheet(() => uploading = true);
            String? error;
            try {
              final userId = FirebaseAuthService().currentUserId;
              if (userId == null) {
                throw AuthException('Bitte melde dich zuerst an.');
              }
              await VerificationService()
                  .uploadStudentId(userId: userId, imagePath: image.path);
            } catch (e) {
              error = e.toString();
            }
            if (!ctx.mounted) return;
            if (error != null) {
              setSheet(() => uploading = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error), backgroundColor: Colors.redAccent));
              return;
            }
            Navigator.pop(ctx);
            if (!mounted) return;
            setState(() => _verificationStatus = 'pending');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Anfrage gesendet! Wir prüfen deinen Studentenausweis (ca. 24h).'),
                duration: Duration(seconds: 4)));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: context.fgA(0.24),
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: const Icon(Icons.badge_outlined,
                          size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text('Studentenausweis hochladen',
                        style: TextStyle(
                            color: context.fg,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Lade ein gut lesbares Foto deines Studentenausweises hoch. Name und Hochschule müssen sichtbar sein. Alles andere (z. B. Matrikelnummer) darfst du abdecken. Unser Team prüft ihn manuell in ca. 24 Stunden.',
                      style: TextStyle(color: context.fgA(0.54), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (picked != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(File(picked!.path),
                            height: 180, fit: BoxFit.cover),
                      ),
                    if (picked != null) const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              uploading ? null : () => pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Foto aufnehmen'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () => pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galerie'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: picked == null || uploading ? null : submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF9B30FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: uploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Zur Prüfung senden',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
