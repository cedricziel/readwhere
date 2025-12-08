import 'package:lua_dardo_co/lua.dart';
import 'package:logging/logging.dart';
import '../../presentation/providers/reader_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../lua_engine.dart';

/// Lua bindings for reader functionality
///
/// This class provides Lua script access to reader operations and data.
/// It registers functions that can be called from Lua scripts to:
/// - Get information about the currently open book
/// - Get and set reading progress
/// - Manage bookmarks
/// - Navigate between chapters
/// - Access and modify reading settings
///
/// Example Lua usage:
/// ```lua
/// -- Get current book info
/// local book = getCurrentBook()
/// print("Reading: " .. book.title)
///
/// -- Get reading progress
/// local progress = getProgress()
/// print("Progress: " .. progress.percentage .. "%")
///
/// -- Add a bookmark
/// addBookmark("Important chapter")
///
/// -- Navigate to chapter
/// goToChapter(3)
///
/// -- Update font size
/// local settings = getSettings()
/// settings.fontSize = 18
/// setSettings(settings)
/// ```
class ReaderBindings {
  static final _logger = Logger('ReaderBindings');

  final LuaEngine _luaEngine;
  final ReaderProvider _readerProvider;
  final SettingsProvider _settingsProvider;

  ReaderBindings({
    required LuaEngine luaEngine,
    required ReaderProvider readerProvider,
    required SettingsProvider settingsProvider,
  }) : _luaEngine = luaEngine,
       _readerProvider = readerProvider,
       _settingsProvider = settingsProvider;

  /// Register all reader bindings with the Lua engine
  ///
  /// This should be called after the Lua engine is initialized
  /// and before executing any user scripts.
  void registerBindings() {
    _logger.info('Registering reader bindings');

    try {
      // Book information
      _luaEngine.registerFunction('getCurrentBook', _getCurrentBook);

      // Progress management
      _luaEngine.registerFunction('getProgress', _getProgress);
      _luaEngine.registerFunction('setProgress', _setProgress);

      // Bookmark management
      _luaEngine.registerFunction('addBookmark', _addBookmark);
      _luaEngine.registerFunction('getBookmarks', _getBookmarks);
      _luaEngine.registerFunction('removeBookmark', _removeBookmark);

      // Navigation
      _luaEngine.registerFunction('goToChapter', _goToChapter);
      _luaEngine.registerFunction('nextChapter', _nextChapter);
      _luaEngine.registerFunction('previousChapter', _previousChapter);

      // Settings
      _luaEngine.registerFunction('getSettings', _getSettings);
      _luaEngine.registerFunction('setSettings', _setSettings);

      // Table of contents
      _luaEngine.registerFunction('getTableOfContents', _getTableOfContents);

      _logger.info('Reader bindings registered successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error registering reader bindings', e, stackTrace);
      rethrow;
    }
  }

  // Book information functions

  /// Get information about the currently open book
  ///
  /// Returns a Lua table with book information or nil if no book is open.
  /// Table structure:
  /// - id: string
  /// - title: string
  /// - author: string
  /// - filePath: string
  /// - format: string
  int _getCurrentBook(LuaState state) {
    try {
      final book = _readerProvider.currentBook;

      if (book == null) {
        state.pushNil();
        return 1;
      }

      // Create a table with book information
      state.newTable();

      // Set book fields
      _setTableField(state, 'id', book.id);
      _setTableField(state, 'title', book.title);
      _setTableField(state, 'author', book.author);
      _setTableField(state, 'filePath', book.filePath);
      _setTableField(state, 'format', book.format);

      return 1;
    } catch (e) {
      _logger.severe('Error in getCurrentBook', e);
      state.pushString('Error: ${e.toString()}');
      state.error();
      return 0;
    }
  }

  // Progress functions

  /// Get the current reading progress
  ///
  /// Returns a Lua table with progress information or nil if no book is open.
  /// Table structure:
  /// - cfi: string (current location)
  /// - progress: number (0.0 to 1.0)
  /// - percentage: number (0 to 100)
  /// - currentChapter: number
  int _getProgress(LuaState state) {
    try {
      final progress = _readerProvider.progress;
      final currentChapter = _readerProvider.currentChapterIndex;

      if (progress == null) {
        state.pushNil();
        return 1;
      }

      // Create a table with progress information
      state.newTable();

      _setTableField(state, 'cfi', progress.cfi);
      _setTableField(state, 'progress', progress.progress);
      _setTableField(state, 'percentage', progress.progress * 100);
      _setTableField(state, 'currentChapter', currentChapter);

      return 1;
    } catch (e) {
      _logger.severe('Error in getProgress', e);
      state.pushString('Error: ${e.toString()}');
      state.error();
      return 0;
    }
  }

