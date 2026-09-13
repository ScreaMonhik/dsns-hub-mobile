import 'package:dsns_hub/core/utils/isolate_json.dart';
import 'package:dsns_hub/features/news/data/models/news_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses paginated news JSON off the UI isolate', () async {
    final parsed = await parseJsonMapInIsolate(
      {
        'data': [
          {
            'id': 'n1',
            'title': 'Тренування',
            'status': 'PUBLISHED',
          },
        ],
        'meta': {'total': 1, 'page': 1, 'lastPage': 1, 'limit': 10},
      },
      NewsPaginatedResponse.fromJson,
    );

    expect(parsed.data, hasLength(1));
    expect(parsed.data.first.id, 'n1');
    expect(parsed.meta?.lastPage, 1);
  });
}
