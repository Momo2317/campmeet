import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';

/// Guard utility for verifying user access to restricted features
class VerificationGuard {
  /// Check if user can access a feature
  static bool canAccessFeature(UserProfile? profile) {
    return profile != null && profile.isVerified;
  }

  /// Check if user is verified
  static bool isUserVerified(UserProfile? profile) {
    return profile != null && profile.isVerified;
  }

  /// Get verification status text
  static String getVerificationStatusText(UserProfile? profile) {
    if (profile == null) return 'Nicht angemeldet';

    if (profile.isVerified) {
      if (profile.verificationMethod == 'email') {
        return 'Verifiziert über Email (${profile.email})';
      } else if (profile.verificationMethod == 'student_id') {
        return 'Verifiziert via Studienausweis';
      }
      return 'Verifiziert';
    }

    return 'Nicht verifiziert';
  }

  /// Show verification prompt dialog
  static void showVerificationPrompt({
    required BuildContext context,
    required String title,
    required String message,
    String? actionButtonText,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          title: Text(
            title,
            style: TextStyle(color: context.fg),
          ),
          content: Text(
            message,
            style: TextStyle(color: context.fgA(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Abbrechen',
                style: TextStyle(color: context.fgA(0.54)),
              ),
            ),
            if (onAction != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                child: Text(
                  actionButtonText ?? 'Verifizieren',
                  style: const TextStyle(color: Color(0xFF9B30FF)),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build verification overlay widget for unverified users on feature pages
  static Widget buildVerificationOverlay({
    required Widget child,
    required bool isVerified,
    required String featureName,
  }) {
    if (isVerified) {
      return child;
    }

    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: child,
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verifizierung erforderlich',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verifizieren Sie Ihren Account um $featureName zu nutzen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF2D9B),
                          Color(0xFF9B30FF),
                          Color(0xFF5B2BF0)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () {
                        // Navigate to verification
                      },
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          'Jetzt verifizieren',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Get feature restriction message
  static String getFeatureRestrictionMessage(String featureName) {
    return 'Das Feature "$featureName" ist nur für verifizierte Benutzer verfügbar. '
        'Bitte verifizieren Sie Ihren Account mit Ihrer Universität-Email oder laden Sie einen Studienausweis hoch.';
  }

  /// List of features that require verification
  static const List<String> restrictedFeatures = [
    'discovery',
    'messaging',
    'likes',
    'radar',
  ];

  /// Check if feature requires verification
  static bool featureRequiresVerification(String featureName) {
    return restrictedFeatures.contains(featureName.toLowerCase());
  }
}
