/// Panel detection for comic book pages.
///
/// This library provides automatic panel detection for comic pages using
/// connected component labeling (CCL). It can identify individual panels
/// and sort them by reading order (left-to-right or right-to-left).
library;

export 'src/panel.dart';
export 'src/panel_detector.dart';
export 'src/reading_order.dart';
