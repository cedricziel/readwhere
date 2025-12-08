import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Utility class for file system operations.
///
/// Provides helper methods for managing files and directories
/// used by the e-reader app, including book files and covers.
class FileUtils {
  // Private constructor to prevent instantiation
  FileUtils._();

  /// Gets the app's documents directory.
  ///
  /// Returns the platform-specific directory where the app can store files.
  /// Throws [FileException] if the directory cannot be accessed.
  static Future<Directory> getAppDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      throw FileException('Failed to get app documents directory: $e');
    }
  }

  /// Gets the directory where book files are stored.
  ///
  /// Creates the directory if it doesn't exist.
  /// Returns the books directory path.
  static Future<Directory> getBooksDirectory() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final booksDir = Directory(
        path.join(appDir.path, AppConstants.booksDirectory),
      );

      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      return booksDir;
    } catch (e) {
      throw FileException('Failed to get or create books directory: $e');
    }
  }

  /// Gets the directory where book cover images are stored.
  ///
  /// Creates the directory if it doesn't exist.
  /// Returns the covers directory path.
  static Future<Directory> getCoversDirectory() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final coversDir = Directory(
        path.join(appDir.path, AppConstants.coversDirectory),
      );

      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      return coversDir;
    } catch (e) {
      throw FileException('Failed to get or create covers directory: $e');
    }
  }

  /// Gets the temporary directory for the app.
  ///
  /// Creates the directory if it doesn't exist.
  /// Returns the temp directory path.
  static Future<Directory> getTempDirectory() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final tempDir = Directory(
        path.join(appDir.path, AppConstants.tempDirectory),
      );

      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      return tempDir;
    } catch (e) {
      throw FileException('Failed to get or create temp directory: $e');
    }
  }

  /// Copies a file to the app's storage.
  ///
  /// [sourcePath] is the path to the file to copy.
  /// [destinationDirectory] is the target directory.
  /// [newFileName] is optional custom filename. If not provided, uses original filename.
  ///
  /// Returns the path to the copied file.
  /// Throws [FileException] if the operation fails.
  static Future<String> copyFileToAppStorage({
    required String sourcePath,
    required Directory destinationDirectory,
    String? newFileName,
  }) async {
    try {
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        throw FileException('Source file does not exist: $sourcePath');
      }

      final fileName = newFileName ?? path.basename(sourcePath);
      final destinationPath = path.join(destinationDirectory.path, fileName);
      final destinationFile = File(destinationPath);

      await sourceFile.copy(destinationPath);

      return destinationFile.path;
    } catch (e) {
      if (e is FileException) rethrow;
      throw FileException('Failed to copy file to app storage: $e');
    }
  }

  /// Deletes a file from app storage.
  ///
  /// [filePath] is the path to the file to delete.
  /// Returns true if the file was deleted, false if it didn't exist.
  /// Throws [FileException] if the deletion fails.
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return false;
      }

      await file.delete();
      return true;
    } catch (e) {
      throw FileException('Failed to delete file: $e');
    }
  }

  /// Gets the file extension from a file path.
  ///
  /// [filePath] is the path to the file.
  /// Returns the extension without the dot (e.g., 'epub', 'pdf').
  /// Returns empty string if no extension found.
  static String getFileExtension(String filePath) {
    final extension = path.extension(filePath);
    return extension.isNotEmpty ? extension.substring(1).toLowerCase() : '';
  }

  /// Checks if a file format is supported.
  ///
  /// [filePath] is the path to the file.
  /// Returns true if the file format is supported.
  static bool isSupportedFormat(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.supportedBookFormats.contains(extension);
  }

  /// Gets the file size in bytes.
  ///
  /// [filePath] is the path to the file.
  /// Returns the file size in bytes.
  /// Throws [FileException] if the file doesn't exist or cannot be accessed.
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw FileException('File does not exist: $filePath');
      }

      return await file.length();
    } catch (e) {
      if (e is FileException) rethrow;
      throw FileException('Failed to get file size: $e');
    }
  }

  /// Formats file size in human-readable format.
  ///
  /// [bytes] is the file size in bytes.
  /// Returns formatted string (e.g., "1.5 MB", "500 KB").
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Cleans up temporary files.
  ///
  /// Deletes all files in the temp directory.
  /// Returns the number of files deleted.
  static Future<int> cleanupTempFiles() async {
    try {
      final tempDir = await getTempDirectory();
      int deletedCount = 0;

      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      throw FileException('Failed to cleanup temp files: $e');
    }
  }
}
