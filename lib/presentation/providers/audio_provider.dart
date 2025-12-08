import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readwhere_epub/readwhere_epub.dart' as epub;

import '../../plugins/epub/readwhere_epub_controller.dart';

/// Provider for managing EPUB media overlay audio playback.
///
/// This provider handles:
/// - Audio playback using just_audio
/// - Synchronization with text content using SMIL timing
/// - Play, pause, seek, and speed controls
/// - Position tracking for text highlighting
class AudioProvider extends ChangeNotifier {
  static final _logger = Logger('AudioProvider');

  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasMediaOverlay = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  String? _error;

  // Media overlay tracking
  epub.MediaOverlay? _currentOverlay;
  epub.SmilParallel? _currentSyncPoint;
  int _currentChapterIndex = -1;

  // Temp files for audio
  final List<File> _tempAudioFiles = [];

  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get hasMediaOverlay => _hasMediaOverlay;
  Duration get position => _position;
  Duration get duration => _duration;
  double get playbackSpeed => _playbackSpeed;
  String? get error => _error;
  epub.SmilParallel? get currentSyncPoint => _currentSyncPoint;
  int get currentChapterIndex => _currentChapterIndex;

  /// The text element ID that should be highlighted.
  String? get highlightedElementId {
    final textRef = _currentSyncPoint?.effectiveTextRef;
    if (textRef == null) return null;

    // Extract fragment identifier (e.g., "chapter1.xhtml#para5" -> "para5")
    final hashIndex = textRef.indexOf('#');
    if (hashIndex != -1 && hashIndex < textRef.length - 1) {
      return textRef.substring(hashIndex + 1);
    }
    return null;
  }

  /// Progress as a value from 0.0 to 1.0.
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  AudioProvider() {
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      _updateCurrentSyncPoint();
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;

      // Handle playback completion
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _position = Duration.zero;
        _currentSyncPoint = null;
      }

