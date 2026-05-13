// ================= UNIVERSAL PDF VIEWER WIDGET =================
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerWidget extends StatelessWidget {
  final Uint8List? fileBytes;
  final String? filePath;

  final void Function(int totalPages) onDocumentLoaded;
  final void Function(int page) onPageChanged;
  final void Function(String error) onLoadFailed;

  const PdfViewerWidget({
    Key? key,
    this.fileBytes,
    this.filePath,
    required this.onDocumentLoaded,
    required this.onPageChanged,
    required this.onLoadFailed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // UNIVERSAL PRIORITY: BYTES FIRST
      if (fileBytes != null && fileBytes!.isNotEmpty) {
        return SfPdfViewer.memory(
          fileBytes!,
          onDocumentLoaded: (details) {
            onDocumentLoaded(details.document.pages.count);
          },
          onPageChanged: (details) {
            onPageChanged(details.newPageNumber);
          },
          onDocumentLoadFailed: (details) {
            onLoadFailed(details.description);
          },
        );
      }

      // MOBILE/DESKTOP FALLBACK ONLY
      if (!kIsWeb && filePath != null && filePath!.isNotEmpty) {
        return SfPdfViewer.file(
          File(filePath!),
          onDocumentLoaded: (details) {
            onDocumentLoaded(details.document.pages.count);
          },
          onPageChanged: (details) {
            onPageChanged(details.newPageNumber);
          },
          onDocumentLoadFailed: (details) {
            onLoadFailed(details.description);
          },
        );
      }

      return const Center(
        child: Text("No PDF data available"),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onLoadFailed(e.toString());
      });

      return Center(
        child: Text("Error loading PDF:\n$e"),
      );
    }
  }
}