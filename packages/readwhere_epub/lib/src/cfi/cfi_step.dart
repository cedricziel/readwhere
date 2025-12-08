import 'package:equatable/equatable.dart';

/// A single step in a CFI path.
///
/// Each step represents a navigation from a parent to a child element
/// in the DOM tree. Steps use 1-based indexing where:
/// - Even numbers (2, 4, 6, ...) refer to element nodes
/// - Odd numbers (1, 3, 5, ...) refer to text nodes
class CfiStep extends Equatable {
  /// The 1-based index of this step in the parent's children.
  ///
  /// Even indices (2, 4, 6, ...) indicate element nodes.
  /// Odd indices (1, 3, 5, ...) indicate text nodes.
  final int index;

  /// Optional element ID assertion.
  ///
  /// When present, the parser should verify the element has this ID.
  /// Format in CFI: `[id]`
  final String? id;

  /// Optional element type assertion.
  ///
  /// When present, indicates the expected element type (tag name).
  /// Format in CFI: `[type=tagname]`
  final String? elementType;

  const CfiStep({
    required this.index,
    this.id,
    this.elementType,
  });

  /// Whether this step refers to an element node (even index).
  bool get isElement => index % 2 == 0;

  /// Whether this step refers to a text node (odd index).
  bool get isTextNode => index % 2 == 1;

  /// Creates a copy with modified fields.
  CfiStep copyWith({
    int? index,
    String? id,
    String? elementType,
  }) {
    return CfiStep(
      index: index ?? this.index,
      id: id ?? this.id,
      elementType: elementType ?? this.elementType,
    );
  }

  @override
  List<Object?> get props => [index, id, elementType];

  @override
  String toString() {
    final buffer = StringBuffer()..write('/$index');
    if (id != null) {
      buffer.write('[$id]');
    }
    if (elementType != null) {
      buffer.write('[type=$elementType]');
    }
    return buffer.toString();
  }
}

/// Character offset within a text node or element.
///
/// Used for precise positioning within content.
class CfiCharacterOffset extends Equatable {
  /// The character offset (0-based).
  final int offset;

  /// Optional text assertion for validation.
  ///
  /// Contains text before and/or after the offset point.
  /// Format: `[;s=before,after]`
  final CfiTextAssertion? assertion;

  const CfiCharacterOffset({
    required this.offset,
    this.assertion,
  });

  @override
  List<Object?> get props => [offset, assertion];

  @override
  String toString() {
    final buffer = StringBuffer()..write(':$offset');
    if (assertion != null) {
      buffer.write(assertion);
    }
    return buffer.toString();
  }
}

/// Text assertion for CFI validation.
///
/// Contains text before and/or after the target position to verify
/// the CFI points to the correct location.
class CfiTextAssertion extends Equatable {
  /// Text expected before the offset.
  final String? before;

  /// Text expected after the offset.
  final String? after;

  const CfiTextAssertion({
    this.before,
    this.after,
  });

  @override
  List<Object?> get props => [before, after];

  @override
  String toString() {
    final parts = <String>[];
    if (before != null) {
      parts.add(_escape(before!));
    }
    if (after != null || before != null) {
      parts.add(after != null ? _escape(after!) : '');
    }
    if (parts.isEmpty) return '';
    return '[;s=${parts.join(",")}]';
  }

  /// Escapes special CFI characters in text.
  static String _escape(String text) {
    return text
        .replaceAll('^', '^^')
        .replaceAll('[', '^[')
        .replaceAll(']', '^]')
        .replaceAll('(', '^(')
        .replaceAll(')', '^)')
        .replaceAll(',', '^,')
        .replaceAll(';', '^;');
  }
}
