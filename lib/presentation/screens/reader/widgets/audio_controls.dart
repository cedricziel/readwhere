import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/audio_provider.dart';

/// Floating audio controls bar for EPUB media overlay playback.
///
/// This widget displays when a chapter has media overlays and provides:
/// - Play/pause toggle
/// - Progress slider with time display
/// - Skip forward/backward buttons
/// - Playback speed selector
class AudioControls extends StatelessWidget {
  /// Whether the controls should be visible.
  final bool visible;

  /// Callback when the controls are dismissed.
  final VoidCallback? onDismiss;

  const AudioControls({super.key, this.visible = true, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // Don't show if no media overlay or not visible
        if (!audioProvider.hasMediaOverlay || !visible) {
          return const SizedBox.shrink();
        }

        return AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 200),
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _AudioControlsContent(
              audioProvider: audioProvider,
              onDismiss: onDismiss,
            ),
          ),
        );
      },
    );
  }
}

class _AudioControlsContent extends StatelessWidget {
  final AudioProvider audioProvider;
  final VoidCallback? onDismiss;

  const _AudioControlsContent({required this.audioProvider, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider and time
          _buildProgressRow(context),
          const SizedBox(height: 8),

          // Main controls row
          _buildControlsRow(context),
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Current time
        SizedBox(
          width: 48,
          child: Text(
            _formatDuration(audioProvider.position),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),

        // Progress slider
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: audioProvider.progress,
              onChanged: (value) {
                audioProvider.seekToProgress(value);
              },
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
        ),

        // Total duration
        SizedBox(
          width: 48,
          child: Text(
            _formatDuration(audioProvider.duration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speed selector
        _SpeedButton(
          currentSpeed: audioProvider.playbackSpeed,
          onSpeedChanged: (speed) => audioProvider.setSpeed(speed),
        ),

        // Skip backward 10s
        IconButton(
          icon: const Icon(Icons.replay_10),
          iconSize: 28,
          color: colorScheme.onSurface,
          onPressed: () => audioProvider.skipBackward(),
          tooltip: 'Skip back 10 seconds',
        ),

        // Play/Pause button
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            iconSize: 32,
            color: colorScheme.onPrimary,
            onPressed: () => audioProvider.togglePlayPause(),
            tooltip: audioProvider.isPlaying ? 'Pause' : 'Play',
          ),
        ),

        // Skip forward 10s
        IconButton(
          icon: const Icon(Icons.forward_10),
          iconSize: 28,
          color: colorScheme.onSurface,
          onPressed: () => audioProvider.skipForward(),
          tooltip: 'Skip forward 10 seconds',
        ),

        // Close/dismiss button
        IconButton(
          icon: const Icon(Icons.close),
          iconSize: 24,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          onPressed: onDismiss,
          tooltip: 'Close audio controls',
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Button for selecting playback speed.
class _SpeedButton extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  const _SpeedButton({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<double>(
      initialValue: currentSpeed,
      onSelected: onSpeedChanged,
      tooltip: 'Playback speed',
      offset: const Offset(0, -200),
      itemBuilder: (context) => _speeds.map((speed) {
        final isSelected = (currentSpeed - speed).abs() < 0.01;
        return PopupMenuItem<double>(
          value: speed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(Icons.check, size: 18, color: colorScheme.primary)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text('${speed}x'),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${currentSpeed}x',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Compact audio indicator that shows when audio is available.
///
/// Use this as an alternative to full controls when space is limited.
class AudioIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const AudioIndicator({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.hasMediaOverlay) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  audioProvider.isPlaying ? Icons.volume_up : Icons.headphones,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  audioProvider.isPlaying ? 'Playing' : 'Audio',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
