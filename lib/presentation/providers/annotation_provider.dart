import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/annotation.dart';
import '../../domain/entities/text_selection_state.dart';
import '../../domain/repositories/annotation_repository.dart';

/// Provider for managing annotation state in the reader.
///
/// Handles:
/// - Loading annotations for the current book
/// - Creating, updating, and deleting annotations
/// - Managing text selection state
/// - Filtering annotations by chapter
class AnnotationProvider extends ChangeNotifier {
  final AnnotationRepository _annotationRepository;
  final Uuid _uuid = const Uuid();

  AnnotationProvider({required AnnotationRepository annotationRepository})
    : _annotationRepository = annotationRepository;

  // State
  List<Annotation> _annotations = [];
  String? _currentBookId;
  bool _isLoading = false;
  String? _error;
  TextSelectionState? _currentSelection;
  bool _sidePanelVisible = false;

  // Getters
  List<Annotation> get annotations => List.unmodifiable(_annotations);
  String? get currentBookId => _currentBookId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TextSelectionState? get currentSelection => _currentSelection;
  bool get sidePanelVisible => _sidePanelVisible;
  bool get hasSelection => _currentSelection != null;

  /// Returns annotations for a specific chapter
  List<Annotation> annotationsForChapter(String? chapterId) {
    if (chapterId == null) return [];
    return _annotations.where((a) => a.chapterId == chapterId).toList();
  }

  /// Returns annotations grouped by chapter ID
  Map<String?, List<Annotation>> get annotationsByChapter {
    final grouped = <String?, List<Annotation>>{};
    for (final annotation in _annotations) {
      grouped.putIfAbsent(annotation.chapterId, () => []).add(annotation);
    }
    return grouped;
  }

  /// Returns the count of annotations
  int get annotationCount => _annotations.length;

  /// Loads annotations for a book
  Future<void> loadAnnotationsForBook(String bookId) async {
    if (_currentBookId == bookId && _annotations.isNotEmpty) {
      // Already loaded
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentBookId = bookId;
      _annotations = await _annotationRepository.getAnnotationsForBook(bookId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load annotations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears annotations when closing a book
  void clearAnnotations() {
    _annotations = [];
    _currentBookId = null;
    _currentSelection = null;
    _sidePanelVisible = false;
    notifyListeners();
  }

  /// Sets the current text selection
  void setSelection({
    required String selectedText,
    required int chapterIndex,
    String? chapterHref,
  }) {
    if (selectedText.trim().isEmpty) {
      _currentSelection = null;
    } else {
      _currentSelection = TextSelectionState(
        selectedText: selectedText,
        chapterIndex: chapterIndex,
        chapterHref: chapterHref,
        selectionTime: DateTime.now(),
      );
    }
    notifyListeners();
  }

  /// Clears the current selection
  void clearSelection() {
    _currentSelection = null;
    notifyListeners();
  }

  /// Creates an annotation from the current selection
  ///
  /// Returns the created annotation or null if no selection exists.
  Future<Annotation?> createAnnotationFromSelection({
    required AnnotationColor color,
    String? note,
  }) async {
    if (_currentSelection == null || _currentBookId == null) {
      return null;
    }

    final selection = _currentSelection!;

    // Generate simplified CFI based on chapter and position
    // A more sophisticated CFI resolver would be used in production
    final chapterId = 'chapter-${selection.chapterIndex}';
    final cfiBase = 'epubcfi(/6/${(selection.chapterIndex + 1) * 2}!)';

    final annotation = Annotation(
      id: _uuid.v4(),
      bookId: _currentBookId!,
      chapterId: chapterId,
      cfiStart: selection.cfiStart ?? cfiBase,
      cfiEnd: selection.cfiEnd ?? cfiBase,
      text: selection.selectedText,
      note: note,
      color: color,
      createdAt: DateTime.now(),
    );

    try {
      final created = await _annotationRepository.addAnnotation(annotation);
      _annotations.insert(0, created);
      _currentSelection = null;
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to create annotation: $e';
      notifyListeners();
      return null;
    }
  }

  /// Creates an annotation directly (without using selection state)
  Future<Annotation?> createAnnotation({
    required String text,
    required int chapterIndex,
    required AnnotationColor color,
    String? note,
    String? cfiStart,
    String? cfiEnd,
  }) async {
    if (_currentBookId == null) return null;

    final chapterId = 'chapter-$chapterIndex';
    final cfiBase = 'epubcfi(/6/${(chapterIndex + 1) * 2}!)';

    final annotation = Annotation(
      id: _uuid.v4(),
      bookId: _currentBookId!,
      chapterId: chapterId,
      cfiStart: cfiStart ?? cfiBase,
      cfiEnd: cfiEnd ?? cfiBase,
      text: text,
      note: note,
      color: color,
      createdAt: DateTime.now(),
    );

    try {
      final created = await _annotationRepository.addAnnotation(annotation);
      _annotations.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to create annotation: $e';
      notifyListeners();
      return null;
    }
  }

  /// Updates the note of an annotation
  Future<Annotation?> updateNote(String annotationId, String? note) async {
    final index = _annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return null;

    final annotation = _annotations[index];
    final updated = annotation.copyWith(note: note);

    try {
      final result = await _annotationRepository.updateAnnotation(updated);
      _annotations[index] = result;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Failed to update annotation: $e';
      notifyListeners();
      return null;
    }
  }

  /// Updates the color of an annotation
  Future<Annotation?> updateColor(
    String annotationId,
    AnnotationColor color,
  ) async {
    final index = _annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return null;

    final annotation = _annotations[index];
    final updated = annotation.copyWith(color: color);

    try {
      final result = await _annotationRepository.updateAnnotation(updated);
      _annotations[index] = result;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Failed to update annotation color: $e';
      notifyListeners();
      return null;
    }
  }

  /// Deletes an annotation
  Future<bool> deleteAnnotation(String annotationId) async {
    try {
      final success = await _annotationRepository.deleteAnnotation(
        annotationId,
      );
      if (success) {
        _annotations.removeWhere((a) => a.id == annotationId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete annotation: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggles the side panel visibility
  void toggleSidePanel() {
    _sidePanelVisible = !_sidePanelVisible;
    notifyListeners();
  }

  /// Shows the side panel
  void showSidePanel() {
    _sidePanelVisible = true;
    notifyListeners();
  }

  /// Hides the side panel
  void hideSidePanel() {
    _sidePanelVisible = false;
    notifyListeners();
  }

  /// Clears any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Gets an annotation by ID
  Annotation? getAnnotation(String id) {
    try {
      return _annotations.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
