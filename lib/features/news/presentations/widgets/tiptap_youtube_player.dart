import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/utils/safe_url.dart';

class TipTapYoutubePlayer extends StatefulWidget {
  final String src;

  const TipTapYoutubePlayer({super.key, required this.src});

  @override
  State<TipTapYoutubePlayer> createState() => _TipTapYoutubePlayerState();
}

class _TipTapYoutubePlayerState extends State<TipTapYoutubePlayer> {
  YoutubePlayerController? _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _bind(widget.src);
  }

  @override
  void didUpdateWidget(TipTapYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _controller?.close();
      _controller = null;
      _bind(widget.src);
    }
  }

  void _bind(String src) {
    final id = youtubeVideoId(src);
    _videoId = id;
    if (id == null) return;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
        playsInline: true,
        privacyEnhancedMode: true,
        strictRelatedVideos: true,
        interfaceLanguage: 'uk',
        captionLanguage: 'uk',
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;
    final videoId = _videoId;

    if (controller == null || videoId == null) {
      return _YoutubeFallback(src: widget.src);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: YoutubePlayer(
          controller: controller,
          aspectRatio: 16 / 9,
          autoFullScreen: false,
          enableFullScreenOnVerticalDrag: false,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _YoutubeFallback extends StatelessWidget {
  final String src;

  const _YoutubeFallback({required this.src});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => launchSafeYoutubeUrl(src),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_fill,
              color: theme.colorScheme.error,
              size: 36,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Дивитись відео на YouTube',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
