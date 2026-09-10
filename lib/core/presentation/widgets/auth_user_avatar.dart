import 'package:flutter/material.dart';
import 'auth_network_image.dart';

class AuthUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double radius;

  const AuthUserAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = (fallbackText != null && fallbackText!.trim().isNotEmpty)
        ? fallbackText!.trim()[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: AuthNetworkImage(
                imageUrl: imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
              ),
            )
          : Text(
              letter,
              style: TextStyle(
                fontSize: radius,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }
}
