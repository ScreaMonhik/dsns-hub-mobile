import 'package:dsns_hub/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes only provided notification flags', () {
    const prefs = NotificationPreferences(
      notifyPolls: false,
      notifyPollDeadlines: true,
    );

    expect(prefs.toJson(), {
      'notifyPolls': false,
      'notifyPollDeadlines': true,
    });
  });
}
