import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../utils/media_url.dart';

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

  String? get _fullUrl => resolveMediaUrl(imageUrl, baseUrl: baseUrl);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUrl = _fullUrl;
    if (resolvedUrl == null) {
      return errorBuilder?.call(
            context,
            'Invalid image URL',
            StackTrace.current,
          ) ??
          _fallback(context);
    }

    final token = ref.watch(currentTokenProvider);
    final headers = <String, String>{};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logicalWidth = (width != null && width!.isFinite && width! > 0)
        ? width!
        : screenWidth;
    final cacheWidth = (logicalWidth * dpr).round().clamp(1, 4096);

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      httpHeaders: headers,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      errorWidget: (context, url, error) {
        return errorBuilder?.call(context, error, StackTrace.current) ?? _fallback(context);
      },
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: Colors.grey,
      ),
    );
  }
}
