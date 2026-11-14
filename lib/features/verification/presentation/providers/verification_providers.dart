import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camp_meet/core/services/firebase_auth_service.dart';
import 'package:camp_meet/features/verification/data/verification_service.dart';

// ============== Authentication Providers ==============

/// Provider for Firebase Auth state
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for Firebase Auth Service
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Provider for current user from Firebase
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider).maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
  return user?.uid;
});

// ============== Verification Providers ==============

/// Provider for Verification Service
final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService();
});

/// Provider for user verification status
final userVerificationStatusProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.getUserVerificationStatus(userId);
});

/// Provider for current user's verification status
final currentUserVerificationProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.getUserVerificationStatus(userId);
});

/// Provider for pending verification requests (admin)
final pendingVerificationRequestsProvider =
    FutureProvider<List<VerificationRequest>>((ref) async {
  final verificationService = ref.watch(verificationServiceProvider);
  return verificationService.getPendingRequests();
});

/// Provider for current user's latest verification request
final currentUserVerificationRequestProvider =
    FutureProvider<VerificationRequest?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final verificationService = ref.watch(verificationServiceProvider);
  return verificationService.getVerificationRequest(userId);
});

/// Provider for specific verification request (with user info)
final verificationRequestWithUserProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, requestId) async {
  final verificationService = ref.watch(verificationServiceProvider);
  return verificationService.getVerificationRequestWithUser(requestId);
});

// ============== Verification Actions ==============

/// Notifier for handling verification uploads
class VerificationUploadNotifier extends Notifier<AsyncValue<String?>> {
  VerificationService get _verificationService =>
      ref.read(verificationServiceProvider);

  @override
  AsyncValue<String?> build() => const AsyncValue.data(null);

  Future<void> uploadStudentId({
    required String userId,
    required String imagePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final requestId = await _verificationService.uploadStudentId(
        userId: userId,
        imagePath: imagePath,
      );
      state = AsyncValue.data(requestId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Provider for verification upload
final verificationUploadProvider =
    NotifierProvider<VerificationUploadNotifier, AsyncValue<String?>>(
  VerificationUploadNotifier.new,
);

// ============== Admin Actions ==============

/// Notifier for admin verification actions
class AdminVerificationNotifier extends Notifier<AsyncValue<void>> {
  VerificationService get _verificationService =>
      ref.read(verificationServiceProvider);

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> approveVerification({
    required String userId,
    required String requestId,
    required String approvedBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _verificationService.approveVerification(
        userId: userId,
        requestId: requestId,
        approvedBy: approvedBy,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> rejectVerification({
    required String userId,
    required String requestId,
    required String reason,
    required String rejectedBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _verificationService.rejectVerification(
        userId: userId,
        requestId: requestId,
        reason: reason,
        rejectedBy: rejectedBy,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Provider for admin verification actions
final adminVerificationProvider =
    NotifierProvider<AdminVerificationNotifier, AsyncValue<void>>(
  AdminVerificationNotifier.new,
);
