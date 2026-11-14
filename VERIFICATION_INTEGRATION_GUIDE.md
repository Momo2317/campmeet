# Student Verification System Integration Guide

## Overview
This document explains how to integrate the Student Verification System components into existing pages.

## Created Files Summary

### Firebase Infrastructure
- `lib/core/firebase/firebase_config.dart` - Firebase initialization and university domain config
- `lib/core/services/firebase_auth_service.dart` - Authentication with auto-verification
- `firestore.rules` - Firestore security rules
- `storage.rules` - Firebase Storage security rules

### Verification System
- `lib/features/verification/data/verification_service.dart` - Student ID upload service
- `lib/features/verification/presentation/providers/verification_providers.dart` - Riverpod providers
- `lib/features/admin/presentation/pages/verification_requests_page.dart` - Admin panel page

### User Profile
- `lib/features/profile/data/firestore_user_profile_repository.dart` - Firestore sync
- `lib/features/profile/data/user_profile_providers.dart` - Riverpod providers
- `lib/features/profile/data/user_profile_model.dart` - Updated with verification fields

### UI Components
- `lib/core/widgets/verification_badge.dart` - Verification badge widgets
- `lib/core/guards/verification_guard.dart` - Feature restriction utility

## Integration Steps

### 1. Update login_page.dart (PRIORITY)

```dart
import 'package:camp_meet/core/services/firebase_auth_service.dart';
import 'package:camp_meet/features/verification/presentation/providers/verification_providers.dart';

class LoginPageState extends State<LoginPage> {
  final _authService = FirebaseAuthService();

  Future<void> _handleLogin(String email, String password) async {
    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null && mounted) {
        ref.read(authSessionProvider.notifier).state = true;
        Navigator.of(context).pushReplacementNamed('/discovery');
      }
    } catch (e) {
      // Show error dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleSignUp(String email, String password) async {
    try {
      final userId = await _authService.signUp(
        email: email,
        password: password,
      );

      // Check if auto-verified
      final verificationStatus = await _authService.getUserVerificationStatus(userId);
      final isVerified = verificationStatus?['isVerified'] ?? false;

      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Willkommen! Deine Uni-Email wurde automatisch verifiziert.'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account erstellt! Bitte verifiziere deinen Account unter Sicherheit.'),
          ),
        );
      }

      if (mounted) {
        ref.read(authSessionProvider.notifier).state = true;
        Navigator.of(context).pushReplacementNamed('/discovery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
```

### 2. Update security_page.dart (PRIORITY)

Replace the `_showVerificationSheet` method:

```dart
void _showVerificationSheet(BuildContext context, WidgetRef ref) {
  final imagePicker = ImagePicker();

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ... existing UI ...

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final image = await imagePicker.pickImage(
                  source: ImageSource.camera,
                );

                if (image != null && context.mounted) {
                  final userId = ref.read(currentUserIdProvider);
                  if (userId != null) {
                    final uploadNotifier = ref.read(
                      verificationUploadProvider.notifier,
                    );

                    await uploadNotifier.uploadStudentId(
                      userId: userId,
                      imagePath: image.path,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Verifizierung eingereicht'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera öffnen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF6A11CB),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 3. Add Verification Tab to admin_dashboard_page.dart

In the tab list, add:

```dart
Tab(
  child: Text(
    '🔐 Verifizierung',
    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
  ),
),
```

And in the tab views, add:

```dart
const VerificationRequestsPage(),
```

Import:
```dart
import 'package:camp_meet/features/admin/presentation/pages/verification_requests_page.dart';
```

### 4. Add Verification Guards to discovery_page.dart

At the beginning of the build method:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final userProfile = ref.watch(userProfileProvider);

  return userProfile.when(
    loading: () => const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    ),
    error: (error, stack) => Scaffold(
      body: Center(child: Text('Error: $error')),
    ),
    data: (profile) {
      if (profile == null || !profile.isVerified) {
        return _buildUnverifiedOverlay(profile);
      }

      return _buildDiscoveryPage(); // Your existing page
    },
  );
}

Widget _buildUnverifiedOverlay(UserProfile? profile) {
  return Scaffold(
    body: VerificationGuard.buildVerificationOverlay(
      child: _buildDiscoveryPage(),
      isVerified: profile?.isVerified ?? false,
      featureName: 'das Entdecken von Profilen',
    ),
  );
}
```

