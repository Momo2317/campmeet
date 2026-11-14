import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/features/profile/data/firestore_user_profile_repository.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';
import 'package:camp_meet/features/verification/presentation/providers/verification_providers.dart';

/// Provider for Firestore User Profile Repository
final firestoreUserProfileRepositoryProvider =
    Provider<FirestoreUserProfileRepository>((ref) {
  return FirestoreUserProfileRepository();
});

/// Provider for current user's profile
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(firestoreUserProfileRepositoryProvider);
  return repository.getUserProfile(userId);
});

/// Provider for user profile stream (real-time)
final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(firestoreUserProfileRepositoryProvider);
  return repository.getUserProfileStream(userId);
});

/// Notifier for updating user profile
class UserProfileNotifier extends Notifier<AsyncValue<UserProfile?>> {
  String? _userId;

  FirestoreUserProfileRepository get _repository =>
      ref.read(firestoreUserProfileRepositoryProvider);

  @override
  AsyncValue<UserProfile?> build() {
    _userId = ref.watch(currentUserIdProvider);
    Future.microtask(_loadProfile);
    return const AsyncValue.loading();
  }

  Future<void> _loadProfile() async {
    final userId = _userId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final profile = await _repository.getUserProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      state = const AsyncValue.loading();
      await _repository.updateUserProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createProfile(UserProfile profile) async {
    try {
      state = const AsyncValue.loading();
      await _repository.createUserProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadProfile();
  }
}

/// Provider for user profile notifier
final userProfileNotifierProvider =
    NotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
  UserProfileNotifier.new,
);
