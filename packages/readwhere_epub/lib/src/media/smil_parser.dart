import 'package:xml/xml.dart';

import 'smil_models.dart';

/// Parser for SMIL (Synchronized Multimedia Integration Language) documents.
class SmilParser {
  /// SMIL namespace.
  static const String smilNs = 'http://www.w3.org/ns/SMIL';

  /// EPUB namespace (for epub:textref).
  static const String epubNs = 'http://www.idpf.org/2007/ops';

  /// Parses a SMIL document into a [MediaOverlay].
  ///
  /// Parameters:
  /// - [smilContent]: The XML content of the SMIL file.
  /// - [id]: The manifest ID of the SMIL file.
  /// - [href]: The href of the SMIL file within the EPUB.
  ///
  /// Returns null if parsing fails.
  static MediaOverlay? parse(String smilContent, String id, String href) {
    try {
      final document = XmlDocument.parse(smilContent);
      return _parseDocument(document, id, href);
    } on XmlException {
      return null;
    }
  }

  static MediaOverlay _parseDocument(
      XmlDocument document, String id, String href) {
    final root = document.rootElement;

    // Parse total duration from head/meta
    Duration? totalDuration;
    final head = _findElement(root, 'head');
    if (head != null) {
      for (final meta in _findAllElements(head, 'meta')) {
        final name = meta.getAttribute('name');
        if (name == 'duration') {
          final content = meta.getAttribute('content');
          if (content != null) {
            totalDuration = parseClipTime(content);
          }
        }
      }
    }

    // Parse body elements
    final body = _findElement(root, 'body');
    final elements = <SmilElement>[];

    if (body != null) {
      for (final child in body.childElements) {
        final element = _parseElement(child);
        if (element != null) {
          elements.add(element);
        }
      }
    }

    return MediaOverlay(
      id: id,
      href: href,
      totalDuration: totalDuration,
      elements: elements,
    );
  }

  static SmilElement? _parseElement(XmlElement element) {
    final localName = element.localName;

    if (localName == 'par') {
      return _parsePar(element);
    } else if (localName == 'seq') {
      return _parseSeq(element);
    }

    return null;
  }

  static SmilParallel _parsePar(XmlElement element) {
    final id = element.getAttribute('id');
    final textRef = element.getAttribute('textref', namespace: epubNs) ??
        element.getAttribute('epub:textref');

    AudioClip? audio;
    TextReference? text;

    for (final child in element.childElements) {
      final childName = child.localName;

      if (childName == 'audio') {
        audio = _parseAudio(child);
      } else if (childName == 'text') {
        final src = child.getAttribute('src');
        if (src != null) {
          text = TextReference(src: src);
        }
      }
    }

    return SmilParallel(
      id: id,
      textRef: textRef,
      audio: audio,
      text: text,
    );
  }

  static SmilSequence _parseSeq(XmlElement element) {
    final id = element.getAttribute('id');
    final textRef = element.getAttribute('textref', namespace: epubNs) ??
        element.getAttribute('epub:textref');

    final children = <SmilElement>[];
    for (final child in element.childElements) {
      final parsed = _parseElement(child);
      if (parsed != null) {
        children.add(parsed);
      }
    }

    return SmilSequence(
      id: id,
      textRef: textRef,
      children: children,
    );
  }

  static AudioClip? _parseAudio(XmlElement element) {
    final src = element.getAttribute('src');
    if (src == null) return null;

    final clipBeginStr = element.getAttribute('clipBegin');
    final clipEndStr = element.getAttribute('clipEnd');

    final clipBegin =
        clipBeginStr != null ? parseClipTime(clipBeginStr) : Duration.zero;
    final clipEnd = clipEndStr != null ? parseClipTime(clipEndStr) : clipBegin;

    return AudioClip(
      src: src,
      clipBegin: clipBegin,
      clipEnd: clipEnd,
    );
  }

  /// Parses a SMIL clock value into a [Duration].
  ///
  /// Supports formats:
  /// - Clock value: "00:01:23.456" (h:mm:ss.mmm)
  /// - Partial clock value: "01:23.456" (mm:ss.mmm) or "23.456" (ss.mmm)
  /// - Seconds: "83.456s"
  /// - Milliseconds: "83456ms"
  /// - Minutes: "1.5min"
  /// - Hours: "0.5h"
  ///
  /// Returns [Duration.zero] if parsing fails.
  static Duration parseClipTime(String time) {
    final trimmed = time.trim();
    if (trimmed.isEmpty) return Duration.zero;

    // Handle unit-based formats
    if (trimmed.endsWith('ms')) {
      final value = double.tryParse(trimmed.substring(0, trimmed.length - 2));
      if (value != null) {
        return Duration(microseconds: (value * 1000).round());
      }
    } else if (trimmed.endsWith('s') && !trimmed.endsWith('ms')) {
      final value = double.tryParse(trimmed.substring(0, trimmed.length - 1));
      if (value != null) {
        return Duration(microseconds: (value * 1000000).round());
      }
    } else if (trimmed.endsWith('min')) {
      final value = double.tryParse(trimmed.substring(0, trimmed.length - 3));
      if (value != null) {
        return Duration(microseconds: (value * 60 * 1000000).round());
      }
    } else if (trimmed.endsWith('h')) {
      final value = double.tryParse(trimmed.substring(0, trimmed.length - 1));
      if (value != null) {
        return Duration(microseconds: (value * 3600 * 1000000).round());
      }
    }

    // Handle clock value format (hh:mm:ss.mmm or mm:ss.mmm or ss.mmm)
    final parts = trimmed.split(':');

    try {
      if (parts.length == 3) {
        // hh:mm:ss.mmm
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secondsParts = parts[2].split('.');
        final seconds = int.parse(secondsParts[0]);
        final millis =
            secondsParts.length > 1 ? _parseMillis(secondsParts[1]) : 0;

        return Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
      } else if (parts.length == 2) {
        // mm:ss.mmm
        final minutes = int.parse(parts[0]);
        final secondsParts = parts[1].split('.');
        final seconds = int.parse(secondsParts[0]);
        final millis =
            secondsParts.length > 1 ? _parseMillis(secondsParts[1]) : 0;

        return Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
      } else if (parts.length == 1) {
        // ss.mmm or just seconds
        final secondsParts = trimmed.split('.');
        final seconds = int.parse(secondsParts[0]);
        final millis =
            secondsParts.length > 1 ? _parseMillis(secondsParts[1]) : 0;

        return Duration(
          seconds: seconds,
          milliseconds: millis,
        );
      }
    } catch (_) {
      // Fall through to return zero
    }

    return Duration.zero;
  }

  /// Parses the fractional part of seconds into milliseconds.
  /// Handles variable precision (e.g., ".5" = 500ms, ".05" = 50ms, ".005" = 5ms).
  static int _parseMillis(String fraction) {
    if (fraction.isEmpty) return 0;

    // Pad or truncate to 3 digits for milliseconds
    String normalized = fraction;
    if (normalized.length < 3) {
      normalized = normalized.padRight(3, '0');
    } else if (normalized.length > 3) {
      normalized = normalized.substring(0, 3);
    }

    return int.tryParse(normalized) ?? 0;
  }

  /// Finds a child element by local name (namespace-agnostic).
  static XmlElement? _findElement(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.localName == localName) {
        return child;
      }
    }
    return null;
  }

  /// Finds all child elements by local name (namespace-agnostic).
  static Iterable<XmlElement> _findAllElements(
      XmlElement parent, String localName) {
    return parent.childElements.where((e) => e.localName == localName);
  }
}
