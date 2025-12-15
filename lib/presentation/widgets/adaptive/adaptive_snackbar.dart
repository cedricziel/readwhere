import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shows a platform-appropriate notification message.
///
/// On Material platforms (Android, Web): Uses [ScaffoldMessenger.showSnackBar]
/// On macOS: Uses a custom overlay toast (no ScaffoldMessenger available)
/// On iOS: Uses a custom overlay toast
///
/// Example:
/// ```dart
/// showAdaptiveSnackBar(
///   context,
///   message: 'Book added to library',
///   action: AdaptiveSnackBarAction(
///     label: 'Undo',
///     onPressed: () => undoAction(),
///   ),
/// );
/// ```
void showAdaptiveSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 4),
  AdaptiveSnackBarAction? action,
}) {
  // macOS/iOS: Use overlay toast since there's no ScaffoldMessenger
  if (!kIsWeb && (Platform.isMacOS || Platform.isIOS)) {
    _showOverlayToast(
      context,
      message: message,
      duration: duration,
      action: action,
    );
    return;
  }

  // Material platforms: Use ScaffoldMessenger
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action != null
          ? SnackBarAction(label: action.label, onPressed: action.onPressed)
          : null,
    ),
  );
}

/// Action button for [showAdaptiveSnackBar].
class AdaptiveSnackBarAction {
  /// The label for the action button.
  final String label;

  /// Callback when the action is pressed.
  final VoidCallback onPressed;

  const AdaptiveSnackBarAction({required this.label, required this.onPressed});
}

/// Shows an overlay toast for macOS/iOS platforms.
void _showOverlayToast(
  BuildContext context, {
  required String message,
  required Duration duration,
  AdaptiveSnackBarAction? action,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  Timer? dismissTimer;

  entry = OverlayEntry(
    builder: (context) => _AdaptiveToast(
      message: message,
      action: action,
      onDismiss: () {
        dismissTimer?.cancel();
        entry.remove();
      },
    ),
  );

  overlay.insert(entry);

  // Auto-dismiss after duration
  dismissTimer = Timer(duration, () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

/// A toast widget for macOS/iOS platforms.
class _AdaptiveToast extends StatefulWidget {
  final String message;
  final AdaptiveSnackBarAction? action;
  final VoidCallback onDismiss;

  const _AdaptiveToast({
    required this.message,
    this.action,
    required this.onDismiss,
  });

  @override
  State<_AdaptiveToast> createState() => _AdaptiveToastState();
}

class _AdaptiveToastState extends State<_AdaptiveToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (widget.action != null) ...[
                          const SizedBox(width: 16),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            // ignore: deprecated_member_use
                            minSize: 0,
                            onPressed: () {
                              widget.action!.onPressed();
                              _dismiss();
                            },
                            child: Text(
                              widget.action!.label,
                              style: const TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          // ignore: deprecated_member_use
                          minSize: 0,
                          onPressed: _dismiss,
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.systemGrey,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
