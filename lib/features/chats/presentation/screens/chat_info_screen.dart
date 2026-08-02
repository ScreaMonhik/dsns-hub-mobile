import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_providers.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';
import '../../../auth/providers/auth_provider.dart';

class ChatInfoScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ChatInfoScreen({super.key, required this.groupId});

  @override
  ConsumerState<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends ConsumerState<ChatInfoScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _isUploading = true);
        await ref.read(chatsListProvider.notifier).updateGroupAvatar(widget.groupId, image.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Фото чату успішно оновлено'),
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
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupState = ref.watch(chatsListProvider);
    final membersState = ref.watch(chatMembersProvider(widget.groupId));
    final currentUserId = ref.watch(currentUserIdProvider);
    
    final group = groupState.value?.where((g) => g.id == widget.groupId).firstOrNull;
    final groupName = group?.name ?? 'Інформація про чат';
    
    // Перевірка прав адміністратора
    bool isAdmin = false;
    if (membersState.value != null && currentUserId != null) {
      final currentUserMember = membersState.value!.where((m) => m.userId == currentUserId).firstOrNull;
      isAdmin = currentUserMember?.isAdmin ?? false;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              // Збільшуємо горизонтальні відступи, щоб багаторядковий текст фізично не міг перекрити кнопку справа
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              title: IgnorePointer(
                child: Text(
                  groupName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2)),
                      Shadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  group?.avatarUrl != null
                      ? AuthNetworkImage(
                          imageUrl: group!.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: theme.colorScheme.primaryContainer,
                          alignment: Alignment.center,
                          child: Text(
                            groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 80,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  if (group?.avatarUrl != null)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black26,
                            Colors.black87,
                          ],
                          stops: [0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  if (_isUploading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else if (isAdmin)
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        elevation: 6,
                        child: InkWell(
                          onTap: _pickAndUploadImage,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Учасники',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          membersState.when(
            data: (members) {
              if (members.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Немає учасників')),
                  ),
                );
              }
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = members[index];
                    final user = member.user;
                    final fullName = user != null ? '${user.firstName} ${user.lastName}' : 'Невідомий користувач';
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: user?.avatarUrl != null
                            ? ClipOval(
                                child: AuthNetworkImage(
                                  imageUrl: user!.avatarUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                fullName[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      title: Text(
                        fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: member.isAdmin 
                          ? Text('Адміністратор', style: TextStyle(color: theme.colorScheme.primary)) 
                          : null,
                    );
                  },
                  childCount: members.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('Помилка: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}