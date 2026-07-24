import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shared image-pick entry point for the orders module (fabric images,
/// order media, style references). Pops a small camera-or-gallery chooser,
/// then returns the picked file as a `File`, or null if the user backed out
/// of either the chooser or the system picker.
///
/// Mirrors how the clients/guests photo flows obtain a `File` before
/// handing it to a repository upload method — image_picker is already a
/// dependency for exactly this. Images are lightly downscaled on pick to
/// keep uploads small; the backend still enforces its own 25MB ceiling.
///
/// Video isn't offered here yet — order media and style references accept
/// video server-side, but the v1 UI captures images only; wire up
/// `picker.pickVideo` when that's needed.
Future<File?> pickImageFile(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;

  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2000,
    maxHeight: 2000,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return File(picked.path);
}
