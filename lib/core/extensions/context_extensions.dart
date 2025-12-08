import 'package:flutter/material.dart';

/// Extension methods for BuildContext.
///
/// Provides convenient accessors for commonly used context-dependent
/// properties like theme, colors, text styles, and screen dimensions.
extension ContextExtensions on BuildContext {
  /// Returns the current [ThemeData] from the context.
  ///
  /// Example:
  /// ```dart
  /// final theme = context.theme;
  /// final primaryColor = context.theme.primaryColor;
  /// ```
  ThemeData get theme => Theme.of(this);

  /// Returns the current [ColorScheme] from the context.
  ///
  /// Example:
  /// ```dart
  /// final colorScheme = context.colorScheme;
  /// final primary = context.colorScheme.primary;
  /// ```
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns the current [TextTheme] from the context.
  ///
  /// Example:
  /// ```dart
  /// final textTheme = context.textTheme;
  /// final headline = context.textTheme.headlineMedium;
  /// ```
  TextTheme get textTheme => theme.textTheme;

  /// Returns the screen size from MediaQuery.
  ///
  /// Example:
  /// ```dart
  /// final size = context.screenSize;
  /// final width = context.screenSize.width;
  /// ```
  Size get screenSize => MediaQuery.of(this).size;

  /// Returns the screen width.
  ///
  /// Example:
  /// ```dart
  /// final width = context.screenWidth;
  /// ```
  double get screenWidth => screenSize.width;

  /// Returns the screen height.
  ///
  /// Example:
  /// ```dart
  /// final height = context.screenHeight;
  /// ```
  double get screenHeight => screenSize.height;

  /// Returns the current device pixel ratio.
  ///
  /// Example:
  /// ```dart
  /// final pixelRatio = context.devicePixelRatio;
  /// ```
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Returns the current text scaler.
  ///
  /// Example:
  /// ```dart
  /// final textScaler = context.textScaler;
  /// ```
  TextScaler get textScaler => MediaQuery.of(this).textScaler;

  /// Returns the safe area padding (notch, status bar, etc.).
  ///
  /// Example:
  /// ```dart
  /// final padding = context.viewPadding;
  /// final topPadding = context.viewPadding.top;
  /// ```
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;

  /// Returns the current device orientation.
  ///
  /// Example:
  /// ```dart
  /// final orientation = context.orientation;
  /// if (context.orientation == Orientation.landscape) {
  ///   // Handle landscape layout
  /// }
  /// ```
  Orientation get orientation => MediaQuery.of(this).orientation;

  /// Returns true if the device is in landscape mode.
  ///
  /// Example:
  /// ```dart
  /// if (context.isLandscape) {
  ///   // Show landscape layout
  /// }
  /// ```
  bool get isLandscape => orientation == Orientation.landscape;

  /// Returns true if the device is in portrait mode.
  ///
  /// Example:
  /// ```dart
  /// if (context.isPortrait) {
  ///   // Show portrait layout
  /// }
  /// ```
  bool get isPortrait => orientation == Orientation.portrait;

  /// Returns true if the screen width is greater than or equal to 1200px (desktop).
  ///
  /// Example:
  /// ```dart
  /// if (context.isDesktop) {
  ///   // Show desktop layout
  /// }
  /// ```
  bool get isDesktop => screenWidth >= 1200;

  /// Returns true if the screen width is between 600px and 1200px (tablet).
  ///
  /// Example:
  /// ```dart
  /// if (context.isTablet) {
  ///   // Show tablet layout
  /// }
  /// ```
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Returns true if the screen width is less than 600px (mobile).
  ///
  /// Example:
  /// ```dart
  /// if (context.isMobile) {
  ///   // Show mobile layout
  /// }
  /// ```
  bool get isMobile => screenWidth < 600;

  /// Returns true if dark mode is currently active.
  ///
  /// Example:
  /// ```dart
  /// if (context.isDarkMode) {
  ///   // Apply dark mode specific styling
  /// }
  /// ```
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Returns true if light mode is currently active.
  ///
  /// Example:
  /// ```dart
  /// if (context.isLightMode) {
  ///   // Apply light mode specific styling
  /// }
  /// ```
  bool get isLightMode => theme.brightness == Brightness.light;

  /// Returns the keyboard height when visible.
  ///
  /// Example:
  /// ```dart
  /// final keyboardHeight = context.keyboardHeight;
  /// ```
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  /// Returns true if the keyboard is currently visible.
  ///
  /// Example:
  /// ```dart
  /// if (context.isKeyboardVisible) {
  ///   // Adjust UI for keyboard
  /// }
  /// ```
  bool get isKeyboardVisible => keyboardHeight > 0;

  /// Shows a SnackBar with the given message.
  ///
  /// [message] is the text to display in the SnackBar.
  /// [duration] is how long the SnackBar should be shown.
  /// [action] is an optional action button.
  ///
  /// Example:
  /// ```dart
  /// context.showSnackBar('Book added to library');
  /// context.showSnackBar(
  ///   'Error occurred',
  ///   duration: Duration(seconds: 5),
  ///   action: SnackBarAction(label: 'Retry', onPressed: () {}),
  /// );
  /// ```
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
  }

  /// Shows an error SnackBar with the given message.
  ///
  /// [message] is the error text to display.
  /// [duration] is how long the SnackBar should be shown.
  ///
  /// Example:
  /// ```dart
  /// context.showErrorSnackBar('Failed to load book');
  /// ```
  void showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: colorScheme.error,
      ),
    );
  }

  /// Shows a success SnackBar with the given message.
  ///
  /// [message] is the success text to display.
  /// [duration] is how long the SnackBar should be shown.
  ///
  /// Example:
  /// ```dart
  /// context.showSuccessSnackBar('Book saved successfully');
  /// ```
  void showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Closes the current screen and pops the navigation stack.
  ///
  /// [result] is an optional value to return to the previous screen.
  ///
  /// Example:
  /// ```dart
  /// context.pop();
  /// context.pop(result: selectedBook);
  /// ```
  void pop<T>({T? result}) {
    Navigator.of(this).pop(result);
  }

  /// Navigates to a new screen.
  ///
  /// [route] is the route to navigate to.
  ///
  /// Example:
  /// ```dart
  /// context.push(MaterialPageRoute(builder: (_) => BookDetailsScreen()));
  /// ```
  Future<T?> push<T>(Route<T> route) {
    return Navigator.of(this).push(route);
  }

  /// Replaces the current screen with a new one.
  ///
  /// [route] is the route to replace the current route with.
  ///
  /// Example:
  /// ```dart
  /// context.pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
  /// ```
  Future<T?> pushReplacement<T, TO>(Route<T> route, {TO? result}) {
    return Navigator.of(this).pushReplacement(route, result: result);
  }

  /// Requests focus for the given FocusNode.
  ///
  /// [node] is the FocusNode to request focus for.
  ///
  /// Example:
  /// ```dart
  /// context.requestFocus(myFocusNode);
  /// ```
  void requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }

  /// Removes focus from the current focused widget.
  ///
  /// Example:
  /// ```dart
  /// context.unfocus();
  /// ```
  void unfocus() {
    FocusScope.of(this).unfocus();
  }
}
