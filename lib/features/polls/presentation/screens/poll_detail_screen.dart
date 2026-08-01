import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/poll_provider.dart';
import '../../data/models/poll_model.dart';

class PollDetailScreen extends ConsumerStatefulWidget {
  final String pollId;
  const PollDetailScreen({super.key, required this.pollId});

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  String? _votingOptionId;

  Future<void> _handleVote(String optionId, Poll poll) async {
    if (poll.status != 'PUBLISHED') return;
    
    setState(() => _votingOptionId = optionId);
    try {
      await ref.read(pollsProvider.notifier).vote(poll.id, optionId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка обробки голосу: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _votingOptionId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watches the specific poll from the reactive provider
    final poll = ref.watch(pollDetailProvider(widget.pollId));

    if (poll == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Опитування не знайдено')),
      );
    }

    final isClosed = poll.status != 'PUBLISHED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Голосування', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 16),
            Text(
              poll.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
            ),
            if (poll.description != null) ...[
              const SizedBox(height: 12),
              Text(
                poll.description!,
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Оберіть варіант:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...poll.options.map((option) => _buildOptionCard(poll, option)),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Всього голосів: ${poll.totalVotes}',
                  style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(Poll poll, PollOption option) {
    final isVotedByMe = poll.userVotedOptionId == option.id;
    final isClosed = poll.status != 'PUBLISHED';
    final isVoting = _votingOptionId == option.id;
    
    final double percentage = poll.totalVotes > 0 ? (option.votes / poll.totalVotes) : 0.0;
    final String percentageText = '${(percentage * 100).toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isVotedByMe ? Colors.blue.shade600 : Colors.grey.shade300,
          width: isVotedByMe ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isVotedByMe)
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isClosed || _votingOptionId != null ? null : () => _handleVote(option.id, poll),
          child: Stack(
            children: [
              // Animated Background Fill Bar
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    color: isVotedByMe ? Colors.blue.shade50 : Colors.grey.shade100,
                  ),
                ),
              ),
              // Card Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                child: Row(
                  children: [
                    if (isVoting)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    else
                      Icon(
                        isVotedByMe ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isVotedByMe ? Colors.blue.shade600 : Colors.grey.shade400,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isVotedByMe ? FontWeight.w700 : FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          percentageText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isVotedByMe ? Colors.blue.shade700 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${option.votes} чол.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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