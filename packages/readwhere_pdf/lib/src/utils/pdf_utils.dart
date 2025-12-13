import 'dart:io';
import 'dart:typed_data';

/// Utility functions for working with PDF files.
class PdfUtils {
  PdfUtils._();

  /// PDF file signature bytes: %PDF-
  static const List<int> pdfSignature = [0x25, 0x50, 0x44, 0x46, 0x2D];

  /// Checks if the given bytes start with the PDF signature.
  static bool isPdfSignature(List<int> bytes) {
    if (bytes.length < pdfSignature.length) return false;
    for (var i = 0; i < pdfSignature.length; i++) {
      if (bytes[i] != pdfSignature[i]) return false;
    }
    return true;
  }

  /// Checks if a file is a PDF by reading its first few bytes.
  static Future<bool> isPdfFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final raf = await file.open();
      try {
        final bytes = await raf.read(pdfSignature.length);
        return isPdfSignature(bytes);
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// Checks if the given bytes represent a PDF file.
  static bool isPdfBytes(Uint8List bytes) {
    return isPdfSignature(bytes);
  }

  /// Extracts the filename without extension from a path.
  static String extractFilename(String path) {
    final file = File(path);
    final basename = file.uri.pathSegments.last;
    final dotIndex = basename.lastIndexOf('.');
    return dotIndex > 0 ? basename.substring(0, dotIndex) : basename;
  }

  /// Returns the file extension (without the dot) in lowercase.
  static String getExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) return '';
    return path.substring(dotIndex + 1).toLowerCase();
  }

  /// Checks if the file has a .pdf extension.
  static bool hasPdfExtension(String path) {
    return getExtension(path) == 'pdf';
  }

  /// Converts points to pixels at a given DPI.
  static double pointsToPixels(double points, double dpi) {
    return points * dpi / 72.0;
  }

  /// Converts pixels to points at a given DPI.
  static double pixelsToPoints(double pixels, double dpi) {
    return pixels * 72.0 / dpi;
  }
}
