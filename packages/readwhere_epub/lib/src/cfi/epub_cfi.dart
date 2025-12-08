import 'package:equatable/equatable.dart';

import '../errors/epub_exception.dart';
import 'cfi_step.dart';

/// EPUB Canonical Fragment Identifier (CFI).
///
/// CFI provides a standardized way to reference specific locations within
/// an EPUB publication, enabling features like bookmarks, highlights,
/// and search result positioning.
///
/// ## CFI Format
/// A CFI string follows this pattern:
/// ```
/// epubcfi(/6/4!/4/2/1:0)
///         │ │  │ │ │ └── character offset
///         │ │  │ │ └──── element index (1-based, even = element)
///         │ │  │ └────── path through DOM
///         │ │  └──────── content document assertion (!)
///         │ └────────── spine item step (0-based index * 2 + 2)
///         └──────────── package document step (/6 = spine in OPF)
/// ```
///
/// ## Example
/// ```dart
/// final cfi = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');
/// print(cfi.spineIndex);    // 1 (second spine item)
/// print(cfi.path);          // [CfiStep(4), CfiStep(2)]
/// print(cfi.characterOffset); // 10
/// ```
class EpubCfi extends Equatable implements Comparable<EpubCfi> {
  /// The spine index (0-based) this CFI points to.
  final int spineIndex;

  /// Path through the DOM tree within the content document.
  final List<CfiStep> path;

  /// Character offset within the final element/text node.
  final CfiCharacterOffset? characterOffset;

  /// Whether this CFI includes an indirect path (content document).
  ///
  /// When true, the CFI includes a `!` separator indicating navigation
  /// into a content document referenced by the spine.
  final bool hasIndirectPath;

  const EpubCfi({
    required this.spineIndex,
    this.path = const [],
    this.characterOffset,
    this.hasIndirectPath = true,
  });

  /// Parses a CFI string into an [EpubCfi] object.
  ///
  /// Throws [EpubCfiParseException] if the CFI string is invalid.
  ///
  /// Example:
  /// ```dart
  /// final cfi = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');
  /// ```
  factory EpubCfi.parse(String cfiString) {
    final result = tryParse(cfiString);
    if (result == null) {
      throw EpubCfiParseException('Invalid CFI format', cfiString);
    }
    return result;
  }

  /// Attempts to parse a CFI string, returning null if invalid.
  ///
  /// Example:
  /// ```dart
  /// final cfi = EpubCfi.tryParse('epubcfi(/6/4!/4/2:10)');
  /// if (cfi != null) {
  ///   print('Spine index: ${cfi.spineIndex}');
  /// }
  /// ```
  static EpubCfi? tryParse(String cfiString) {
    final trimmed = cfiString.trim();

    // Check for epubcfi() wrapper
    if (!trimmed.startsWith('epubcfi(') || !trimmed.endsWith(')')) {
      return null;
    }

    // Extract the inner CFI content
    final inner = trimmed.substring(8, trimmed.length - 1);
    if (inner.isEmpty) {
      return null;
    }

    return _parseCfiPath(inner);
  }

