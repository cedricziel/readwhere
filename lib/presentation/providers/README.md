# State Management Providers

This directory contains the state management providers for the readwhere Flutter e-reader app, implemented using the Provider package with ChangeNotifier.

## Overview

All providers extend `ChangeNotifier` and use `notifyListeners()` to update the UI when state changes. Dependencies are injected via GetIt service locator (configured in `/lib/core/di/service_locator.dart`).

## Providers

### 1. LibraryProvider (`library_provider.dart`)

Manages the book library state and operations.

#### State Properties
- `List<Book> books` - Filtered/sorted books list
- `bool isLoading` - Loading state indicator
- `String? error` - Error message if operation failed
- `LibrarySortOrder sortOrder` - Current sort order
- `LibraryViewMode viewMode` - Current view mode (grid/list)
- `String searchQuery` - Current search query
- `int bookCount` - Total number of books
- `int favoriteCount` - Number of favorite books

#### Enums
```dart
enum LibrarySortOrder {
  recentlyAdded,    // Recently added books first
  recentlyOpened,   // Recently opened books first
  title,            // Alphabetical by title
  author,           // Alphabetical by author
}

enum LibraryViewMode {
  grid,  // Grid view with book covers
  list,  // List view with book details
}
```

#### Key Methods
- `loadLibrary()` / `loadBooks()` - Load all books from repository
- `importBook(String filePath)` - Import a new book from file
- `deleteBook(String id)` - Delete a book and associated data
- `toggleFavorite(String id)` - Toggle favorite status
- `setSortOrder(LibrarySortOrder order)` - Change sort order
- `setViewMode(LibraryViewMode mode)` - Change view mode
- `search(String query)` / `searchBooks(String query)` - Search books
- `getFilteredBooks()` - Get current filtered book list
- `clearSearch()` - Clear search and show all books

#### Dependencies
- `BookRepository` (from domain layer)

---

### 2. ReaderProvider (`reader_provider.dart`)

Manages the reading experience state and operations.

#### State Properties
- `Book? currentBook` - Currently open book
- `ReadingProgress? progress` - Current reading progress
- `List<Bookmark> bookmarks` - Bookmarks for current book
- `ReadingSettings settings` - Current reading settings
- `bool isLoading` - Loading state indicator
- `String? error` - Error message
- `int currentChapterIndex` - Current chapter index
- `List<TocEntry> tableOfContents` - Table of contents
- `bool hasOpenBook` - Whether a book is currently open
- `double progressPercentage` - Progress as percentage (0-100)

#### Key Methods
- `openBook(Book book)` - Open a book for reading
- `closeBook()` - Close the current book (saves progress)
- `goToChapter(int index)` - Navigate to specific chapter
- `goToLocation(String cfi)` - Navigate to specific location (CFI)
- `nextChapter()` - Navigate to next chapter
- `previousChapter()` - Navigate to previous chapter
- `saveProgress()` - Save current reading progress
- `addBookmark(String title)` - Add bookmark at current location
- `removeBookmark(String id)` - Remove a bookmark
- `goToBookmark(Bookmark bookmark)` - Navigate to bookmark
- `updateSettings(ReadingSettings settings)` - Update reading settings
- `updateProgressWhileReading(String cfi, double progress)` - Update progress while reading
- `clearError()` - Clear error messages

#### Dependencies
- `ReadingProgressRepository` (from domain layer)
- `BookmarkRepository` (from domain layer)

---

### 3. SettingsProvider (`settings_provider.dart`)

Manages application settings with persistence to SharedPreferences.

#### State Properties
- `ThemeMode themeMode` - App theme mode (light/dark/system)
- `ReadingSettings defaultReadingSettings` - Default reading settings
- `String booksDirectory` - Books storage directory path
- `bool syncEnabled` - Whether sync is enabled
- `bool hapticFeedback` - Whether haptic feedback is enabled
- `bool keepScreenAwake` - Whether to keep screen awake during reading
- `bool isInitialized` - Whether settings have been loaded

#### Key Methods

##### Initialization
- `initialize()` - Initialize provider and load settings from storage (call at app startup)

##### Theme Settings
- `setThemeMode(ThemeMode mode)` - Set app theme mode
- `resetToDefaults()` - Reset all settings to defaults

