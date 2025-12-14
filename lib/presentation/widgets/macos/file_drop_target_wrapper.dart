import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Wraps content with a drop target for importing files from the desktop.
///
/// This widget allows users to drag and drop EPUB, PDF, CBZ, and CBR files
/// from Finder (or File Explorer) to import them into the library.
///
/// Only active on desktop platforms (macOS, Windows, Linux).
/// On other platforms, it simply returns the child.
///
/// Example:
/// ```dart
/// FileDropTargetWrapper(
///   onFilesDropped: (files) => libraryProvider.importBooks(files),
///   child: MaterialApp(...),
/// )
/// ```
class FileDropTargetWrapper extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Callback when valid files are dropped.
  ///
  /// The callback receives a list of file paths that were dropped.
  /// Only files with supported extensions (epub, pdf, cbz, cbr) are included.
  final void Function(List<String> filePaths)? onFilesDropped;

  /// Supported file extensions for import.
  final List<String> supportedExtensions;

  const FileDropTargetWrapper({
    super.key,
    required this.child,
    this.onFilesDropped,
    this.supportedExtensions = const ['epub', 'pdf', 'cbz', 'cbr'],
  });

  @override
  State<FileDropTargetWrapper> createState() => _FileDropTargetWrapperState();
}

class _FileDropTargetWrapperState extends State<FileDropTargetWrapper> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // Only enable on desktop platforms
    if (kIsWeb ||
        !(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) {
        setState(() => _isDragging = false);
        _handleDroppedFiles(details);
      },
      // Use Directionality to provide text direction for Stack alignment
      // since this widget may be used above MaterialApp/MacosApp
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [widget.child, if (_isDragging) _buildDropOverlay(context)],
        ),
      ),
    );
  }

  Widget _buildDropOverlay(BuildContext context) {
    // Use default colors that work without a Theme ancestor
    // This is necessary because FileDropTargetWrapper may wrap the app itself
    const primaryColor = Color(0xFF007AFF); // iOS blue
    const surfaceColor = Colors.white;
    const textColor = Color(0xFF1D1D1F);
    const subtextColor = Color(0xFF8E8E93);

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: primaryColor.withValues(alpha: 0.1),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: primaryColor, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.file_download,
                    size: 64,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Drop books here to import',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supported formats: ${widget.supportedExtensions.map((e) => '.$e').join(', ')}',
                    style: const TextStyle(fontSize: 14, color: subtextColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDroppedFiles(DropDoneDetails details) {
    // Extract file paths from the dropped files
    final filePaths = details.files.map((file) => file.path).toList();

    // Filter to only supported extensions
    final validFiles = filePaths.where((path) {
      final extension = path.split('.').last.toLowerCase();
      return widget.supportedExtensions.contains(extension);
    }).toList();

    if (validFiles.isNotEmpty && widget.onFilesDropped != null) {
      widget.onFilesDropped!(validFiles);
    }
  }
}
