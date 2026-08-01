import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/poll_provider.dart';
import '../../data/models/poll_model.dart';

class PollsScreen extends ConsumerStatefulWidget {
  const PollsScreen({super.key});

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch polls only if not already loaded to preserve state during tab switching
    Future.microtask(() {
      if (ref.read(pollsProvider).value == null) {
        ref.read(pollsProvider.notifier).fetchPolls();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pollsState = ref.watch(pollsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Опитування', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: pollsState.when(
        data: (polls) {
          final visiblePolls = polls.where((p) => p.status != 'DRAFT').toList();
          
          if (visiblePolls.isEmpty) {
            return const Center(child: Text('Немає активних опитувань', style: TextStyle(color: Colors.grey)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(pollsProvider.notifier).fetchPolls(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visiblePolls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _PollCard(poll: visiblePolls[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Помилка: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(pollsProvider.notifier).fetchPolls(),
                child: const Text('Оновити'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  const _PollCard({required this.poll});

  @override
  Widget build(BuildContext context) {
    final isLocallyExpired = poll.expiresAt != null && poll.expiresAt!.isBefore(DateTime.now());
    final isClosed = poll.status != 'PUBLISHED' || isLocallyExpired; 
    final isVoted = poll.userVotedOptionId != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/polls/${poll.id}'),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isClosed ? Colors.grey.shade100 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isClosed ? Colors.grey.shade300 : Colors.blue.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isClosed ? Icons.lock_outline : Icons.poll_outlined,
                                  size: 14,
                                  color: isClosed ? Colors.grey.shade700 : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isClosed ? 'Завершено' : 'Активне',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isClosed ? Colors.grey.shade700 : Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isClosed && poll.expiresAt != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd.MM HH:mm').format(poll.expiresAt!.toLocal()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(poll.createdAt.toLocal()),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  poll.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: Colors.black87,
                  ),
                ),
                if (poll.description != null && poll.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    poll.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.people_alt_outlined, size: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Учасників',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            Text(
                              '${poll.totalVotes}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isVoted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Проголосовано',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!isClosed)
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade300),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}