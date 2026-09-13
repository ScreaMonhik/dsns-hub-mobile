import 'package:flutter/material.dart';

class SecurePasswordField extends StatelessWidget {
  const SecurePasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleObscure,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.prefixIcon = Icons.lock_outline,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final IconData prefixIcon;
  final Iterable<String> autofillHints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggleObscure,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
    );
  }
}
