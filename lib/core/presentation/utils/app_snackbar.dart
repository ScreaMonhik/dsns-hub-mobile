import 'package:flutter/material.dart';

class AppSnackBar {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isError: false, icon: Icons.check_circle_outline, color: Colors.green.shade700);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true, icon: Icons.error_outline, color: Theme.of(context).colorScheme.error);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, isError: false, icon: Icons.warning_amber_rounded, color: Colors.orange.shade700);
  }

  static void _show(
    BuildContext context, 
    String message, {
    required bool isError,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          elevation: 6,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}