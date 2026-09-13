import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../core/offline/download_actions.dart';
import '../../../../core/offline/download_manager.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';
import '../../../../core/presentation/widgets/search_with_downloads_bar.dart';
import '../../../../core/presentation/widgets/shimmer_loading_list.dart';
import '../../../profile/presentation/widgets/user_profile_button.dart';
import '../../data/models/document_models.dart';
import '../../data/repositories/document_repository.dart';
import '../providers/document_providers.dart';
import '../widgets/document_card.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late final PagingController<int, DocumentModel> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, DocumentModel>(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) return null;
        final lastItems = state.pages?.last;
        if (lastItems != null && lastItems.length < 10) return null;
        return state.nextIntPageKey;
      },
      fetchPage: (pageKey) async {
        final response = await ref.read(documentRepositoryProvider).getDocuments(
              page: pageKey,
              limit: 10,
              search: ref.read(documentSearchQueryProvider),
            );
        return response.data;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsPagingControllerProvider.notifier).state = _pagingController;
    });
  }

  @override
  void dispose() {
    if (ref.read(documentsPagingControllerProvider) == _pagingController) {
      ref.read(documentsPagingControllerProvider.notifier).state = null;
    }
    _searchController.dispose();
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(documentSearchQueryProvider.notifier).state = query.trim();
      _pagingController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Документи'),
        actions: const [UserProfileButton()],
      ),
      body: Column(
        children: [
          SearchWithDownloadsBar(
            controller: _searchController,
            hintText: 'Пошук документів...',
            onChanged: _onSearchChanged,
            downloadsTooltip: 'Завантажені документи',
            onDownloadsTap: () => context.push('/documents/offline'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
              child: PagingListener(
                controller: _pagingController,
                builder: (context, state, fetchNextPage) => PagedListView<int, DocumentModel>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 100 + MediaQuery.paddingOf(context).bottom),
                  builderDelegate: PagedChildBuilderDelegate<DocumentModel>(
                    firstPageProgressIndicatorBuilder: (_) => const ShimmerLoadingList(),
                    firstPageErrorIndicatorBuilder: (_) => CommonErrorWidget(
                      error: state.error?.toString() ?? 'Помилка завантаження',
                      onRetry: _pagingController.refresh,
                    ),
                    noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
                    itemBuilder: (context, doc, index) => DocumentCard(
                      index: index,
                      document: doc,
                      onTap: () {
                        if (doc.fileUrl != null) {
                          context.push('/documents/view', extra: doc);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Файл відсутній')),
                          );
                        }
                      },
                      onLongPress: () => showDownloadPopup(
                        context: context,
                        ref: ref,
                        remoteId: doc.id,
                        kind: OfflineDownloadKind.document,
                        title: doc.title ?? 'Документ',
                        remoteUrl: doc.fileUrl,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Документи не знайдені',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