  /// Set the reading progress
  ///
  /// Arguments:
  /// 1. cfi (string): The new location
  /// 2. progress (number): The progress value (0.0 to 1.0)
  ///
  /// Returns true if successful, false otherwise
  int _setProgress(LuaState state) {
    try {
      // Get arguments
      if (state.getTop() < 2) {
        state.pushBoolean(false);
        return 1;
      }

      final cfi = state.toStr(1) ?? '';
      final progress = state.toNumber(2);

      // Validate progress value
      final clampedProgress = progress.clamp(0.0, 1.0);

      // Update progress (async operation, but Lua binding is sync)
      _readerProvider.updateProgressWhileReading(cfi, clampedProgress);
      _readerProvider.saveProgress(); // Fire and forget

      state.pushBoolean(true);
      return 1;
    } catch (e) {
      _logger.severe('Error in setProgress', e);
      state.pushBoolean(false);
      return 1;
    }
  }

  // Bookmark functions

  /// Add a bookmark at the current location
  ///
  /// Arguments:
  /// 1. title (string): The bookmark title
  ///
  /// Returns the bookmark ID if successful, nil otherwise
  int _addBookmark(LuaState state) {
    try {
      final title = state.toStr(1) ?? 'Untitled Bookmark';

      // Note: This is an async operation, but Lua bindings are sync
      // We'll trigger the operation and return immediately
      _readerProvider.addBookmark(title).then((bookmark) {
        if (bookmark == null) {
          _logger.warning('Failed to add bookmark: $title');
        }
      });

      // Push the bookmark title as confirmation
      // In a real implementation, you might want to use a callback mechanism
      state.pushString(title);
      return 1;
    } catch (e) {
      _logger.severe('Error in addBookmark', e);
      state.pushNil();
      return 1;
    }
  }

  /// Get all bookmarks for the current book
  ///
  /// Returns a Lua array of bookmark tables or empty array if no bookmarks.
  /// Each bookmark table contains:
  /// - id: string
  /// - title: string
  /// - cfi: string
  /// - chapterId: string (optional)
  /// - createdAt: number (timestamp)
  int _getBookmarks(LuaState state) {
    try {
      final bookmarks = _readerProvider.bookmarks;

      // Create array table
      state.newTable();

      for (var i = 0; i < bookmarks.length; i++) {
        final bookmark = bookmarks[i];

        // Create bookmark table
        state.pushInteger(i + 1); // Lua arrays are 1-indexed
        state.newTable();

        _setTableField(state, 'id', bookmark.id);
        _setTableField(state, 'title', bookmark.title);
        _setTableField(state, 'cfi', bookmark.cfi);

        if (bookmark.chapterId != null) {
          _setTableField(state, 'chapterId', bookmark.chapterId!);
        }

        _setTableField(
          state,
          'createdAt',
          bookmark.createdAt.millisecondsSinceEpoch / 1000,
        );

        state.setTable(-3);
      }

      return 1;
    } catch (e) {
      _logger.severe('Error in getBookmarks', e);
      state.newTable(); // Return empty array
      return 1;
    }
  }

  /// Remove a bookmark by ID
  ///
  /// Arguments:
  /// 1. id (string): The bookmark ID to remove
  ///
  /// Returns true if successful, false otherwise
  int _removeBookmark(LuaState state) {
    try {
      final id = state.toStr(1) ?? '';

      if (id.isEmpty) {
        state.pushBoolean(false);
        return 1;
      }

      // Note: Async operation
      _readerProvider.removeBookmark(id).then((success) {
        if (!success) {
          _logger.warning('Failed to remove bookmark: $id');
        }
      });

      state.pushBoolean(true);
      return 1;
    } catch (e) {
      _logger.severe('Error in removeBookmark', e);
      state.pushBoolean(false);
      return 1;
    }
  }

  // Navigation functions

  /// Navigate to a specific chapter
  ///
  /// Arguments:
  /// 1. index (number): The chapter index (0-based)
  ///
  /// Returns true if successful, false otherwise
  int _goToChapter(LuaState state) {
    try {
      final index = state.toInteger(1);

      if (index < 0) {
        state.pushBoolean(false);
        return 1;
      }

      // Note: Async operation
      _readerProvider.goToChapter(index);

      state.pushBoolean(true);
      return 1;
    } catch (e) {
      _logger.severe('Error in goToChapter', e);
      state.pushBoolean(false);
      return 1;
    }
  }

  /// Navigate to the next chapter
  ///
  /// Returns true if successful, false otherwise
  int _nextChapter(LuaState state) {
    try {
      _readerProvider.nextChapter();
      state.pushBoolean(true);
      return 1;
    } catch (e) {
      _logger.severe('Error in nextChapter', e);
      state.pushBoolean(false);
      return 1;
    }
  }