  /// Creates a CFI pointing to a spine item only (chapter level).
  ///
  /// Example:
  /// ```dart
  /// final cfi = EpubCfi.fromSpineIndex(2); // Third chapter
  /// print(cfi); // epubcfi(/6/6!)
  /// ```
  factory EpubCfi.fromSpineIndex(int index) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'Spine index must be >= 0');
    }
    return EpubCfi(
      spineIndex: index,
      hasIndirectPath: true,
    );
  }

  /// Creates a CFI pointing to an element by ID within a spine item.
  ///
  /// Example:
  /// ```dart
  /// final cfi = EpubCfi.fromElementId(0, 'chapter1');
  /// ```
  factory EpubCfi.fromElementId(int spineIndex, String elementId) {
    if (spineIndex < 0) {
      throw ArgumentError.value(
        spineIndex,
        'spineIndex',
        'Spine index must be >= 0',
      );
    }
    if (elementId.isEmpty) {
      throw ArgumentError.value(
        elementId,
        'elementId',
        'Element ID cannot be empty',
      );
    }
    // Create a path with just the ID assertion
    return EpubCfi(
      spineIndex: spineIndex,
      path: [CfiStep(index: 4, id: elementId)], // /4 = body typically
      hasIndirectPath: true,
    );
  }

  /// Creates a CFI from a spine index and element path.
  ///
  /// The [elementPath] is a list of 0-based indices through the DOM.
  /// These are converted to CFI format (1-based, *2 for elements).
  factory EpubCfi.fromElementPath(
    int spineIndex,
    List<int> elementPath, {
    int? characterOffset,
    String? elementId,
  }) {
    if (spineIndex < 0) {
      throw ArgumentError.value(
        spineIndex,
        'spineIndex',
        'Spine index must be >= 0',
      );
    }

    final steps = <CfiStep>[];
    for (var i = 0; i < elementPath.length; i++) {
      final isLast = i == elementPath.length - 1;
      steps.add(CfiStep(
        index: (elementPath[i] + 1) * 2, // Convert to CFI format
        id: isLast ? elementId : null,
      ));
    }

    return EpubCfi(
      spineIndex: spineIndex,
      path: steps,
      characterOffset: characterOffset != null
          ? CfiCharacterOffset(offset: characterOffset)
          : null,
      hasIndirectPath: true,
    );
  }

  /// Returns a CFI with only the spine reference (no element path).
  EpubCfi get spineOnly => EpubCfi(
        spineIndex: spineIndex,
        hasIndirectPath: hasIndirectPath,
      );

  /// Returns a CFI without the character offset.
  EpubCfi get withoutOffset => EpubCfi(
        spineIndex: spineIndex,
        path: path,
        hasIndirectPath: hasIndirectPath,
      );

  /// Whether this CFI has an element path.
  bool get hasPath => path.isNotEmpty;

  /// Whether this CFI has a character offset.
  bool get hasOffset => characterOffset != null;

  /// Compares CFIs for ordering (reading position).
  ///
  /// Returns:
  /// - negative if this CFI comes before [other]
  /// - positive if this CFI comes after [other]
  /// - zero if they point to the same location
  @override
  int compareTo(EpubCfi other) {
    // Compare spine index first
    final spineCompare = spineIndex.compareTo(other.spineIndex);
    if (spineCompare != 0) return spineCompare;

    // Compare paths step by step
    final minLength =
        path.length < other.path.length ? path.length : other.path.length;
    for (var i = 0; i < minLength; i++) {
      final stepCompare = path[i].index.compareTo(other.path[i].index);
      if (stepCompare != 0) return stepCompare;
    }

    // If paths are equal up to the shorter length, shorter path comes first
    final pathLengthCompare = path.length.compareTo(other.path.length);
    if (pathLengthCompare != 0) return pathLengthCompare;

    // Compare character offsets
    final thisOffset = characterOffset?.offset ?? 0;
    final otherOffset = other.characterOffset?.offset ?? 0;
    return thisOffset.compareTo(otherOffset);
  }

  /// Returns true if this CFI points to a location before [other].
  bool operator <(EpubCfi other) => compareTo(other) < 0;

  /// Returns true if this CFI points to a location after [other].
  bool operator >(EpubCfi other) => compareTo(other) > 0;

  /// Returns true if this CFI points to the same or earlier location as [other].
  bool operator <=(EpubCfi other) => compareTo(other) <= 0;

  /// Returns true if this CFI points to the same or later location as [other].
  bool operator >=(EpubCfi other) => compareTo(other) >= 0;

  @override
  String toString() {
    final buffer = StringBuffer()..write('epubcfi(/6/');

    // Spine index: (index * 2 + 2) for 0-based to CFI format
    buffer.write(spineIndex * 2 + 2);

    // Add indirect path marker if needed
    if (hasIndirectPath) {
      buffer.write('!');
    }

    // Add element path
    for (final step in path) {
      buffer.write(step);
    }

    // Add character offset
    if (characterOffset != null) {
      buffer.write(characterOffset);
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  List<Object?> get props =>
      [spineIndex, path, characterOffset, hasIndirectPath];

  /// Parses the CFI path content (without epubcfi() wrapper).
  static EpubCfi? _parseCfiPath(String path) {
    // Must start with /6/ (package document spine reference)
    if (!path.startsWith('/6/')) {
      return null;
    }

    final remaining = path.substring(3);
    if (remaining.isEmpty) {
      return null;
    }

    // Find the spine index step
    final spineEndMatch = RegExp(r'^(\d+)').firstMatch(remaining);
    if (spineEndMatch == null) {
      return null;
    }

    final spineStep = int.tryParse(spineEndMatch.group(1)!);
    if (spineStep == null || spineStep < 2 || spineStep % 2 != 0) {
      return null;
    }

    // Convert from CFI format to 0-based index
    final spineIndex = (spineStep - 2) ~/ 2;

    var rest = remaining.substring(spineEndMatch.end);
    var hasIndirectPath = false;

    // Check for indirect path (!)
    if (rest.startsWith('!')) {
      hasIndirectPath = true;
      rest = rest.substring(1);
    }

    // Parse element path and character offset
    final steps = <CfiStep>[];
    CfiCharacterOffset? charOffset;

    while (rest.isNotEmpty) {
      // Check for character offset
      if (rest.startsWith(':')) {
        charOffset = _parseCharacterOffset(rest);
        break;
      }

      // Check for step
      if (rest.startsWith('/')) {
        final stepResult = _parseStep(rest.substring(1));
        if (stepResult == null) break;
        steps.add(stepResult.step);
        rest = stepResult.remaining;
      } else {
        break;
      }
    }

    return EpubCfi(
      spineIndex: spineIndex,
      path: steps,
      characterOffset: charOffset,
      hasIndirectPath: hasIndirectPath,
    );
  }

  /// Parses a single CFI step.
  static _StepParseResult? _parseStep(String input) {
    // Match the index number
    final indexMatch = RegExp(r'^(\d+)').firstMatch(input);
    if (indexMatch == null) return null;

    final index = int.parse(indexMatch.group(1)!);
    var remaining = input.substring(indexMatch.end);

    String? id;
    String? elementType;

    // Parse assertions [...]
    while (remaining.startsWith('[')) {
      final endBracket = _findMatchingBracket(remaining);
      if (endBracket == -1) break;

      final assertion = remaining.substring(1, endBracket);
      remaining = remaining.substring(endBracket + 1);

      // Check for type assertion
      if (assertion.startsWith('type=')) {
        elementType = assertion.substring(5);
      } else if (!assertion.contains('=') && !assertion.startsWith(';')) {
        // Simple ID assertion
        id = _unescape(assertion);
      }
    }

    return _StepParseResult(
      step: CfiStep(index: index, id: id, elementType: elementType),
      remaining: remaining,
    );
  }

  /// Parses a character offset `:offset[assertion]`.
  static CfiCharacterOffset? _parseCharacterOffset(String input) {
    if (!input.startsWith(':')) return null;

    final match = RegExp(r'^:(\d+)').firstMatch(input);
    if (match == null) return null;

    final offset = int.parse(match.group(1)!);
    final remaining = input.substring(match.end);

    CfiTextAssertion? assertion;

    // Parse text assertion if present
    if (remaining.startsWith('[;s=')) {
      final endBracket = _findMatchingBracket(remaining);
      if (endBracket > 4) {
        final assertionContent = remaining.substring(4, endBracket);
        assertion = _parseTextAssertion(assertionContent);
      }
    }

    return CfiCharacterOffset(offset: offset, assertion: assertion);
  }

  /// Parses text assertion content.
  static CfiTextAssertion? _parseTextAssertion(String content) {
    final parts = _splitUnescaped(content, ',');
    if (parts.isEmpty) return null;

    final before =
        parts.isNotEmpty && parts[0].isNotEmpty ? _unescape(parts[0]) : null;
    final after =
        parts.length > 1 && parts[1].isNotEmpty ? _unescape(parts[1]) : null;

    if (before == null && after == null) return null;

    return CfiTextAssertion(before: before, after: after);
  }

  /// Finds the matching closing bracket, handling escapes.
  static int _findMatchingBracket(String input) {
    if (!input.startsWith('[')) return -1;

    var depth = 0;
    var i = 0;
    while (i < input.length) {
      final char = input[i];
      if (char == '^' && i + 1 < input.length) {
        i += 2; // Skip escaped character
        continue;
      }
      if (char == '[') {
        depth++;
      } else if (char == ']') {
        depth--;
        if (depth == 0) return i;
      }
      i++;
    }
    return -1;
  }

  /// Splits a string by delimiter, respecting CFI escapes.
  static List<String> _splitUnescaped(String input, String delimiter) {
    final parts = <String>[];
    var current = StringBuffer();
    var i = 0;

    while (i < input.length) {
      if (input[i] == '^' && i + 1 < input.length) {
        current.write(input[i]);
        current.write(input[i + 1]);
        i += 2;
        continue;
      }
      if (input[i] == delimiter) {
        parts.add(current.toString());
        current = StringBuffer();
        i++;
        continue;
      }
      current.write(input[i]);
      i++;
    }
    parts.add(current.toString());

    return parts;
  }

  /// Unescapes CFI escape sequences.
  static String _unescape(String input) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < input.length) {
      if (input[i] == '^' && i + 1 < input.length) {
        buffer.write(input[i + 1]);
        i += 2;
      } else {
        buffer.write(input[i]);
        i++;
      }
    }
    return buffer.toString();
  }
}

/// Helper class for step parsing.
class _StepParseResult {
  final CfiStep step;
  final String remaining;

  _StepParseResult({required this.step, required this.remaining});
}
