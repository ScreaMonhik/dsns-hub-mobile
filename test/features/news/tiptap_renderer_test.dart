import 'dart:convert';

import 'package:dsns_hub/core/utils/media_url.dart';
import 'package:dsns_hub/core/utils/safe_url.dart';
import 'package:dsns_hub/features/news/data/models/news_models.dart';
import 'package:dsns_hub/features/news/presentations/widgets/tiptap_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(TipTapHelper.clearCache);

  group('NewsArticle.displayDate', () {
    test('prefers publishedAt like the admin preview', () {
      final article = NewsArticle.fromJson({
        'id': '1',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'publishedAt': '2026-02-01T12:00:00.000Z',
      });
      expect(article.displayDate, DateTime.parse('2026-02-01T12:00:00.000Z'));
    });

    test('falls back to createdAt when unpublished time is missing', () {
      final article = NewsArticle.fromJson({
        'id': '1',
        'createdAt': '2026-01-01T10:00:00.000Z',
      });
      expect(article.displayDate, DateTime.parse('2026-01-01T10:00:00.000Z'));
    });
  });

  group('TipTapHelper.extractPlainText', () {
    test('reads headings, lists, marks and hard breaks', () {
      final payload = jsonEncode({
        'type': 'doc',
        'content': [
          {
            'type': 'heading',
            'attrs': {'level': 2},
            'content': [
              {'type': 'text', 'text': 'Заголовок'},
            ],
          },
          {
            'type': 'paragraph',
            'content': [
              {
                'type': 'text',
                'text': 'Жирний',
                'marks': [
                  {'type': 'bold'},
                ],
              },
              {'type': 'hardBreak'},
              {
                'type': 'text',
                'text': 'курсив',
                'marks': [
                  {'type': 'italic'},
                ],
              },
            ],
          },
          {
            'type': 'bulletList',
            'content': [
              {
                'type': 'listItem',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Пункт'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      });

      expect(
        TipTapHelper.extractPlainText(payload),
        'Заголовок Жирний курсив Пункт',
      );
    });

    test('falls back to stripped HTML when payload is not TipTap JSON', () {
      expect(
        TipTapHelper.extractPlainText('<p>Привіт&nbsp;світе</p>'),
        isNot(contains('<')),
      );
    });
  });

  group('resolveMediaUrl', () {
    test('joins relative API paths', () {
      expect(
        resolveMediaUrl(
          '/news/media/file.mp4',
          baseUrl: 'https://api.example.gov.ua',
        ),
        'https://api.example.gov.ua/news/media/file.mp4',
      );
    });

    test('rejects non-http schemes', () {
      expect(resolveMediaUrl('javascript:alert(1)'), isNull);
      expect(resolveMediaUrl('data:text/html,hi'), isNull);
    });
  });

  group('YouTube URL helpers', () {
    test('accepts youtube hosts and rewrites embed links', () {
      expect(isSafeYoutubeUrl('https://www.youtube.com/watch?v=abc'), isTrue);
      expect(isSafeYoutubeUrl('https://youtu.be/abc'), isTrue);
      expect(isSafeYoutubeUrl('https://evil.example/watch?v=abc'), isFalse);
      expect(
        youtubeWatchUrl('https://www.youtube.com/embed/abc123'),
        'https://www.youtube.com/watch?v=abc123',
      );
      expect(
        youtubeVideoId('https://www.youtube.com/watch?v=dQw4w9wgxcq'),
        'dQw4w9wgxcq',
      );
      expect(youtubeVideoId('https://youtu.be/dQw4w9wgxcq'), 'dQw4w9wgxcq');
      expect(
        youtubeVideoId('https://www.youtube.com/embed/dQw4w9wgxcq'),
        'dQw4w9wgxcq',
      );
      expect(
        youtubeVideoId('https://www.youtube-nocookie.com/embed/dQw4w9wgxcq'),
        'dQw4w9wgxcq',
      );
      expect(
        youtubeVideoId('https://www.youtube.com/shorts/dQw4w9wgxcq'),
        'dQw4w9wgxcq',
      );
      expect(
        youtubeVideoId('https://evil.example/watch?v=dQw4w9wgxcq'),
        isNull,
      );
    });
  });

  testWidgets('renders heading, bullet list and italic from admin JSON', (
    tester,
  ) async {
    final payload = jsonEncode({
      'type': 'doc',
      'content': [
        {
          'type': 'heading',
          'attrs': {'level': 2},
          'content': [
            {'type': 'text', 'text': 'H2 з адмінки'},
          ],
        },
        {
          'type': 'bulletList',
          'content': [
            {
              'type': 'listItem',
              'content': [
                {
                  'type': 'paragraph',
                  'content': [
                    {
                      'type': 'text',
                      'text': 'елемент',
                      'marks': [
                        {'type': 'italic'},
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
        {
          'type': 'paragraph',
          'content': [
            {
              'type': 'text',
              'text': 'підкреслений',
              'marks': [
                {'type': 'underline'},
              ],
            },
          ],
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TipTapRenderer(jsonContent: payload)),
      ),
    );

    expect(find.text('H2 з адмінки', findRichText: true), findsOneWidget);
    expect(find.textContaining('елемент', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('підкреслений', findRichText: true),
      findsOneWidget,
    );
  });
}
