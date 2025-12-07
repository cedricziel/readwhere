import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Information about a user script
///
/// Contains metadata about a Lua script file including its name,
/// file path, description, and enabled status.
class ScriptInfo {
  /// Display name of the script
  final String name;

  /// Absolute file path to the script
  final String filePath;

  /// Description of what the script does
  final String? description;

  /// Whether the script is enabled
  final bool enabled;

  /// File name without extension
  String get fileName => p.basenameWithoutExtension(filePath);

  /// File extension (e.g., '.lua')
  String get extension => p.extension(filePath);

  /// Last modified time of the script file
  final DateTime? lastModified;

  /// Size of the script file in bytes
  final int? fileSize;

  const ScriptInfo({
    required this.name,
    required this.filePath,
    this.description,
    this.enabled = true,
    this.lastModified,
    this.fileSize,
  });

  /// Create a ScriptInfo from a File
  static Future<ScriptInfo> fromFile(File file) async {
    final stat = await file.stat();
    final name = p.basenameWithoutExtension(file.path);

    // Try to read description from script comments
    String? description;
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');

      // Look for a description comment at the top of the file
      // Format: -- Description: Some description here
      for (final line in lines.take(10)) {
        final trimmed = line.trim();
        if (trimmed.startsWith('-- Description:')) {
          description = trimmed.substring('-- Description:'.length).trim();
          break;
        } else if (trimmed.startsWith('--[[') && trimmed.contains('Description:')) {
          // Multi-line comment format
          final match = RegExp(r'Description:\s*(.+?)(?:\]\]|$)').firstMatch(trimmed);
          if (match != null) {
            description = match.group(1)?.trim();
            break;
          }
        }
      }
    } catch (e) {
      // Ignore errors reading description
    }

