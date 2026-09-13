import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/isolate_json.dart';
import '../models/poll_model.dart';

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  final dio = ref.watch(dioProvider); 
  return PollRepository(dio);
});

class PollRepository {
  final Dio _dio;

  PollRepository(this._dio);

  Future<List<Poll>> getPolls({String? status}) async {
    final queryParameters = status != null ? {'status': status} : null;
    final response = await _dio.get('/polls', queryParameters: queryParameters);
    return parseJsonListInIsolate(response.data['data'], Poll.fromJson);
  }

  Future<Poll> getPoll(String id) async {
    final response = await _dio.get('/polls/$id');
    return parseJsonMapInIsolate(response.data, Poll.fromJson);
  }

  Future<Poll> vote(String pollId, String optionId) async {
    final response = await _dio.post(
      '/polls/$pollId/vote',
      data: {'optionId': optionId},
    );
    return Poll.fromJson(response.data as Map<String, dynamic>);
  }
}