import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_models.dart';
import '../../data/repositories/project_repository.dart';

class ProjectPdfScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const ProjectPdfScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectPdfScreen> createState() => _ProjectPdfScreenState();
}

class _ProjectPdfScreenState extends ConsumerState<ProjectPdfScreen> {
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
      final fileUrl = widget.project.fileUrl;
      if (fileUrl == null || fileUrl.isEmpty) {
        throw Exception('Посилання на файл відсутнє');
      }

      final fileName = fileUrl.split('/').last;
      final localPath = await ref.read(projectRepositoryProvider).downloadProjectPdf(fileUrl, fileName);
      
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
        title: Text(widget.project.title ?? 'Документ проєкту', style: const TextStyle(fontSize: 18)),
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
            Text('Завантаження файлу...', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
              Text('Помилка', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    if (_localPath != null) {
      return PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        fitPolicy: FitPolicy.WIDTH,
      );
    }

    return const SizedBox.shrink();
  }
}