import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'feedback.dart';

/// Open a full-screen player for a single video [url] (an ImageKit URL).
///
/// Mirrors [showImageViewer]: a modal dialog over a near-opaque backdrop with a
/// close button and the same save/share affordance, so a tailor can forward a
/// reference clip to a client the same way they forward photos. Playback uses
/// `video_player` (already a dependency for the trim screen) — no new package.
Future<void> showVideoViewer(
  BuildContext context, {
  required String url,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) => _VideoViewer(url: url),
    // Fade + a slight scale-up, matching the image viewer's open animation.
    transitionBuilder: (context, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _VideoViewer extends StatefulWidget {
  const _VideoViewer({required this.url});

  final String url;

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..addListener(_onTick);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.setLooping(true);
      _controller.play();
      setState(() => _ready = true);
    }).catchError((Object e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not load video');
        Navigator.of(context).pop();
      }
    });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Fresh Dio — the shared instance's auth interceptor would attach a
      // Bearer token, which is wrong for public ImageKit URLs (same rationale
      // as the image viewer's save).
      final res = await Dio().get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes == null) throw Exception('No video data returned');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/video_${DateTime.now().millisecondsSinceEpoch}'
        '${_extFromUrl(widget.url)}',
      );
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, e, action: 'Could not save video');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _extFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    for (final ext in const ['.mov', '.webm', '.m4v']) {
      if (path.endsWith(ext)) return ext;
    }
    return '.mp4';
  }

  @override
  Widget build(BuildContext context) {
    final playing = _ready && _controller.value.isPlaying;
    return Stack(
      children: [
        Center(
          child: _ready
              ? GestureDetector(
                  onTap: _togglePlay,
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
        // Center play/pause affordance — fades out while playing.
        if (_ready && !playing)
          Center(
            child: IgnorePointer(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white.withValues(alpha: 0.85),
                size: 72,
              ),
            ),
          ),
        // Scrubber pinned to the bottom.
        if (_ready)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ),
            ),
          ),
        // Top controls: save + close.
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.ios_share, color: Colors.white),
                    tooltip: 'Save or share',
                    onPressed: _saving ? null : _save,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
