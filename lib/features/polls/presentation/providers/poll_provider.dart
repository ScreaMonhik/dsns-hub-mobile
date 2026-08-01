import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/poll_model.dart';
import '../../data/repositories/poll_repository.dart';

final pollsProvider = StateNotifierProvider<PollsNotifier, AsyncValue<List<Poll>>>((ref) {
  final repository = ref.watch(pollRepositoryProvider);
  return PollsNotifier(repository)..fetchPolls();
});

class PollsNotifier extends StateNotifier<AsyncValue<List<Poll>>> {
  final PollRepository _repository;

  PollsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> fetchPolls() async {
    try {
      state = const AsyncValue.loading();
      final polls = await _repository.getPolls();
      state = AsyncValue.data(polls);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> vote(String pollId, String optionId) async {
    if (state.value == null) return;
    final previousState = state.value!;

    try {
      final updatedPoll = await _repository.vote(pollId, optionId);
      
      // Reactively update the specific poll in the list
      state = AsyncValue.data(
        previousState.map((p) => p.id == pollId ? updatedPoll : p).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }
}

// Reactive provider for a specific poll detail to keep UI in sync automatically
final pollDetailProvider = Provider.family<Poll?, String>((ref, id) {
  final pollsState = ref.watch(pollsProvider);
  final polls = pollsState.value ?? [];
  for (final p in polls) {
    if (p.id == id) return p;
  }
  return null;
});