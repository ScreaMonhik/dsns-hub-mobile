import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TipTapHelper {
  /// Витягує чистий текст з JSON TipTap для прев'ю на картках
  static String extractPlainText(String payload) {
    try {
      final doc = jsonDecode(payload);
      if (doc is Map<String, dynamic> && doc['type'] == 'doc') {
        return _extractText(doc['content'] as List?);
      }
      return payload;
    } catch (e) {
      // Якщо це не JSON (наприклад, звичайний текст), прибираємо HTML теги про всяк випадок
      return payload.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    }
  }

  static String _extractText(List? nodes) {
    if (nodes == null) return '';
    final buffer = StringBuffer();
    for (final node in nodes) {
      if (node['type'] == 'text') {
        buffer.write(node['text']);
      } else if (node['content'] != null) {
        buffer.write(_extractText(node['content']));
      }
      if (node['type'] == 'paragraph' || node['type'] == 'listItem') {
        buffer.write(' ');
      }
    }
    return buffer.toString().trim();
  }
}

class TipTapRenderer extends StatelessWidget {
  final String jsonContent;
  final String baseUrl;

  const TipTapRenderer({
    super.key,
    required this.jsonContent,
    this.baseUrl = 'http://10.0.2.2:3000', // Змініть на свій baseUrl
  });

  @override
  Widget build(BuildContext context) {
    try {
      final doc = jsonDecode(jsonContent);
      if (doc is! Map<String, dynamic> || doc['type'] != 'doc') {
        return Text(jsonContent); // Fallback
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildNodes(doc['content'] as List?, context),
      );
    } catch (e) {
      return Text(jsonContent); // Fallback якщо формат некоректний
    }
  }

  List<Widget> _buildNodes(List? nodes, BuildContext context) {
    if (nodes == null) return [];
    return nodes.map((node) => _buildNode(node, context)).toList();
  }

  Widget _buildNode(Map<String, dynamic> node, BuildContext context) {
    final type = node['type'];
    final attrs = node['attrs'] as Map<String, dynamic>?;
    final content = node['content'] as List?;

    switch (type) {
      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: RichText(
            textAlign: _getTextAlign(attrs?['textAlign']),
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
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
              left: BorderSide(
                color: Theme.of(context).colorScheme.primary, 
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildNodes(content, context),
          ),
        );
        
      case 'orderedList':
        final start = attrs?['start'] ?? 1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(content?.length ?? 0, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${start + i}. ', 
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: _buildNode(content![i], context)),
                  ],
                ),
              );
            }),
          ),
        );
        
      case 'listItem':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildNodes(content, context),
        );
        
      case 'image':
        final src = attrs?['src'] as String?;
        if (src == null) return const SizedBox();
        // Додаємо baseUrl якщо посилання відносне
        final imageUrl = src.startsWith('http') ? src : '$baseUrl$src';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl, 
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
        
      case 'youtube':
        final src = attrs?['src'] as String?;
        if (src == null) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(src), mode: LaunchMode.externalApplication),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill, color: Theme.of(context).colorScheme.error, size: 36),
                  const SizedBox(width: 12),
                  Text(
                    'Дивитись відео на YouTube', 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        
      default:
        return const SizedBox();
    }
  }

  List<TextSpan> _buildTextSpans(List? nodes, BuildContext context) {
    if (nodes == null) return [];
    List<TextSpan> spans = [];
    
    for (final node in nodes) {
      if (node['type'] == 'text') {
        final text = node['text'] as String? ?? '';
        final marks = node['marks'] as List?;
        
        FontWeight weight = FontWeight.normal;
        Color? color;
        TextDecoration? decoration;
        TapGestureRecognizer? recognizer;

        if (marks != null) {
          for (final mark in marks) {
            if (mark['type'] == 'bold') {
              weight = FontWeight.bold;
            } else if (mark['type'] == 'link') {
              color = Theme.of(context).colorScheme.primary;
              decoration = TextDecoration.underline;
              final href = mark['attrs']?['href'];
              if (href != null) {
                recognizer = TapGestureRecognizer()
                  ..onTap = () => launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
              }
            }
          }
        }

        spans.add(TextSpan(
          text: text,
          style: TextStyle(fontWeight: weight, color: color, decoration: decoration),
          recognizer: recognizer,
        ));
      }
    }
    return spans;
  }

  TextAlign _getTextAlign(String? align) {
    switch (align) {
      case 'center': return TextAlign.center;
      case 'right': return TextAlign.right;
      case 'justify': return TextAlign.justify;
      default: return TextAlign.left;
    }
  }
}