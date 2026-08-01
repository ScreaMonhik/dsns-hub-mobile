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
          if (polls.isEmpty) {
            return const Center(child: Text('Немає активних опитувань', style: TextStyle(color: Colors.grey)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(pollsProvider.notifier).fetchPolls(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: polls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _PollCard(poll: polls[index]),
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
    final isClosed = poll.status == 'ARCHIVED';
    final isVoted = poll.userVotedOptionId != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/polls/${poll.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.grey.shade200 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isClosed ? 'Завершено' : 'Активне',
                      style: TextStyle(
                        fontSize: 12,
                        color: isClosed ? Colors.grey.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isVoted)
                    Icon(Icons.check_circle, color: Colors.blue.shade600, size: 22),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                poll.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (poll.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  poll.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        '${poll.totalVotes}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(poll.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}