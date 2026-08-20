import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPdf();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.title ?? 'Документ',
          style: const TextStyle(fontSize: 18),
        ),
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
      return PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        pageSnap: false,
        fitPolicy: FitPolicy.WIDTH,
        onError: (error) {
          setState(() {
            _errorMessage = 'Не вдалося відрендерити PDF: $error';
          });
        },
      );
    }

    return const SizedBox.shrink();
  }
}