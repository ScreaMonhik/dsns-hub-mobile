import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/providers/auth_provider.dart';

class TipTapVideoPlayer extends ConsumerStatefulWidget {
  final String src;
  final String baseUrl;

  const TipTapVideoPlayer({
    super.key,
    required this.src,
    required this.baseUrl,
  });

  @override
  ConsumerState<TipTapVideoPlayer> createState() => _TipTapVideoPlayerState();
}

class _TipTapVideoPlayerState extends ConsumerState<TipTapVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(TipTapVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src || oldWidget.baseUrl != widget.baseUrl) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _initController();
    }
  }

  Future<void> _initController() async {
    final url = resolveMediaUrl(widget.src, baseUrl: widget.baseUrl);
    if (url == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final token = ref.read(currentTokenProvider);
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_failed) {
      return Container(
        height: 180,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Text(
          'Не вдалося завантажити відео',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 180,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final aspect = value.aspectRatio;
        return AspectRatio(
          aspectRatio: aspect > 0 ? aspect : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
                  child: AnimatedOpacity(
                    opacity: value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
