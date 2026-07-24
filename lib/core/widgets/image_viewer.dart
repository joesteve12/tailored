import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'feedback.dart';

/// Open a full-screen image viewer over the current screen.
///
/// The viewer is a modal dialog with a near-opaque backdrop — it feels like
/// an in-place overlay, not a route destination (no app-bar-back, no tab
/// swap). Dismisses via the close button or the system back button.
///
/// * [urls] is the collection to browse. Even for a single image, pass a
///   one-item list — the same code path handles both cases.
/// * [initialIndex] controls which image is shown first when the caller
///   taps a specific thumbnail out of a set.
/// * [zoomable] = false for profile pictures — the viewer still expands
///   to full size and dismisses the same way, but pinch/pan/double-tap-
///   to-zoom are disabled because profile pics don't reward zooming.
///
/// The save button downloads the currently-visible image and opens the
/// system share sheet, from which "Save to Photos" is one tap. This is
/// the same pattern the app already uses for invoice/receipt PDFs — no
/// new dependency, cross-platform, and lets the tailor forward images to
/// clients via WhatsApp in the same flow as saving locally.
Future<void> showImageViewer(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
  bool zoomable = true,
}) {
  if (urls.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    // Near-opaque so the underlying screen visually recedes; still transparent
    // enough that the OS-level blur (if any) shows through, matching platform
    // image viewers.
    barrierColor: Colors.black.withValues(alpha: 0.92),
    useSafeArea: false,
    builder: (context) => _ImageViewer(
      urls: urls,
      initialIndex: initialIndex.clamp(0, urls.length - 1),
      zoomable: zoomable,
    ),
  );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({
    required this.urls,
    required this.initialIndex,
    required this.zoomable,
  });

  final List<String> urls;
  final int initialIndex;
  final bool zoomable;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pageController;
  late int _currentPage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final url = widget.urls[_currentPage];
      // Fresh Dio — the app's shared instance has auth interceptors that
      // would attach a Bearer token to every request, which is wrong for
      // public CDN URLs (ImageKit) and could leak credentials to any
      // future URL that happens not to be a first-party host. If images
      // ever move to a signed-URL scheme, this is where to plumb it in.
      final res = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes == null) throw Exception('No image data returned');
      // Write to temp with a real image extension so share targets (Photos,
      // WhatsApp) treat it as an image, not an opaque blob.
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/image_${DateTime.now().millisecondsSinceEpoch}'
        '${_extFromUrl(url)}',
      );
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, e, action: 'Could not save image');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Sniff extension from URL path. Falls back to .jpg — most image CDNs
  /// serve JPEG for opaque-format URLs, and Photos/WhatsApp both accept
  /// mislabelled JPEGs of PNGs without complaint if we happen to be wrong.
  String _extFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    for (final ext in const ['.png', '.webp', '.gif', '.heic', '.heif']) {
      if (path.endsWith(ext)) return ext;
    }
    return '.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          // Physics: disable swipe when only one image (no gallery to browse).
          physics: widget.urls.length == 1
              ? const NeverScrollableScrollPhysics()
              : null,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, i) => Center(
            child: InteractiveViewer(
              panEnabled: widget.zoomable,
              scaleEnabled: widget.zoomable,
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, e, s) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Top controls: save + close. SafeArea so they clear the status bar.
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
        // Page indicator — only meaningful when there's actually a gallery
        // to browse. Positioned at the bottom to stay out of the image.
        if (widget.urls.length > 1)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
