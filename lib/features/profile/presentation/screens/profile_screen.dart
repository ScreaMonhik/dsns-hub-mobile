import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';
import '../../../../core/providers/app_info_provider.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await ref.read(profileProvider.notifier).uploadAvatar(image.path);
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Фото профілю успішно оновлено');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Помилка завантаження фото: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    }
  }

  Future<void> _copyEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      AppSnackBar.showSuccess(context, 'Email скопійовано');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Особистий кабінет'),
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Дані відсутні'));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _ProfileHeader(
                profile: profile,
                isUploading: profileState.isRefreshing,
                onChangePhoto: profileState.isLoading ? null : _pickAndUploadImage,
              ),
              const SizedBox(height: 24),
              _AccountPanel(
                email: profile.email,
                onCopyEmail: () => _copyEmail(profile.email),
              ),
              const SizedBox(height: 20),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.campaign_outlined,
                    title: 'Історія тривог',
                    subtitle: 'Критичні сповіщення ДСНС',
                    onTap: () => context.push('/profile/alerts'),
                  ),
                  _SettingsTile(
                    icon: Icons.settings_outlined,
                    title: 'Налаштування',
                    subtitle: 'Тема, сповіщення, кеш і безпека',
                    onTap: () => context.push('/profile/settings'),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authStateProvider.notifier).logout(),
                  icon: Icon(Icons.logout, color: theme.colorScheme.error),
                  label: Text(
                    'Вийти з акаунта',
                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ref.watch(appInfoProvider).when(
                data: (info) => Column(
                  children: [
                    Text(
                      'DSNS Hub v${info.version} (${info.buildNumber})',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kReleaseMode ? 'Production' : 'Debug',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Помилка завантаження профілю: $err')),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isUploading,
    required this.onChangePhoto,
  });

  final UserProfile profile;
  final bool isUploading;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departmentName = profile.department?.name;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: profile.avatarUrl != null
                  ? ClipOval(
                      child: AuthNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      profile.firstName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
            ),
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onChangePhoto,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        if (isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        const SizedBox(height: 16),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (departmentName != null && departmentName.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              departmentName,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.email,
    required this.onCopyEmail,
  });

  final String email;
  final VoidCallback onCopyEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        leading: Icon(Icons.mail_outline, color: theme.colorScheme.primary),
        title: Text(
          email,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Робоча адреса'),
        trailing: IconButton(
          tooltip: 'Скопіювати',
          onPressed: onCopyEmail,
          icon: const Icon(Icons.copy_outlined),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ],
    );
  }
}
