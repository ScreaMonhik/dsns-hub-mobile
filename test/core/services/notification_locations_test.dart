import 'package:dsns_hub/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps push payloads to app routes', () {
    expect(
      NotificationService.locationForData({'type': 'NEWS', 'newsId': 'n1'}),
      '/news/n1',
    );
    expect(
      NotificationService.locationForData({'type': 'POLL', 'pollId': 'p1'}),
      '/polls/p1',
    );
    expect(
      NotificationService.locationForData({'type': 'DOCUMENT', 'documentId': 'd1'}),
      '/documents',
    );
    expect(
      NotificationService.locationForData({'type': 'PROJECT', 'projectId': 'pr1'}),
      '/projects/pr1',
    );
    expect(
      NotificationService.locationForData({'type': 'CHAT', 'groupId': 'c1'}),
      '/chats/c1',
    );
  });
}
