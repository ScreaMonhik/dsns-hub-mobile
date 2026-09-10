import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../config/app_config.dart';

class AuthNetworkImage extends ConsumerWidget {
  final String imageUrl;
  final String? baseUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AuthNetworkImage({
    super.key,
    required this.imageUrl,
    this.baseUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  String? get _fullUrl {
    final normalizedUrl = imageUrl.replaceAll('\\', '/').trim();
    if (normalizedUrl.isEmpty) return null;

    if (normalizedUrl.startsWith('http://') || normalizedUrl.startsWith('https://')) {
      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return null;
      }
      return normalizedUrl;
    }

    final origin = baseUrl ?? AppConfig.apiBaseUrl;
    final formattedPath = normalizedUrl.startsWith('/') ? normalizedUrl : '/$normalizedUrl';
    return '$origin$formattedPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = _fullUrl;
    if (resolvedUrl == null) {
      return errorBuilder?.call(context, 'Invalid image URL', StackTrace.current) ??
          _fallback(context);
    }

    final token = ref.watch(currentTokenProvider);
    final headers = <String, String>{};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logicalWidth = (width != null && width!.isFinite && width! > 0) ? width! : screenWidth;
    final cacheWidth = (logicalWidth * dpr).round().clamp(1, 4096);

    return Image.network(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      headers: headers,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
    );
  }
}
