/// Natural sorting utilities for comic book page ordering.
///
/// Natural sort orders strings containing numbers in a human-intuitive way:
/// - "page1", "page2", "page10" instead of "page1", "page10", "page2"
///
/// This is essential for CBZ files where page filenames are typically
/// numbered sequentially (e.g., "001.jpg", "002.jpg", ... "100.jpg").
library;

/// Regular expression to split strings into numeric and non-numeric parts.
final _chunkPattern = RegExp(r'(\d+|\D+)');

/// Compares two strings using natural sort order.
///
/// Numbers within strings are compared numerically, not lexicographically.
///
/// Examples:
/// ```dart
/// naturalCompare('page1', 'page2');   // negative (1 < 2)
/// naturalCompare('page2', 'page10');  // negative (2 < 10)
/// naturalCompare('page10', 'page2');  // positive (10 > 2)
/// naturalCompare('a', 'b');           // negative (lexicographic)
/// ```
int naturalCompare(String a, String b) {
  final chunksA = _splitIntoChunks(a);
  final chunksB = _splitIntoChunks(b);

  final minLength =
      chunksA.length < chunksB.length ? chunksA.length : chunksB.length;

  for (var i = 0; i < minLength; i++) {
    final chunkA = chunksA[i];
    final chunkB = chunksB[i];

    final result = _compareChunks(chunkA, chunkB);
    if (result != 0) {
      return result;
    }
  }

  // If all compared chunks are equal, shorter string comes first
  return chunksA.length.compareTo(chunksB.length);
}

/// Splits a string into chunks of consecutive digits or non-digits.
///
/// Example: "page123abc" -> ["page", "123", "abc"]
List<String> _splitIntoChunks(String s) {
  return _chunkPattern.allMatches(s).map((m) => m.group(0)!).toList();
}

/// Compares two chunks, treating numeric chunks numerically.
int _compareChunks(String a, String b) {
  final aIsNumeric = _isNumeric(a);
  final bIsNumeric = _isNumeric(b);

  if (aIsNumeric && bIsNumeric) {
    // Both numeric: compare as integers
    // Handle potential overflow for very large numbers by comparing lengths first
    if (a.length != b.length) {
      // Remove leading zeros and compare lengths
      final aTrimmed = a.replaceFirst(RegExp(r'^0+'), '');
      final bTrimmed = b.replaceFirst(RegExp(r'^0+'), '');
      if (aTrimmed.length != bTrimmed.length) {
        return aTrimmed.length.compareTo(bTrimmed.length);
      }
    }
    return a.compareTo(b);
  }

  if (aIsNumeric != bIsNumeric) {
    // Numeric chunks come before non-numeric (digits before letters)
    return aIsNumeric ? -1 : 1;
  }

  // Both non-numeric: case-insensitive lexicographic comparison
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Checks if a string consists entirely of digits.
bool _isNumeric(String s) {
  if (s.isEmpty) return false;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c < 48 || c > 57) return false; // '0' = 48, '9' = 57
  }
  return true;
}

/// Sorts a list of strings using natural sort order.
///
/// This modifies the list in place.
///
/// Example:
/// ```dart
/// final files = ['page10.jpg', 'page1.jpg', 'page2.jpg'];
/// naturalSort(files);
/// // files is now ['page1.jpg', 'page2.jpg', 'page10.jpg']
/// ```
void naturalSort(List<String> list) {
  list.sort(naturalCompare);
}

/// Returns a new list sorted using natural sort order.
///
/// The original list is not modified.
///
/// Example:
/// ```dart
/// final files = ['page10.jpg', 'page1.jpg', 'page2.jpg'];
/// final sorted = naturalSorted(files);
/// // sorted is ['page1.jpg', 'page2.jpg', 'page10.jpg']
/// // files is unchanged
/// ```
List<String> naturalSorted(Iterable<String> items) {
  final list = items.toList();
  naturalSort(list);
  return list;
}

/// Extension methods for natural sorting on iterables.
extension NaturalSortExtension on Iterable<String> {
  /// Returns a new list sorted using natural sort order.
  List<String> toNaturalSortedList() => naturalSorted(this);
}

/// Extension methods for natural sorting on lists.
extension NaturalSortListExtension on List<String> {
  /// Sorts this list in place using natural sort order.
  void sortNatural() => naturalSort(this);
}
