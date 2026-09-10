import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/alerts_provider.dart';
import '../../data/models/emergency_alert.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';

class AlertsInboxScreen extends ConsumerStatefulWidget {
  const AlertsInboxScreen({super.key});

  @override
  ConsumerState<AlertsInboxScreen> createState() => _AlertsInboxScreenState();
}

class _AlertsInboxScreenState extends ConsumerState<AlertsInboxScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(alertsInboxProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsInboxProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Історія тривог'),
      ),
      body: alertsState.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Text(
                'Тривог ще не було',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(alertsInboxProvider),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _AlertTile(alert: alert);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => CommonErrorWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(alertsInboxProvider),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final EmergencyAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _severityColors(theme, alert.severity);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/profile/alerts/${alert.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _severityLabel(alert.severity),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM yyyy, HH:mm', 'uk').format(alert.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                alert.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (alert.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  alert.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

({Color background, Color foreground}) _severityColors(ThemeData theme, String severity) {
  switch (severity) {
    case 'CRITICAL':
      return (
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      );
    case 'WARNING':
      return (
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFF92400E),
      );
    default:
      return (
        background: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.onPrimaryContainer,
      );
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
