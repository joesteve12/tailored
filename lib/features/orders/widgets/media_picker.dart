import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../billing/state/entitlements_notifier.dart';
import '../../billing/widgets/upgrade_prompt.dart';
import '../screens/video_trim_screen.dart';

enum _MediaChoice { takePhoto, choosePhoto, recordVideo, chooseVideo, videoLocked }

/// Entitlement-aware entry point used by every order-media / style-reference add
/// button. Resolves whether the shop may attach video (Studio+), then runs
/// [pickMedia] — showing the upgrade sheet if a Starter shop taps the video row.
///
/// Fail-closed on an entitlements error (images-only): the backend's 402 is the
/// real gate, so hiding the video option on a transient UI failure is safe.
Future<File?> pickOrderMedia(BuildContext context, WidgetRef ref) async {
  bool allowVideo = false;
  try {
    final ent = await ref.read(entitlementsProvider.future);
    allowVideo = ent.limits.video;
  } catch (_) {
    allowVideo = false;
  }
  if (!context.mounted) return null;
  return pickMedia(
    context,
    allowVideo: allowVideo,
    onVideoLocked: () => showUpgradeSheet(
      context,
      title: 'Video is a Studio feature',
      message: 'Upgrade to Studio to attach short video clips to your '
          'orders and style references.',
    ),
  );
}

/// Media picker for order media + style references (scoped video, Phase 8).
///
/// Always offers photo (camera/gallery). Video is offered only when
/// [allowVideo] (Studio+); a picked video is routed through the interactive
/// [VideoTrimScreen] (max 10s) before its trimmed [File] is returned. When video
/// is not entitled, a locked row invokes [onVideoLocked] (typically an upgrade
/// sheet) and no file is returned — keeping billing UI out of this helper.
///
/// Photo/video picks go through the system gallery (thumbnail grid) via
/// [ImagePicker.pickImage] / [ImagePicker.pickVideo]. Images are lightly
/// downscaled on pick; the backend still enforces its own size caps
/// (25MB image / 20MB video).
Future<File?> pickMedia(
  BuildContext context, {
  required bool allowVideo,
  VoidCallback? onVideoLocked,
}) async {
  final choice = await showModalBottomSheet<_MediaChoice>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheetContext, _MediaChoice.takePhoto),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose photo'),
            onTap: () => Navigator.pop(sheetContext, _MediaChoice.choosePhoto),
          ),
          if (allowVideo) ...[
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record video'),
              onTap: () => Navigator.pop(sheetContext, _MediaChoice.recordVideo),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose video'),
              onTap: () => Navigator.pop(sheetContext, _MediaChoice.chooseVideo),
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Add a video'),
              subtitle: const Text('Available on the Studio plan'),
              trailing: const Icon(Icons.lock_outline, size: 16),
              onTap: () => Navigator.pop(sheetContext, _MediaChoice.videoLocked),
            ),
        ],
      ),
    ),
  );

  if (choice == null) return null;
  final picker = ImagePicker();

  switch (choice) {
    case _MediaChoice.takePhoto:
    case _MediaChoice.choosePhoto:
      final picked = await picker.pickImage(
        source: choice == _MediaChoice.takePhoto
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      return picked == null ? null : File(picked.path);

    case _MediaChoice.recordVideo:
    case _MediaChoice.chooseVideo:
      final picked = await picker.pickVideo(
        source: choice == _MediaChoice.recordVideo
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (picked == null || !context.mounted) return null;
      // Hand the raw clip to the interactive trim screen; it returns the
      // trimmed file (or null if the shop backed out).
      return Navigator.of(context).push<File?>(
        MaterialPageRoute(
          builder: (_) => VideoTrimScreen(file: File(picked.path)),
        ),
      );

    case _MediaChoice.videoLocked:
      onVideoLocked?.call();
      return null;
  }
}