##### Reading Settings
- `updateReadingSettings(ReadingSettings settings)` - Update all reading settings
- `setFontSize(double fontSize)` - Set font size
- `setFontFamily(String fontFamily)` - Set font family
- `setLineHeight(double lineHeight)` - Set line height
- `setMarginHorizontal(double margin)` - Set horizontal margin
- `setMarginVertical(double margin)` - Set vertical margin
- `setReadingTheme(ReadingTheme theme)` - Set reading theme (light/dark/sepia)
- `setTextAlign(TextAlign alignment)` - Set text alignment

##### Other Settings
- `setBooksDirectory(String directory)` - Set books storage directory
- `setSyncEnabled(bool enabled)` - Enable/disable sync
- `toggleHapticFeedback()` - Toggle haptic feedback on/off
- `setHapticFeedback(bool enabled)` - Set haptic feedback state
- `toggleKeepScreenAwake()` - Toggle keep screen awake on/off
- `setKeepScreenAwake(bool enabled)` - Set keep screen awake state

#### Persistence
All settings are automatically persisted to SharedPreferences and loaded on initialization.

---

### 4. ThemeProvider (`theme_provider.dart`)

Simplified theme provider focused on app theme mode management.

#### State Properties
- `ThemeMode themeMode` - Current theme mode
- `bool isInitialized` - Whether theme has been loaded
- `bool isLightMode` - Whether current mode is light
- `bool isDarkMode` - Whether current mode is dark
- `bool isSystemMode` - Whether current mode is system

#### Key Methods
- `initialize()` - Initialize and load theme from storage
- `setLightMode()` - Set theme to light mode
- `setDarkMode()` - Set theme to dark mode
- `setSystemMode()` - Set theme to follow system
- `toggleTheme({Brightness? brightness})` - Toggle between light/dark
- `setThemeMode(ThemeMode mode)` - Set specific theme mode
- `getEffectiveBrightness(Brightness systemBrightness)` - Get effective brightness

---

## Usage Example

### Setting up providers at app startup

```dart
import 'package:provider/provider.dart';
import 'package:readwhere/core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await setupServiceLocator();

  // Initialize settings
  await sl<SettingsProvider>().initialize();
  await sl<ThemeProvider>().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => sl<SettingsProvider>()),
        ChangeNotifierProvider(create: (_) => sl<LibraryProvider>()),
        ChangeNotifierProvider(create: (_) => sl<ReaderProvider>()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ReadWhere',
            themeMode: themeProvider.themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const LibraryScreen(),
          );
        },
      ),
    );
  }
}
```

### Using providers in widgets

