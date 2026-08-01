import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AuthNetworkImage extends ConsumerWidget {
  final String imageUrl;
  final String baseUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AuthNetworkImage({
    super.key,
    required this.imageUrl,
    this.baseUrl = 'http://10.0.2.2:3000',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  String get _fullUrl {
    // 1. Нормалізуємо бекенд-шляхи Windows (замінюємо \ на /)
    final normalizedUrl = imageUrl.replaceAll('\\', '/');
    
    // 2. Якщо бекенд повертає повний лінк
    if (normalizedUrl.startsWith('http')) {
      return normalizedUrl;
    }
    
    // 3. Формуємо правильний URL
    final formattedPath = normalizedUrl.startsWith('/') ? normalizedUrl : '/$normalizedUrl';
    return '$baseUrl$formattedPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(currentTokenProvider);
    final headers = <String, String>{};
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Image.network(
      _fullUrl,
      width: width,
      height: height,
      fit: fit,
      headers: headers,
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => Container(
                width: width,
                height: height,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              ),
    );
  }
}