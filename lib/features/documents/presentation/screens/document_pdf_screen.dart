import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../data/models/document_models.dart';
import '../../data/repositories/document_repository.dart';

class DocumentPdfScreen extends ConsumerStatefulWidget {
  final DocumentModel document;

  const DocumentPdfScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentPdfScreen> createState() => _DocumentPdfScreenState();
}

class _DocumentPdfScreenState extends ConsumerState<DocumentPdfScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;

  final PdfViewerController _pdfViewerController = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPdf();
  }

  @override
  void dispose() {
    _searchResult.removeListener(_onSearchResultUpdated);
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchResultUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _downloadAndOpenPdf() async {
    try {
      final fileUrl = widget.document.fileUrl;
      if (fileUrl == null || fileUrl.isEmpty) {
        throw Exception('Посилання на файл відсутнє');
      }

      final fileName = fileUrl.split('/').last;
      
      final localPath = await ref.read(documentRepositoryProvider).downloadDocumentToTemp(fileUrl, fileName);
      
      if (mounted) {
        setState(() {
          _localPath = localPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      _searchResult.clear();
      setState(() {});
      return;
    }
    
    _searchResult.removeListener(_onSearchResultUpdated);
    _searchResult = await _pdfViewerController.searchText(query);
    _searchResult.addListener(_onSearchResultUpdated);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Пошук по тексту...',
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _searchResult.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: _performSearch,
              )
            : Text(
                widget.document.title ?? 'Документ',
                style: const TextStyle(fontSize: 18),
              ),
        actions: [
          if (_isSearchMode && _searchResult.hasResult) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                _searchResult.previousInstance();
              },
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                _searchResult.nextInstance();
              },
            ),
          ],
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchResult.clear();
                  _searchController.clear();
                }
              });
            },
          ),
          if (_localPath != null && !_isLoading && !_isSearchMode) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                Share.shareXFiles(
                  [XFile(_localPath!)],
                  text: widget.document.title ?? 'Документ',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () async {
                final file = File(_localPath!);
                final bytes = await file.readAsBytes();
                await Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) async => bytes,
                  name: widget.document.title ?? 'Document',
                );
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Завантаження документа...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Помилка відкриття файлу',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _downloadAndOpenPdf();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Спробувати ще раз'),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath != null) {
      return SfPdfViewer.file(
        File(_localPath!),
        controller: _pdfViewerController,
        canShowScrollHead: false,
        canShowScrollStatus: false,
      );
    }

    return const SizedBox.shrink();
  }
}