```dart
// Library Screen Example
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Load library on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          // View mode toggle
          Consumer<LibraryProvider>(
            builder: (context, library, child) {
              return IconButton(
                icon: Icon(
                  library.viewMode == LibraryViewMode.grid
                      ? Icons.list
                      : Icons.grid_view,
                ),
                onPressed: () {
                  library.setViewMode(
                    library.viewMode == LibraryViewMode.grid
                        ? LibraryViewMode.list
                        : LibraryViewMode.grid,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, library, child) {
          if (library.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (library.error != null) {
            return Center(child: Text('Error: ${library.error}'));
          }

          final books = library.getFilteredBooks();

          if (books.isEmpty) {
            return const Center(child: Text('No books in library'));
          }

          return library.viewMode == LibraryViewMode.grid
              ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) => BookGridItem(book: books[index]),
                )
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) => BookListItem(book: books[index]),
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Import book
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['epub', 'pdf'],
          );

          if (result != null && result.files.single.path != null) {
            await context.read<LibraryProvider>().importBook(
              result.files.single.path!,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Reader Screen Example
class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    // Open book on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderProvider>().openBook(widget.book);
    });
  }

  @override
  void dispose() {
    // Close book when leaving screen
    context.read<ReaderProvider>().closeBook();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ReaderProvider>(
          builder: (context, reader, child) {
            return Text(reader.currentBook?.title ?? 'Reading');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: () async {
              final title = await _showBookmarkDialog(context);
              if (title != null) {
                context.read<ReaderProvider>().addBookmark(title);
              }
            },
          ),
        ],
      ),
      body: Consumer<ReaderProvider>(
        builder: (context, reader, child) {
          if (reader.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!reader.hasOpenBook) {
            return const Center(child: Text('No book open'));
          }

          return Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: reader.progress?.progress ?? 0.0,
              ),
              // Book content (would use actual EPUB renderer here)
              Expanded(
                child: Center(
                  child: Text('Book content at ${reader.progress?.cfi}'),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ReaderProvider>(
        builder: (context, reader, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: reader.currentChapterIndex > 0
                    ? () => reader.previousChapter()
                    : null,
              ),
              Text(
                'Chapter ${reader.currentChapterIndex + 1} of ${reader.tableOfContents.length}',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: reader.currentChapterIndex < reader.tableOfContents.length - 1
                    ? () => reader.nextChapter()
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _showBookmarkDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Bookmark'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Bookmark Title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

// Settings Screen Example
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Theme mode
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeText(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context),
              );
            },
          ),

          // Haptic feedback
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SwitchListTile(
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate on interactions'),
                value: settings.hapticFeedback,
                onChanged: (_) => settings.toggleHapticFeedback(),
              );
            },
          ),

          // Keep screen awake
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return SwitchListTile(
                title: const Text('Keep Screen Awake'),
                subtitle: const Text('Prevent screen from sleeping while reading'),
                value: settings.keepScreenAwake,
                onChanged: (_) => settings.toggleKeepScreenAwake(),
              );
            },
          ),

          // Font size
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return ListTile(
                title: const Text('Font Size'),
                subtitle: Slider(
                  value: settings.defaultReadingSettings.fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 12,
                  label: settings.defaultReadingSettings.fontSize.toString(),
                  onChanged: (value) => settings.setFontSize(value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context) {
    // Theme selection dialog implementation
  }
}
```

## Error Handling

All providers implement consistent error handling:

1. Errors are captured and stored in the `error` property
2. The error is exposed via a getter for UI display
3. Loading states are set appropriately during async operations
4. Previous data is preserved when operations fail
5. Users can retry operations after errors

Example error handling in UI:

```dart
Consumer<LibraryProvider>(
  builder: (context, library, child) {
    if (library.error != null) {
      return ErrorWidget(
        error: library.error!,
        onRetry: () => library.loadLibrary(),
      );
    }
    // ... normal UI
  },
)
```

## Testing

Providers are designed to be easily testable:

```dart
void main() {
  late LibraryProvider provider;
  late MockBookRepository mockRepository;

  setUp(() {
    mockRepository = MockBookRepository();
    provider = LibraryProvider(bookRepository: mockRepository);
  });

  test('loadLibrary loads books successfully', () async {
    // Arrange
    final books = [
      Book(id: '1', title: 'Test Book', /* ... */),
    ];
    when(mockRepository.getAll()).thenAnswer((_) async => books);

    // Act
    await provider.loadLibrary();

    // Assert
    expect(provider.books, equals(books));
    expect(provider.isLoading, false);
    expect(provider.error, null);
  });

  test('loadLibrary handles errors', () async {
    // Arrange
    when(mockRepository.getAll()).thenThrow(Exception('Database error'));

    // Act
    await provider.loadLibrary();

    // Assert
    expect(provider.books, isEmpty);
    expect(provider.error, contains('Failed to load books'));
    expect(provider.isLoading, false);
  });
}
```

## Best Practices

1. **Always initialize providers** - Call `initialize()` on SettingsProvider and ThemeProvider at app startup
2. **Use Consumer wisely** - Only wrap parts of the widget tree that need to rebuild
3. **Selector for performance** - Use `Selector` instead of `Consumer` when only specific fields need to trigger rebuilds
4. **Clean up** - Close books and save progress when disposing reader screens
5. **Error handling** - Always display errors to users and provide retry mechanisms
6. **Loading states** - Show loading indicators during async operations
7. **Debounce search** - Consider debouncing search input to avoid excessive queries

## Files

- `/lib/presentation/providers/library_provider.dart` - Library state management
- `/lib/presentation/providers/reader_provider.dart` - Reader state management
- `/lib/presentation/providers/settings_provider.dart` - Settings state management
- `/lib/presentation/providers/theme_provider.dart` - Theme state management
- `/lib/core/di/service_locator.dart` - Dependency injection setup
