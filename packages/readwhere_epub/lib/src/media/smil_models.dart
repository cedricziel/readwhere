import 'package:equatable/equatable.dart';

/// Represents a text reference in a SMIL media overlay.
class TextReference extends Equatable {
  /// The source reference (e.g., "chapter1.xhtml#p1").
  final String src;

  const TextReference({required this.src});

  /// The document href without fragment.
  String get href {
    final fragmentIndex = src.indexOf('#');
    return fragmentIndex >= 0 ? src.substring(0, fragmentIndex) : src;
  }

  /// The element ID (fragment identifier), if present.
  String? get elementId {
    final fragmentIndex = src.indexOf('#');
    return fragmentIndex >= 0 && fragmentIndex < src.length - 1
        ? src.substring(fragmentIndex + 1)
        : null;
  }

  @override
  List<Object?> get props => [src];

  @override
  String toString() => 'TextReference($src)';
}

/// Represents an audio clip in a SMIL media overlay.
class AudioClip extends Equatable {
  /// Source audio file (e.g., "audio/chapter1.mp3").
  final String src;

  /// Start time of the clip.
  final Duration clipBegin;

  /// End time of the clip.
  final Duration clipEnd;

  const AudioClip({
    required this.src,
    required this.clipBegin,
    required this.clipEnd,
  });

  /// Duration of this audio clip.
  Duration get duration => clipEnd - clipBegin;

  @override
  List<Object?> get props => [src, clipBegin, clipEnd];

  @override
  String toString() =>
      'AudioClip($src, ${_formatDuration(clipBegin)} - ${_formatDuration(clipEnd)})';

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final millis = d.inMilliseconds.remainder(1000);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(3, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(3, '0')}';
  }
}

/// Base class for SMIL elements (par or seq).
sealed class SmilElement extends Equatable {
  /// Element ID.
  final String? id;

  /// Text reference for this element (epub:textref attribute).
  final String? textRef;

  const SmilElement({this.id, this.textRef});
}

/// A parallel SMIL element (audio and text play simultaneously).
class SmilParallel extends SmilElement {
  /// Audio clip for this parallel element.
  final AudioClip? audio;

  /// Text reference (text element).
  final TextReference? text;

  const SmilParallel({
    super.id,
    super.textRef,
    this.audio,
    this.text,
  });

  /// Whether this element has audio.
  bool get hasAudio => audio != null;

  /// Whether this element has a text reference.
  bool get hasText => text != null || textRef != null;

  /// Effective text reference (from text element or textRef attribute).
  String? get effectiveTextRef => text?.src ?? textRef;

  @override
  List<Object?> get props => [id, textRef, audio, text];

  @override
  String toString() => 'SmilParallel(id: $id, audio: $audio, text: $text)';
}

/// A sequential SMIL element (children play in order).
class SmilSequence extends SmilElement {
  /// Child elements (par or seq).
  final List<SmilElement> children;

  const SmilSequence({
    super.id,
    super.textRef,
    this.children = const [],
  });

  /// Number of child elements.
  int get length => children.length;

  /// Whether this sequence is empty.
  bool get isEmpty => children.isEmpty;

  /// Whether this sequence has children.
  bool get isNotEmpty => children.isNotEmpty;

  /// Flattens all parallel elements in this sequence and nested sequences.
  List<SmilParallel> get flattenedParallels {
    final result = <SmilParallel>[];
    for (final child in children) {
      if (child is SmilParallel) {
        result.add(child);
      } else if (child is SmilSequence) {
        result.addAll(child.flattenedParallels);
      }
    }
    return result;
  }

  @override
  List<Object?> get props => [id, textRef, children];

  @override
  String toString() => 'SmilSequence(id: $id, ${children.length} children)';
}

/// A complete media overlay document.
class MediaOverlay extends Equatable {
  /// ID of this media overlay (from manifest).
  final String id;

  /// Href of the SMIL file within the EPUB.
  final String href;

  /// Total duration of the media overlay.
  final Duration? totalDuration;

  /// Root body elements (par or seq).
  final List<SmilElement> elements;

  const MediaOverlay({
    required this.id,
    required this.href,
    this.totalDuration,
    this.elements = const [],
  });

  /// All parallel elements (flattened from sequences).
  List<SmilParallel> get allParallels {
    final result = <SmilParallel>[];
    for (final element in elements) {
      if (element is SmilParallel) {
        result.add(element);
      } else if (element is SmilSequence) {
        result.addAll(element.flattenedParallels);
      }
    }
    return result;
  }

  /// Number of sync points (parallel elements).
  int get syncPointCount => allParallels.length;

  /// Whether this overlay has any content.
  bool get isEmpty => elements.isEmpty;

  /// Whether this overlay has content.
  bool get isNotEmpty => elements.isNotEmpty;

  /// All unique audio source files.
  Set<String> get audioSources {
    final sources = <String>{};
    for (final par in allParallels) {
      if (par.audio != null) {
        sources.add(par.audio!.src);
      }
    }
    return sources;
  }

  /// All unique text references (document hrefs).
  Set<String> get textReferences {
    final refs = <String>{};
    for (final par in allParallels) {
      final textRef = par.effectiveTextRef;
      if (textRef != null) {
        refs.add(textRef);
      }
    }
    return refs;
  }

  /// Finds all sync points for a given text element ID.
  List<SmilParallel> findByTextId(String elementId) {
    return allParallels.where((p) {
      final ref = p.effectiveTextRef;
      return ref != null && ref.endsWith('#$elementId');
    }).toList();
  }

  /// Finds the sync point at a given time offset.
  SmilParallel? findAtTime(Duration time) {
    for (final par in allParallels) {
      if (par.audio != null) {
        if (time >= par.audio!.clipBegin && time < par.audio!.clipEnd) {
          return par;
        }
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [id, href, totalDuration, elements];

  @override
  String toString() =>
      'MediaOverlay($id, $syncPointCount sync points, duration: $totalDuration)';
}
