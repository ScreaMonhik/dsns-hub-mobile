import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/emergency_alert.dart';
import '../data/repositories/alerts_repository.dart';

class AlertsInboxNotifier extends AsyncNotifier<List<EmergencyAlert>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetching = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<EmergencyAlert>> build() async {
    final token = ref.watch(currentTokenProvider);
    if (token == null || token.isEmpty) return [];

    _currentPage = 1;
    return _fetchPage(1);
  }

  Future<List<EmergencyAlert>> _fetchPage(int page) async {
    final response = await ref.read(alertsRepositoryProvider).getInbox(page: page);
    _hasMore = response.page < response.lastPage;
    return response.data;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetching) return;

    _isFetching = true;
    _currentPage++;

    try {
      final next = await _fetchPage(_currentPage);
      state = AsyncValue.data([...?state.value, ...next]);
    } catch (_) {
      _currentPage--;
    } finally {
      _isFetching = false;
    }
  }
}

final alertsInboxProvider =
    AsyncNotifierProvider<AlertsInboxNotifier, List<EmergencyAlert>>(AlertsInboxNotifier.new);

final alertDetailProvider = FutureProvider.autoDispose.family<EmergencyAlert, String>((ref, id) {
  return ref.watch(alertsRepositoryProvider).getInboxOne(id);
});
