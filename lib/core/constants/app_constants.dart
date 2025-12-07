/// App-wide constants for the readwhere e-reader application.
///
/// This file contains all constant values used throughout the app
/// including database names, version info, and other configuration.
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Information
  static const String appName = 'ReadWhere';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Database
  static const String databaseName = 'readwhere.db';
  static const int databaseVersion = 1;

  // Directories
  static const String booksDirectory = 'books';
  static const String coversDirectory = 'covers';
  static const String tempDirectory = 'temp';

  // File Formats
  static const List<String> supportedBookFormats = [
    'epub',
    'pdf',
    'mobi',
    'azw',
    'azw3',
  ];

  // Reading Preferences Defaults
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 10.0;
  static const double maxFontSize = 32.0;
  static const String defaultFontFamily = 'Roboto';
  static const double defaultLineHeight = 1.5;
  static const int defaultThemeMode = 0; // 0: system, 1: light, 2: dark

  // Pagination
  static const int booksPerPage = 20;
  static const int searchResultsLimit = 50;

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double coverAspectRatio = 2 / 3;

  // Cache
  static const int maxCachedBooks = 10;
  static const int cacheExpirationDays = 7;

  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 400;
  static const int longAnimationDuration = 600;

  // API & Sync (for future use)
  static const String apiBaseUrl = '';
  static const int apiTimeoutSeconds = 30;

  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String fileNotFoundMessage = 'File not found.';
  static const String unsupportedFormatMessage = 'Unsupported file format.';
}
