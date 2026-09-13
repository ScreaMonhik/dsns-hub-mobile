import 'package:flutter/material.dart';

class SearchWithDownloadsBar extends StatelessWidget {
  const SearchWithDownloadsBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onDownloadsTap,
    required this.downloadsTooltip,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onDownloadsTap;
  final String downloadsTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: downloadsTooltip,
            onPressed: onDownloadsTap,
            icon: const Icon(Icons.download_done_outlined),
          ),
        ],
      ),
    );
  }
}
