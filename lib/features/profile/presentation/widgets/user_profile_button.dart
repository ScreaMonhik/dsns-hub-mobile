import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';

class UserProfileButton extends ConsumerWidget {
  const UserProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () => context.push('/profile'),
        child: profileState.when(
          data: (profile) => CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: profile != null && profile.avatarUrl != null
                ? ClipOval(
                    child: AuthNetworkImage(
                      imageUrl: profile.avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    profile?.firstName[0].toUpperCase() ?? '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
          loading: () => const SizedBox(
            width: 36,
            height: 36,
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          error: (_, __) => CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            child: Icon(Icons.error_outline, size: 20, color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}