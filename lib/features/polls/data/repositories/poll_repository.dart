import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart'; // Переконайтеся, що шлях до вашого dioProvider правильний
import '../models/poll_model.dart';

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  // Відстежуємо налаштований екземпляр Dio з авторизаційними інтерцепторами
  final dio = ref.watch(dioProvider); 
  return PollRepository(dio);
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