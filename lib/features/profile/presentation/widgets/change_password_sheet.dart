import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/widgets/secure_password_field.dart';
import '../../../../core/security/password_rules.dart';
import '../../providers/profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';

void showChangePasswordSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const ChangePasswordSheet(),
  );
}

class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      AppSnackBar.showError(context, 'Усі поля є обов\'язковими');
      return;
    }

    if (!PasswordRules.isValid(newPassword)) {
      AppSnackBar.showError(context, PasswordRules.message);
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      await ref.read(profileProvider.notifier).changePassword(oldPassword, newPassword);
      await ref.read(authStateProvider.notifier).setForcePasswordChange(false);
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(context, 'Пароль успішно змінено');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Зміна пароля',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SecurePasswordField(
            controller: _oldPasswordController,
            enabled: !_isSubmitting,
            obscureText: _obscureOld,
            onToggleObscure: () => setState(() => _obscureOld = !_obscureOld),
            label: 'Поточний пароль',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          SecurePasswordField(
            controller: _newPasswordController,
            enabled: !_isSubmitting,
            obscureText: _obscureNew,
            onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
            label: 'Новий пароль',
            prefixIcon: Icons.lock_reset,
          ),
          const SizedBox(height: 8),
          Text(
            'Пароль має містити щонайменше 8 символів, 1 велику та малу літеру, 1 цифру та спецсимвол.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('ЗБЕРЕГТИ ПАРОЛЬ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