      notifyListeners();
    });
  }

  /// Initialize audio for a specific chapter with media overlay.
  Future<bool> initializeForChapter(
    ReadwhereEpubController controller,
    int chapterIndex,
  ) async {
    _logger.info('Initializing audio for chapter $chapterIndex');

    if (!controller.hasMediaOverlays) {
      _logger.info('No media overlays available');
      _hasMediaOverlay = false;
      return false;
    }

    try {
      _error = null;
      _currentChapterIndex = chapterIndex;

      // Get the media overlay for this chapter
      final overlay = controller.getMediaOverlay(chapterIndex);
      if (overlay == null || overlay.isEmpty) {
        _logger.info('No media overlay for chapter $chapterIndex');
        _hasMediaOverlay = false;
        return false;
      }

      _currentOverlay = overlay;
      _hasMediaOverlay = true;
      _logger.info(
        'Found media overlay with ${overlay.syncPointCount} sync points',
      );

      // For now, we'll need to extract the audio from the EPUB
      // This is a simplified implementation - in production, you'd
      // extract the actual audio bytes from the EPUB archive
      // and create temp files or use in-memory audio sources

      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error initializing audio', e, stackTrace);
      _error = 'Failed to initialize audio: $e';
      _hasMediaOverlay = false;
      notifyListeners();
      return false;
    }
  }

  /// Load audio from bytes and prepare for playback.
  Future<void> loadAudioFromBytes(Uint8List audioBytes, String mimeType) async {
    try {
      _error = null;

      // Determine file extension from mime type
      String extension = '.mp3';
      if (mimeType.contains('mp4') || mimeType.contains('m4a')) {
        extension = '.m4a';
      } else if (mimeType.contains('ogg')) {
        extension = '.ogg';
      } else if (mimeType.contains('wav')) {
        extension = '.wav';
      }

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/readwhere_audio_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      await tempFile.writeAsBytes(audioBytes);
      _tempAudioFiles.add(tempFile);

      // Load into player
      await _audioPlayer.setFilePath(tempFile.path);
      await _audioPlayer.setSpeed(_playbackSpeed);

      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('Error loading audio', e, stackTrace);
      _error = 'Failed to load audio: $e';
      notifyListeners();
    }
  }

  /// Play audio.
  Future<void> play() async {
    if (!_isInitialized) {
      _error = 'Audio not initialized';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      await _audioPlayer.play();
    } catch (e, stackTrace) {
      _logger.severe('Error playing audio', e, stackTrace);
      _error = 'Failed to play audio: $e';
      notifyListeners();
    }
  }

  /// Pause audio.
  Future<void> pause() async {
    try {
      _error = null;
      await _audioPlayer.pause();
    } catch (e, stackTrace) {
      _logger.severe('Error pausing audio', e, stackTrace);
      _error = 'Failed to pause audio: $e';
      notifyListeners();
    }
  }

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seek to a specific position.
  Future<void> seek(Duration position) async {
    try {
      _error = null;
      await _audioPlayer.seek(position);
    } catch (e, stackTrace) {
      _logger.severe('Error seeking', e, stackTrace);
      _error = 'Failed to seek: $e';
      notifyListeners();
    }
  }

  /// Seek to a specific progress (0.0 to 1.0).
  Future<void> seekToProgress(double progress) async {
    final targetPosition = Duration(
      milliseconds: (progress * _duration.inMilliseconds).round(),
    );
    await seek(targetPosition);
  }

  /// Skip forward by a duration.
  Future<void> skipForward({
    Duration amount = const Duration(seconds: 10),
  }) async {
    final newPosition = _position + amount;
    if (newPosition < _duration) {
      await seek(newPosition);
    } else {
      await seek(_duration);
    }
  }

  /// Skip backward by a duration.
  Future<void> skipBackward({
    Duration amount = const Duration(seconds: 10),
  }) async {
    final newPosition = _position - amount;
    if (newPosition > Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  /// Set playback speed.
  Future<void> setSpeed(double speed) async {
    try {
      _error = null;
      _playbackSpeed = speed.clamp(0.5, 2.0);
      await _audioPlayer.setSpeed(_playbackSpeed);
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('Error setting speed', e, stackTrace);
      _error = 'Failed to set speed: $e';
      notifyListeners();
    }
  }

  /// Stop playback and reset.
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
      _position = Duration.zero;
      _currentSyncPoint = null;
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('Error stopping audio', e, stackTrace);
    }
  }

  /// Update the current sync point based on playback position.
  void _updateCurrentSyncPoint() {
    if (_currentOverlay == null) return;

    final newSyncPoint = _currentOverlay!.findAtTime(_position);
    if (newSyncPoint != _currentSyncPoint) {
      _currentSyncPoint = newSyncPoint;
      // notifyListeners is called by the position listener
    }
  }

  /// Navigate to a specific sync point.
  Future<void> goToSyncPoint(epub.SmilParallel syncPoint) async {
    final audio = syncPoint.audio;
    if (audio != null) {
      await seek(audio.clipBegin);
    }
  }

  /// Navigate to a sync point by text element ID.
  Future<void> goToTextElement(String elementId) async {
    if (_currentOverlay == null) return;

    final matches = _currentOverlay!.findByTextId(elementId);
    if (matches.isNotEmpty) {
      await goToSyncPoint(matches.first);
    }
  }

  /// Clean up resources.
  @override
  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _audioPlayer.dispose();

    // Clean up temp files
    for (final file in _tempAudioFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        _logger.warning('Failed to delete temp file: $e');
      }
    }
    _tempAudioFiles.clear();

    super.dispose();
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state when changing chapters or closing book.
  Future<void> reset() async {
    await stop();
    _isInitialized = false;
    _hasMediaOverlay = false;
    _currentOverlay = null;
    _currentSyncPoint = null;
    _currentChapterIndex = -1;
    _duration = Duration.zero;
    notifyListeners();
  }
}
