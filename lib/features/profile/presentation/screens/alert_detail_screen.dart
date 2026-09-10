import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/alerts_provider.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';

class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(alertDetailProvider(alertId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тривога'),
      ),
      body: alertState.when(
        data: (alert) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(_severityLabel(alert.severity)),
                  backgroundColor: _chipColor(theme, alert.severity),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                alert.title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('d MMMM yyyy, HH:mm', 'uk').format(alert.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                alert.body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => CommonErrorWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(alertDetailProvider(alertId)),
        ),
      ),
    );
  }
}

Color _chipColor(ThemeData theme, String severity) {
  switch (severity) {
    case 'CRITICAL':
      return theme.colorScheme.errorContainer;
    case 'WARNING':
      return const Color(0xFFFEF3C7);
    default:
      return theme.colorScheme.primaryContainer;
  }
}

String _severityLabel(String severity) {
  switch (severity) {
    case 'CRITICAL':
      return 'Критичний';
    case 'WARNING':
      return 'Увага';
    default:
      return 'Інформація';
  }
}
