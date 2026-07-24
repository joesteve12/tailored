import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The two delivery formats every document endpoint supports (`?format=`):
/// a PDF or a rendered PNG image. Images are handier to drop straight into a
/// WhatsApp chat as a photo; PDFs are the "proper document" choice.
enum DocFormat { pdf, image }

extension DocFormatX on DocFormat {
  /// The `format` query value the backend expects.
  String get apiValue => this == DocFormat.pdf ? 'pdf' : 'image';

  /// File extension for the shared temp file.
  String get extension => this == DocFormat.pdf ? 'pdf' : 'png';

  String get mimeType =>
      this == DocFormat.pdf ? 'application/pdf' : 'image/png';

  String get label => this == DocFormat.pdf ? 'PDF' : 'Image';
}

/// Asks the owner whether to share the document as a PDF or an image. Returns
/// the choice, or null if dismissed. A small bottom sheet so the two options
/// are one tap each on mobile.
Future<DocFormat?> pickDocumentFormat(BuildContext context) {
  return showModalBottomSheet<DocFormat>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Share as PDF'),
            subtitle: const Text('A document file'),
            onTap: () => Navigator.pop(context, DocFormat.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Share as image'),
            subtitle: const Text('A photo, easy to drop into a chat'),
            onTap: () => Navigator.pop(context, DocFormat.image),
          ),
        ],
      ),
    ),
  );
}

/// Writes document [bytes] to a temporary file and hands it to the OS share
/// sheet, so the owner can forward it to a tailor's (or client's) WhatsApp —
/// or anywhere else the device offers. Used for the per-item work order and
/// the invoice/receipt: the hand-off is identical for all three (plan §7),
/// which is why this lives in core rather than the orders feature.
///
/// The share sheet can't pre-select a specific WhatsApp chat — that's an OS
/// constraint on file attachments, not something a paid API removes — so the
/// owner taps the chat themselves. Zero Business-API cost, a few taps.
///
/// [fileName] should include the extension (e.g. `work_order_1042.pdf`);
/// [mimeType] defaults to PDF. [text] becomes the message caption alongside
/// the file. Throws if writing or sharing fails, for the caller to surface.
Future<void> shareDocumentBytes(
  Uint8List bytes, {
  required String fileName,
  String mimeType = 'application/pdf',
  String? text,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType, name: fileName)],
    text: text,
  );
}

/// Sanitises a string for use in a file name: collapses anything that isn't a
/// letter, digit, dash or underscore into a single underscore, and trims
/// leading/trailing underscores. Keeps generated document names tidy and
/// filesystem-safe across platforms.
String safeFileSegment(String raw) {
  final cleaned =
      raw.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  return cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
}
