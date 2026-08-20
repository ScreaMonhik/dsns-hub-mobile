import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/poll_provider.dart';
import '../../data/models/poll_model.dart';

class PollDetailScreen extends ConsumerStatefulWidget {
  final String pollId;
  const PollDetailScreen({super.key, required this.pollId});

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  String? _pendingOptionId;
  bool _isEditing = false;
  bool _isSubmitting = false;

  Future<void> _submitVote(Poll poll) async {
    if (_pendingOptionId == null || poll.status != 'PUBLISHED') return;

    // Запобігання повторній відправці того самого варіанту (уникнення анулювання/зайвих запитів)
    if (_pendingOptionId == poll.userVotedOptionId) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Голос залишено без змін'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    try {
      await ref.read(pollsProvider.notifier).vote(poll.id, _pendingOptionId!);
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ваш голос враховано!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка обробки голосу: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = ref.watch(pollDetailProvider(widget.pollId));

    if (poll == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Опитування не знайдено')),
      );
    }

    // Додана локальна перевірка на протермінованість
    final isLocallyExpired = poll.expiresAt != null && poll.expiresAt!.isBefore(DateTime.now());
    final isClosed = poll.status != 'PUBLISHED' || isLocallyExpired;
    
    final hasVoted = poll.userVotedOptionId != null;
    final isVotingActive = !isClosed && (!hasVoted || _isEditing);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Голосування', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isClosed ? Icons.lock_outline : Icons.how_to_vote,
                      color: isClosed ? Colors.grey : Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isClosed ? 'Завершено' : 'Активне опитування',
                      style: TextStyle(
                        color: isClosed ? Colors.grey : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Бейдж з таймером
                if (!isClosed && poll.expiresAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: Theme.of(context).colorScheme.onTertiaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          'До ${DateFormat('dd.MM.yyyy HH:mm').format(poll.expiresAt!.toLocal())}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              poll.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
            ),
            if (poll.description != null) ...[
              const SizedBox(height: 12),
              Text(
                poll.description!,
                style: TextStyle(fontSize: 16, height: 1.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              isClosed ? 'Результати опитування:' : 'Оберіть варіант:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...poll.options.map((option) {
              final maxVotes = poll.options.isEmpty ? 0 : poll.options.map((o) => o.votes).reduce((a, b) => a > b ? a : b);
              return _buildOptionCard(poll, option, isVotingActive, isClosed, maxVotes);
            }),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Всього голосів: ${poll.totalVotes}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (!isClosed) ...[
              const SizedBox(height: 24),
              _buildBottomActions(poll, hasVoted, isVotingActive),
            ],
            SizedBox(height: 100 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(Poll poll, bool hasVoted, bool isVotingActive) {
    return isVotingActive
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() {
                                _isEditing = false;
                                _pendingOptionId = null;
                              }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Скасувати', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: (_pendingOptionId == null || _isSubmitting)
                        ? null
                        : () => _submitVote(poll),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Проголосувати', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        : SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _isEditing = true;
                _pendingOptionId = poll.userVotedOptionId;
              }),
              icon: const Icon(Icons.edit),
              label: const Text('Змінити голос', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
  }

  Widget _buildOptionCard(Poll poll, PollOption option, bool isVotingActive, bool isClosed, int maxVotes) {
    final theme = Theme.of(context);
    final isSelected = isVotingActive 
        ? _pendingOptionId == option.id 
        : poll.userVotedOptionId == option.id;
        
    final bool showResults = !isVotingActive || poll.userVotedOptionId != null || isClosed;
    final double percentage = poll.totalVotes > 0 ? (option.votes / poll.totalVotes) : 0.0;
    final double displayPercentage = showResults ? percentage : 0.0;
    final String percentageText = '${(percentage * 100).toStringAsFixed(1)}%';
    
    final isWinner = isClosed && option.votes == maxVotes && maxVotes > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isWinner)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          else if (isSelected)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner 
              ? Colors.green.shade500 
              : (isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
          width: (isWinner || isSelected) ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isVotingActive 
              ? () => setState(() => _pendingOptionId = option.id) 
              : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: displayPercentage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    color: isWinner 
                        ? Colors.green.withValues(alpha: 0.1) 
                        : (isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                child: Row(
                  children: [
                    if (!isClosed) ...[
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: (isWinner || isSelected) ? FontWeight.w700 : FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (showResults) 
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isWinner) ...[
                            Icon(Icons.emoji_events, color: Colors.green.shade600, size: 24),
                            const SizedBox(width: 10),
                          ] else if (isClosed && isSelected) ...[
                            Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                percentageText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isWinner 
                                      ? Colors.green.shade600 
                                      : (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                                ),
                              ),
                              Text(
                                '${option.votes} чол.',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}