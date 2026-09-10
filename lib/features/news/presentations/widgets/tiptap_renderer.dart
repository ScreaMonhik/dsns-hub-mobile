import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';
import '../../../../core/utils/safe_url.dart';
import 'tiptap_video_player.dart';

class TipTapHelper {
  static final Map<String, String> _plainTextCache = <String, String>{};
  static const int _maxCacheEntries = 80;

  /// Витягує чистий текст з JSON TipTap для прев'ю на картках
  static String extractPlainText(String payload) {
    final cached = _plainTextCache[payload];
    if (cached != null) return cached;

    String result;
    try {
      final doc = jsonDecode(payload);
      if (doc is Map && doc['type'] == 'doc') {
        result = extractTextFromNodes(doc['content'] as List?);
      } else {
        result = payload;
      }
    } catch (e) {
      result = payload.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    }

    if (_plainTextCache.length >= _maxCacheEntries) {
      _plainTextCache.remove(_plainTextCache.keys.first);
    }
    _plainTextCache[payload] = result;
    return result;
  }

  @visibleForTesting
  static void clearCache() => _plainTextCache.clear();

  static String extractTextFromNodes(List? nodes) {
    if (nodes == null) return '';
    final buffer = StringBuffer();
    for (final node in nodes) {
      final map = _asMap(node);
      if (map == null) continue;
      if (map['type'] == 'text') {
        buffer.write(map['text'] ?? '');
      } else if (map['type'] == 'hardBreak') {
        buffer.write(' ');
      } else if (map['content'] != null) {
        buffer.write(extractTextFromNodes(map['content'] as List?));
      }
      final type = map['type'];
      if (type == 'paragraph' || type == 'listItem' || type == 'heading') {
        buffer.write(' ');
      }
    }
    return buffer.toString().trim();
  }
}

Map<String, dynamic>? _asMap(dynamic node) {
  if (node is Map<String, dynamic>) return node;
  if (node is Map) return Map<String, dynamic>.from(node);
  return null;
}

class TipTapRenderer extends StatefulWidget {
  final String jsonContent;
  final String baseUrl;

  const TipTapRenderer({
    super.key,
    required this.jsonContent,
    this.baseUrl = AppConfig.apiBaseUrl,
  });

  @override
  State<TipTapRenderer> createState() => _TipTapRendererState();
}

class _TipTapRendererState extends State<TipTapRenderer> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(TipTapRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonContent != widget.jsonContent) {
      _disposeRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    try {
      final doc = jsonDecode(widget.jsonContent);
      if (doc is! Map || doc['type'] != 'doc') {
        return Text(widget.jsonContent);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildNodes(doc['content'] as List?, context),
      );
    } catch (e) {
      return Text(widget.jsonContent);
    }
  }

  List<Widget> _buildNodes(List? nodes, BuildContext context) {
    if (nodes == null) return const [];
    final widgets = <Widget>[];
    for (final node in nodes) {
      final map = _asMap(node);
      if (map != null) widgets.add(_buildNode(map, context));
    }
    return widgets;
  }

  Widget _buildNode(Map<String, dynamic> node, BuildContext context) {
    final type = node['type'];
    final attrs = _asMap(node['attrs']);
    final content = node['content'] as List?;
    final theme = Theme.of(context);

    switch (type) {
      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: RichText(
            textAlign: _getTextAlign(attrs?['textAlign']),
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              children: _buildTextSpans(content, context),
            ),
          ),
        );

      case 'heading':
        final level = attrs?['level'] is int ? attrs!['level'] as int : 2;
        final style =
            (level <= 2
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.3);
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: RichText(
            textAlign: _getTextAlign(attrs?['textAlign']),
            text: TextSpan(
              style: style,
              children: _buildTextSpans(content, context),
            ),
          ),
        );

      case 'blockquote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          padding: const EdgeInsets.only(left: 16.0, top: 4, bottom: 4),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildNodes(content, context),
          ),
        );

      case 'bulletList':
        return _buildList(context, content, numbered: false, start: 1);

      case 'orderedList':
        final start = attrs?['start'] is int ? attrs!['start'] as int : 1;
        return _buildList(context, content, numbered: true, start: start);

      case 'listItem':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildNodes(content, context),
        );

      case 'image':
        final src = attrs?['src'] as String?;
        if (src == null || src.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AuthNetworkImage(
              imageUrl: src,
              baseUrl: widget.baseUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );

      case 'video':
        final src = attrs?['src'] as String?;
        if (src == null || src.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TipTapVideoPlayer(src: src, baseUrl: widget.baseUrl),
          ),
        );

      case 'youtube':
        final src = attrs?['src'] as String?;
        if (src == null || !isSafeYoutubeUrl(src)) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: InkWell(
            onTap: () => launchSafeYoutubeUrl(src),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: theme.colorScheme.error,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Дивитись відео на YouTube',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'horizontalRule':
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        );

      case 'codeBlock':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            TipTapHelper.extractTextFromNodes(content),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        );

      default:
        if (content != null && content.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildNodes(content, context),
          );
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildList(
    BuildContext context,
    List? content, {
    required bool numbered,
    required int start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(content?.length ?? 0, (i) {
          final item = _asMap(content![i]);
          if (item == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numbered ? '${start + i}. ' : '•  ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: numbered ? FontWeight.bold : FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                Expanded(child: _buildNode(item, context)),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(List? nodes, BuildContext context) {
    if (nodes == null) return const [];
    final spans = <InlineSpan>[];
    final linkColor = Theme.of(context).colorScheme.primary;

    for (final node in nodes) {
      final map = _asMap(node);
      if (map == null) continue;

      if (map['type'] == 'hardBreak') {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      if (map['type'] != 'text') continue;

      final text = map['text'] as String? ?? '';
      final marks = map['marks'] as List?;

      FontWeight? weight;
      FontStyle? fontStyle;
      Color? color;
      TextDecoration? decoration;
      String? fontFamily;
      TapGestureRecognizer? recognizer;
      final decorations = <TextDecoration>[];

      if (marks != null) {
        for (final mark in marks) {
          final markMap = _asMap(mark);
          if (markMap == null) continue;
          switch (markMap['type']) {
            case 'bold':
              weight = FontWeight.bold;
            case 'italic':
              fontStyle = FontStyle.italic;
            case 'underline':
              decorations.add(TextDecoration.underline);
            case 'strike':
              decorations.add(TextDecoration.lineThrough);
            case 'code':
              fontFamily = 'monospace';
            case 'link':
              color = linkColor;
              decorations.add(TextDecoration.underline);
              final href = markMap['attrs'] is Map
                  ? markMap['attrs']['href']
                  : null;
              if (href != null) {
                recognizer = TapGestureRecognizer()
                  ..onTap = () => launchSafeUrl(href.toString());
                _recognizers.add(recognizer);
              }
          }
        }
      }

      if (decorations.isNotEmpty) {
        decoration = decorations.length == 1
            ? decorations.first
            : TextDecoration.combine(decorations);
      }

      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: weight,
            fontStyle: fontStyle,
            color: color,
            decoration: decoration,
            fontFamily: fontFamily,
          ),
          recognizer: recognizer,
        ),
      );
    }
    return spans;
  }

  TextAlign _getTextAlign(dynamic align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }
}
