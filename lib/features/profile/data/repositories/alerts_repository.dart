import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/emergency_alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref.watch(dioProvider));
});

class AlertsRepository {
  AlertsRepository(this._dio);

  final Dio _dio;

  Future<EmergencyAlertsPage> getInbox({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      '/emergency-broadcasts/inbox',
      queryParameters: {'page': page, 'limit': limit},
    );
    return EmergencyAlertsPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmergencyAlert> getInboxOne(String id) async {
    final response = await _dio.get('/emergency-broadcasts/inbox/$id');
    return EmergencyAlert.fromJson(response.data as Map<String, dynamic>);
  }
}
