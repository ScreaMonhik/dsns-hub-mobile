import 'package:dio/dio.dart';
import 'package:dsns_hub/core/config/maintenance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses public settings status', () {
    final status = maintenanceStatusFromJson({
      'maintenanceMode': true,
      'maintenanceMessage': 'Оновлення серверів',
    });

    expect(status.enabled, isTrue);
    expect(status.message, 'Оновлення серверів');
  });

  test('falls back to the default maintenance message', () {
    final status = maintenanceStatusFromJson({'maintenanceMode': true, 'maintenanceMessage': '  '});
    expect(status.message, defaultMaintenanceMessage);
  });

  test('detects MAINTENANCE API responses', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/news'),
      response: Response(
        requestOptions: RequestOptions(path: '/news'),
        statusCode: 503,
        data: {
          'code': 'MAINTENANCE',
          'message': 'Сервіс на паузі',
        },
      ),
    );

    expect(isMaintenanceResponse(error), isTrue);
    expect(maintenanceMessageFromError(error), 'Сервіс на паузі');
  });
}
