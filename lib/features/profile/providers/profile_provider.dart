import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/profile_repository.dart';
import '../../auth/data/models/auth_model.dart';
import '../../auth/providers/auth_provider.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final token = ref.watch(currentTokenProvider);
    if (token == null || token.isEmpty) return null;

    return ref.watch(profileRepositoryProvider).getMe();
  }

  Future<void> uploadAvatar(String filePath) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      final newAvatarUrl = await ref.read(profileRepositoryProvider).uploadAvatar(filePath);
      if (previousState.hasValue && previousState.value != null) {
        state = AsyncValue.data(previousState.value!.copyWith(avatarUrl: newAvatarUrl));
      } else {
        ref.invalidateSelf();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (previousState.hasValue) {
        state = previousState;
      }
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await ref.read(profileRepositoryProvider).changePassword(oldPassword, newPassword);
  }

  Future<void> updateNotificationPrefs(NotificationPreferences prefs) async {
    final current = state.value;
    if (current == null) return;

    final previous = state;
    state = AsyncValue.data(
      current.copyWith(
        notifyNews: prefs.notifyNews ?? current.notifyNews,
        notifyPolls: prefs.notifyPolls ?? current.notifyPolls,
        notifyPollDeadlines: prefs.notifyPollDeadlines ?? current.notifyPollDeadlines,
        notifyDocuments: prefs.notifyDocuments ?? current.notifyDocuments,
        notifyProjects: prefs.notifyProjects ?? current.notifyProjects,
        notifyChats: prefs.notifyChats ?? current.notifyChats,
      ),
    );

    try {
      final updated = await ref.read(profileRepositoryProvider).updatePreferences(prefs);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = previous.hasValue ? previous : AsyncValue.error(e, st);
      rethrow;
    }
  }
}
