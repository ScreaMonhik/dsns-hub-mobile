import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/poll_model.dart';
import '../../data/repositories/poll_repository.dart';
import '../../../auth/providers/auth_provider.dart';

final pollsProvider = StateNotifierProvider<PollsNotifier, AsyncValue<List<Poll>>>((ref) {
  final token = ref.watch(currentTokenProvider);
  final repository = ref.watch(pollRepositoryProvider);
  
  final notifier = PollsNotifier(repository);
  if (token != null && token.isNotEmpty) {
    notifier.fetchPolls();
  } else {
    notifier.clear();
  }
  return notifier;
});

class PollsNotifier extends StateNotifier<AsyncValue<List<Poll>>> {
  final PollRepository _repository;

  PollsNotifier(this._repository) : super(const AsyncValue.loading());

  void clear() {
    state = const AsyncValue.data([]);
  }

  Future<void> fetchPolls() async {
    try {
      state = const AsyncValue.loading();
      
      // Fetch both active (default) and archived polls concurrently
      final results = await Future.wait([
        _repository.getPolls(), // GET /polls?status=PUBLISHED (by default)
        _repository.getPolls(status: 'ARCHIVED'), // GET /polls?status=ARCHIVED
      ]);
      
      final activePolls = results[0];
      final archivedPolls = results[1];
      
      // Combine and remove any potential duplicates by ID
      final allPolls = [...activePolls, ...archivedPolls];
      final uniquePolls = {for (var p in allPolls) p.id: p}.values.toList();
      
      state = AsyncValue.data(uniquePolls);
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