### 5. Add Verification Guards to chat_detail_page.dart

Wrap the message input area:

```dart
if (!isVerified) {
  Padding(
    padding: const EdgeInsets.all(16),
    child: ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, '/security'),
      child: const Text('Verifizieren um zu schreiben'),
    ),
  )
} else {
  // Your existing message input UI
  _buildMessageInput()
}
```

### 6. Add Verification Guards to likes_page.dart

Show profile cards with reduced opacity if unverified:

```dart
Opacity(
  opacity: isVerified ? 1.0 : 0.5,
  child: ProfileCard(...),
)
```

### 7. Update main.dart (ALREADY DONE)

Firebase initialization is already added. Ensure the main function looks like:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // ... rest of initialization
}
```

## Firestore Collections Structure

The system automatically creates these collections:

```
users/
├── {userId}
│   ├── id, email, name, isVerified, verificationMethod, verificationDate
│   ├── university, major, semester, ... (profile fields)
│   └── verificationRequests/ (subcollection)
│       └── {requestId}
│           ├── userId, imageUrl, status, submittedAt
│           ├── reviewedAt, rejectionReason, reviewedBy

verificationAuditLog/
└── {logId}
    ├── userId, action, method, details, approvedBy, timestamp

verificationRequests/ (global index - optional)
└── (mirrors subcollections for easier queries)
```

## Security Rules Deployment

Deploy the Firestore and Storage rules:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Deploy rules
firebase deploy --only firestore:rules,storage
```

## Testing with Firebase Emulator

```bash
# Install Firebase Emulator Suite
firebase emulators:start

# In your app, connect to emulator:
# FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
# await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
```

## Usage Examples

### Check if user is verified
```dart
final isVerified = profile?.isVerified ?? false;
```

### Get verification status
```dart
final status = ref.watch(currentUserVerificationProvider);
```

### Upload Student ID
```dart
final uploadNotifier = ref.read(verificationUploadProvider.notifier);
await uploadNotifier.uploadStudentId(
  userId: userId,
  imagePath: imagePath,
);
```

### Show verification badge
```dart
VerificationBadge(
  isVerified: profile?.isVerified ?? false,
  verificationMethod: profile?.verificationMethod,
)
```

### Get pending requests (admin)
```dart
final pending = ref.watch(pendingVerificationRequestsProvider);
```

## Email Verification

Users with these email domains are **auto-verified** on signup:
- All `.tum.de` (Technical University Munich)
- All `.kit.edu` (Karlsruhe Institute of Technology)
- All `.rwth-aachen.de`, `.tu-berlin.de`, etc. (30+ German universities)

See `FirebaseConfig.germanUniversityDomains` for complete list.

## Common Patterns

### Protect a feature behind verification
```dart
if (!isVerified) {
  VerificationGuard.showVerificationPrompt(
    context: context,
    title: 'Verifizierung erforderlich',
    message: 'Bitte verifiziere deinen Account um diese Funktion zu nutzen.',
    onAction: () => Navigator.pushNamed(context, '/security'),
  );
  return;
}
// Continue with feature logic
```

### Display verification status
```dart
Text(VerificationGuard.getVerificationStatusText(profile))
```

### Refresh verification status
```dart
ref.refresh(currentUserVerificationProvider)
```

## Next Steps

1. Configure Firebase project credentials (google-services.json, GoogleService-Info.plist)
2. Deploy Firestore & Storage rules
3. Update pages according to integration guide above
4. Test with Firebase Emulator Suite
5. Deploy to Firebase Hosting when ready
