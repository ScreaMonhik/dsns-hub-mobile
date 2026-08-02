import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';
import '../../../../core/theme/theme_provider.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Фото профілю успішно оновлено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження фото: ${e.toString().replaceAll("Exception: ", "")}'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профіль'),
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Дані відсутні'));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: profile.avatarUrl != null
                            ? ClipOval(
                                child: AuthNetworkImage(
                                  imageUrl: profile.avatarUrl!,
                                  width: 128,
                                  height: 128,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                profile.firstName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            onTap: profileState.isLoading ? null : _pickAndUploadImage,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (profileState.isRefreshing)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 32),
                _buildInfoTile(context, Icons.person_outline, 'ПІБ', '${profile.lastName} ${profile.firstName}'),
                const SizedBox(height: 16),
                _buildInfoTile(context, Icons.email_outlined, 'Email', profile.email),
                const SizedBox(height: 16),
                _buildInfoTile(context, Icons.work_outline, 'Роль', profile.role),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Налаштування додатку', 
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Системна')),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Світла')),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Темна')),
                    ],
                    selected: {ref.watch(themeProvider)},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      ref.read(themeProvider.notifier).setTheme(newSelection.first);
                    },
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authStateProvider.notifier).logout(),
                    icon: Icon(Icons.logout, color: theme.colorScheme.error),
                    label: Text('Вийти з акаунта', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Помилка завантаження профілю: $err')),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}