    return ScriptInfo(
      name: name,
      filePath: file.path,
      description: description,
      enabled: true,
      lastModified: stat.modified,
      fileSize: stat.size,
    );
  }

  /// Create a copy with updated fields
  ScriptInfo copyWith({
    String? name,
    String? filePath,
    String? description,
    bool? enabled,
    DateTime? lastModified,
    int? fileSize,
  }) {
    return ScriptInfo(
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      lastModified: lastModified ?? this.lastModified,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  String toString() {
    return 'ScriptInfo(name: $name, filePath: $filePath, enabled: $enabled, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScriptInfo &&
        other.name == name &&
        other.filePath == filePath &&
        other.description == description &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        filePath.hashCode ^
        description.hashCode ^
        enabled.hashCode;
  }
}

/// Manager for user Lua scripts
///
/// This class handles:
/// - Loading scripts from files
/// - Listing available user scripts
/// - Managing the scripts directory
/// - Script metadata and organization
///
/// Scripts are stored in the app's documents directory under a 'scripts' folder.
/// Users can add custom Lua scripts to extend app functionality.
class ScriptManager {
  static final _logger = Logger('ScriptManager');

  /// Name of the scripts directory
  static const String scriptsDirectoryName = 'scripts';

  /// Get the scripts directory
  ///
  /// Returns the directory where user scripts are stored.
  /// Creates the directory if it doesn't exist.
  ///
  /// The directory is located at:
  /// - iOS/macOS: <Application Support>/scripts/
  /// - Android: <App Data>/scripts/
  /// - Linux/Windows: <Documents>/ReadWhere/scripts/
  Future<Directory> getScriptsDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final scriptsDir = Directory(p.join(appDir.path, scriptsDirectoryName));

      if (!await scriptsDir.exists()) {
        _logger.info('Creating scripts directory: ${scriptsDir.path}');
        await scriptsDir.create(recursive: true);

        // Create a README file in the directory
        await _createReadmeFile(scriptsDir);
      }

      return scriptsDir;
    } catch (e, stackTrace) {
      _logger.severe('Error getting scripts directory', e, stackTrace);
      rethrow;
    }
  }

  /// Load a script from a file
  ///
  /// Reads the contents of a Lua script file.
  ///
  /// [path] The absolute path to the script file
  /// Returns the script content as a string
  ///
  /// Throws [FileSystemException] if the file cannot be read
  Future<String> loadScript(String path) async {
    try {
      _logger.info('Loading script: $path');

      final file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('Script file not found', path);
      }

      final content = await file.readAsString();
      _logger.fine('Loaded script (${content.length} bytes): $path');

      return content;
    } catch (e, stackTrace) {
      _logger.severe('Error loading script: $path', e, stackTrace);
      rethrow;
    }
  }

  /// List all user scripts
  ///
  /// Scans the scripts directory and returns information about all
  /// Lua script files found.
  ///
  /// Returns a list of [ScriptInfo] objects, one for each script file.
  /// Returns an empty list if no scripts are found or if there's an error.
  Future<List<ScriptInfo>> listUserScripts() async {
    try {
      final scriptsDir = await getScriptsDirectory();
      _logger.info('Listing scripts in: ${scriptsDir.path}');

      final scripts = <ScriptInfo>[];

      // List all .lua files in the scripts directory
      final entities = scriptsDir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.lua')) {
          try {
            final scriptInfo = await ScriptInfo.fromFile(entity);
            scripts.add(scriptInfo);
            _logger.fine('Found script: ${scriptInfo.name}');
          } catch (e) {
            _logger.warning('Failed to load script info for: ${entity.path}', e);
          }
        }
      }

      _logger.info('Found ${scripts.length} user scripts');
      return scripts;
    } catch (e, stackTrace) {
      _logger.severe('Error listing user scripts', e, stackTrace);
      return [];
    }
  }

  /// Save a script to a file
  ///
  /// Writes script content to a file in the scripts directory.
  ///
  /// [name] The name of the script (without extension)
  /// [content] The Lua script content
  /// Returns the path to the saved file
  ///
  /// Throws [FileSystemException] if the file cannot be written
  Future<String> saveScript(String name, String content) async {
    try {
      final scriptsDir = await getScriptsDirectory();

      // Sanitize the filename
      final sanitizedName = _sanitizeFilename(name);
      final fileName = sanitizedName.endsWith('.lua')
          ? sanitizedName
          : '$sanitizedName.lua';

      final filePath = p.join(scriptsDir.path, fileName);
      final file = File(filePath);

      _logger.info('Saving script: $filePath');
      await file.writeAsString(content);

      _logger.info('Script saved successfully: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      _logger.severe('Error saving script: $name', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a script file
  ///
  /// Removes a script file from the scripts directory.
  ///
  /// [path] The absolute path to the script file
  ///
  /// Throws [FileSystemException] if the file cannot be deleted
  Future<void> deleteScript(String path) async {
    try {
      _logger.info('Deleting script: $path');

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _logger.info('Script deleted: $path');
      } else {
        _logger.warning('Script file not found: $path');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error deleting script: $path', e, stackTrace);
      rethrow;
    }
  }

  /// Check if a script file exists
  ///
  /// [path] The absolute path to check
  /// Returns true if the file exists, false otherwise
  Future<bool> scriptExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      _logger.warning('Error checking script existence: $path', e);
      return false;
    }
  }

  /// Get the default example scripts directory
  ///
  /// Returns the path to the bundled example scripts in the assets.
  /// These are read-only example scripts that users can reference.
  String getExampleScriptsPath() {
    return 'assets/scripts/';
  }

  // Private helper methods

  /// Create a README file in the scripts directory
  Future<void> _createReadmeFile(Directory scriptsDir) async {
    try {
      final readmePath = p.join(scriptsDir.path, 'README.txt');
      final readmeFile = File(readmePath);

      if (!await readmeFile.exists()) {
        const readmeContent = '''
ReadWhere User Scripts
======================

This directory contains Lua scripts that can extend the functionality
of the ReadWhere e-reader app.

Script Format:
- Scripts should be saved with a .lua extension
- Add a description comment at the top of your script:
  -- Description: What your script does

Example Script:
-- Description: Adds custom bookmark tags
-- This script demonstrates how to work with bookmarks

function addCustomTag(bookmark, tag)
  -- Your script logic here
  return bookmark
end

For more information and examples, visit:
https://github.com/readwhere/readwhere

API Documentation:
See the app documentation for available Lua bindings and APIs.
''';

        await readmeFile.writeAsString(readmeContent);
        _logger.info('Created README file in scripts directory');
      }
    } catch (e) {
      _logger.warning('Failed to create README file', e);
    }
  }

  /// Sanitize a filename by removing invalid characters
  String _sanitizeFilename(String name) {
    // Remove or replace invalid filename characters
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}
