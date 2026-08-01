import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poll_model.dart';

// TODO: Replace with the actual import path to your configured Dio provider
// import '../../../../core/providers/dio_provider.dart';

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  // final dio = ref.watch(dioProvider); 
  // Using a raw Dio instance as a placeholder until you connect your injected Dio.
  return PollRepository(Dio());
});

class PollRepository {
  final Dio _dio;

  PollRepository(this._dio);

  Future<List<Poll>> getPolls() async {
    final response = await _dio.get('/polls');
    final data = response.data['data'] as List;
    return data.map((json) => Poll.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Poll> getPoll(String id) async {
    final response = await _dio.get('/polls/$id');
    return Poll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Poll> vote(String pollId, String optionId) async {
    final response = await _dio.post(
      '/polls/$pollId/vote',
      data: {'optionId': optionId},
    );
    return Poll.fromJson(response.data as Map<String, dynamic>);
  }
}