  /// Navigate to the previous chapter
  ///
  /// Returns true if successful, false otherwise
  int _previousChapter(LuaState state) {
    try {
      _readerProvider.previousChapter();
      state.pushBoolean(true);
      return 1;
    } catch (e) {
      _logger.severe('Error in previousChapter', e);
      state.pushBoolean(false);
      return 1;
    }
  }

  // Settings functions

  /// Get current reading settings
  ///
  /// Returns a Lua table with settings or nil if not available.
  /// Table structure:
  /// - fontSize: number
  /// - fontFamily: string
  /// - lineHeight: number
  /// - marginHorizontal: number
  /// - marginVertical: number
  /// - theme: string ("light", "dark", "sepia")
  int _getSettings(LuaState state) {
    try {
      final settings = _settingsProvider.defaultReadingSettings;

      state.newTable();

      _setTableField(state, 'fontSize', settings.fontSize);
      _setTableField(state, 'fontFamily', settings.fontFamily);
      _setTableField(state, 'lineHeight', settings.lineHeight);
      _setTableField(state, 'marginHorizontal', settings.marginHorizontal);
      _setTableField(state, 'marginVertical', settings.marginVertical);
      _setTableField(state, 'theme', _getThemeName(settings.theme));

      return 1;
    } catch (e) {
      _logger.severe('Error in getSettings', e);
      state.pushNil();
      return 1;
    }
  }

  /// Set reading settings
  ///
  /// Arguments:
  /// 1. settings (table): A table with settings to update
  ///
  /// Supported fields:
  /// - fontSize: number
  /// - fontFamily: string
  /// - lineHeight: number
  /// - marginHorizontal: number
  /// - marginVertical: number
  ///
  /// Returns true if successful, false otherwise
  int _setSettings(LuaState state) {
    try {
      if (!state.isTable(1)) {
        state.pushBoolean(false);
        return 1;
      }

      // Update fontSize if provided
      state.getField(1, 'fontSize');
      if (state.isNumber(-1)) {
        _settingsProvider.setFontSize(state.toNumber(-1));
      }
      state.pop(1);

      // Update fontFamily if provided
      state.getField(1, 'fontFamily');
      if (state.isString(-1)) {
        final fontFamily = state.toStr(-1);
        if (fontFamily != null) {
          _settingsProvider.setFontFamily(fontFamily);
        }
      }
      state.pop(1);

      // Update lineHeight if provided
      state.getField(1, 'lineHeight');
      if (state.isNumber(-1)) {
        _settingsProvider.setLineHeight(state.toNumber(-1));
      }
      state.pop(1);

      // Update marginHorizontal if provided
      state.getField(1, 'marginHorizontal');
      if (state.isNumber(-1)) {
        _settingsProvider.setMarginHorizontal(state.toNumber(-1));
      }
      state.pop(1);

      // Update marginVertical if provided
      state.getField(1, 'marginVertical');
      if (state.isNumber(-1)) {
        _settingsProvider.setMarginVertical(state.toNumber(-1));
      }
      state.pop(1);

      state.pushBoolean(true);
      return 1;
    } catch (e) {
      _logger.severe('Error in setSettings', e);
      state.pushBoolean(false);
      return 1;
    }
  }

  /// Get the table of contents
  ///
  /// Returns a Lua array of chapter tables or empty array.
  /// Each chapter table contains:
  /// - id: string
  /// - title: string
  /// - href: string
  /// - level: number
  int _getTableOfContents(LuaState state) {
    try {
      final toc = _readerProvider.tableOfContents;

      // Create array table
      state.newTable();

      for (var i = 0; i < toc.length; i++) {
        final entry = toc[i];

        state.pushInteger(i + 1); // Lua arrays are 1-indexed
        state.newTable();

        _setTableField(state, 'id', entry.id);
        _setTableField(state, 'title', entry.title);
        _setTableField(state, 'href', entry.href);
        _setTableField(state, 'level', entry.level);

        state.setTable(-3);
      }

      return 1;
    } catch (e) {
      _logger.severe('Error in getTableOfContents', e);
      state.newTable(); // Return empty array
      return 1;
    }
  }

  // Helper methods

  /// Set a field in a Lua table at the top of the stack
  void _setTableField(LuaState state, String key, dynamic value) {
    state.pushString(key);

    if (value is String) {
      state.pushString(value);
    } else if (value is int) {
      state.pushInteger(value);
    } else if (value is double) {
      state.pushNumber(value);
    } else if (value is bool) {
      state.pushBoolean(value);
    } else {
      state.pushNil();
    }

    state.setTable(-3);
  }

  /// Get the theme name as a string
  String _getThemeName(dynamic theme) {
    // Assuming ReadingTheme enum has toString() or name property
    return theme.toString().split('.').last;
  }
}
