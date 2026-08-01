import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/secure_storage_provider.dart';

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
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    final formattedPath = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    return '$baseUrl$formattedPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(secureStorageProvider);

    return FutureBuilder<String?>(
      future: storage.read(key: 'jwt_token'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final token = snapshot.data;
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
      },
    );
  }
}