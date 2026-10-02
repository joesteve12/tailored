import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/video_trim.dart';
import '../../../core/widgets/feedback.dart';

/// Interactive trim screen for a picked video (scoped video, Phase 8).
///
/// Shows the clip with a draggable range selector capped at [kMaxVideoDuration]
/// (10s). The shop drags to choose which window to keep; on confirm the clip is
/// losslessly trimmed on-device (native MediaMuxer, no ffmpeg) and the trimmed
/// [File] is returned via `Navigator.pop`. Backing out returns null.
///
/// If the source is already within the limit and the whole thing is selected,
/// the original file is returned untouched — no trim needed.
class VideoTrimScreen extends StatefulWidget {
  const VideoTrimScreen({super.key, required this.file});

  final File file;

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _processing = false;

  double _durationMs = 0;
  RangeValues _range = const RangeValues(0, 0);

  double get _maxWindowMs => kMaxVideoDuration.inMilliseconds.toDouble();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..addListener(_onTick);
    _controller.initialize().then((_) {
      if (!mounted) return;
      final total = _controller.value.duration.inMilliseconds.toDouble();
      final end = total <= _maxWindowMs ? total : _maxWindowMs;
      setState(() {
        _durationMs = total;
        _range = RangeValues(0, end);
        _ready = true;
      });
    }).catchError((Object e) {
      if (mounted) {
        showErrorSnackbar(context, e, action: 'Could not open video');
        Navigator.of(context).pop();
      }
    });
  }

  // While previewing, loop the playhead back to the start once it runs past the
  // selected end so the shop only ever sees the window they picked.
  void _onTick() {
    if (!_ready || _processing) return;
    final posMs = _controller.value.position.inMilliseconds;
    if (_controller.value.isPlaying && posMs >= _range.end) {
      _controller.pause();
      _controller.seekTo(Duration(milliseconds: _range.start.round()));
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _onRangeChanged(RangeValues v) {
    double start = v.start;
    double end = v.end;
    // Constrain the window to at most the max length. Whichever thumb moved
    // furthest is the one the shop is dragging — clamp the other to keep the
    // window width within the cap.
    if (end - start > _maxWindowMs) {
      final startMoved = (v.start - _range.start).abs() >= (v.end - _range.end).abs();
      if (startMoved) {
        end = start + _maxWindowMs;
      } else {
        start = end - _maxWindowMs;
      }
    }
    start = start.clamp(0, _durationMs);
    end = end.clamp(0, _durationMs);
    setState(() => _range = RangeValues(start, end));
    _controller.pause();
    _controller.seekTo(Duration(milliseconds: start.round()));
  }

  Future<void> _togglePreview() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.seekTo(Duration(milliseconds: _range.start.round()));
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _confirm() async {
    final start = Duration(milliseconds: _range.start.round());
    final end = Duration(milliseconds: _range.end.round());

    // Nothing to cut: the source already fits and the whole clip is selected.
    final noTrimNeeded = _durationMs <= _maxWindowMs &&
        _range.start <= 0 &&
        (_durationMs - _range.end).abs() < 1;
    if (noTrimNeeded) {
      Navigator.of(context).pop(widget.file);
      return;
    }

    setState(() => _processing = true);
    await _controller.pause();
    try {
      final trimmed = await trimVideo(widget.file, start: start, end: end);
      if (mounted) Navigator.of(context).pop(trimmed);
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        showErrorSnackbar(context, e, action: 'Could not trim video');
      }
    }
  }

  String _fmt(double ms) {
    final total = (ms / 1000);
    final s = total.floor();
    final tenths = ((total - s) * 10).floor();
    return '$s.${tenths}s';
  }

  @override
  Widget build(BuildContext context) {
    final selectedMs = _range.end - _range.start;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trim video'),
        actions: [
          TextButton(
            onPressed: (_ready && !_processing) ? _confirm : null,
            child: const Text('Use clip'),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio == 0
                              ? 16 / 9
                              : _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton.filledTonal(
                                onPressed: _togglePreview,
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                              ),
                              Text(
                                'Selected: ${_fmt(selectedMs)}  ·  max ${kMaxVideoDuration.inSeconds}s',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          RangeSlider(
                            min: 0,
                            max: _durationMs <= 0 ? 1 : _durationMs,
                            values: _range,
                            labels: RangeLabels(
                              _fmt(_range.start),
                              _fmt(_range.end),
                            ),
                            onChanged: _processing ? null : _onRangeChanged,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(_range.start),
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text(_fmt(_range.end),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            'Trimming…',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
