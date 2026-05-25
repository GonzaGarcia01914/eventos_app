import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/event.dart';

class StoryMediaView extends StatefulWidget {
  const StoryMediaView({
    super.key,
    required this.event,
    required this.isActive,
  });

  final Event event;
  final bool isActive;

  @override
  State<StoryMediaView> createState() => _StoryMediaViewState();
}

class _StoryMediaViewState extends State<StoryMediaView> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  @override
  void didUpdateWidget(StoryMediaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      _disposeVideo();
      _initMedia();
    } else if (oldWidget.isActive != widget.isActive) {
      _syncPlayback();
    }
  }

  Future<void> _initMedia() async {
    if (!widget.event.hasVideo) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.event.videoUrl!),
    );
    _videoController = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0);
      if (!mounted) return;
      setState(() => _isVideoReady = true);
      _syncPlayback();
    } catch (_) {
      if (mounted) setState(() => _isVideoReady = false);
    }
  }

  void _syncPlayback() {
    final controller = _videoController;
    if (controller == null || !_isVideoReady) return;

    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoReady = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.hasVideo && _isVideoReady && _videoController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.event.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, __, ___) => const _PlaceholderMedia(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _PlaceholderMedia(showLoader: true);
        },
      );
    }

    return const _PlaceholderMedia();
  }
}

class _PlaceholderMedia extends StatelessWidget {
  const _PlaceholderMedia({this.showLoader = false});

  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      child: Center(
        child: showLoader
            ? const CircularProgressIndicator(color: AppColors.primary)
            : const Icon(Icons.event_rounded, size: 72, color: AppColors.onSurfaceMuted),
      ),
    );
  }
}
