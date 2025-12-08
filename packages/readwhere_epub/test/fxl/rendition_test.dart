import 'package:readwhere_epub/src/fxl/rendition_properties.dart';
import 'package:test/test.dart';

void main() {
  group('ViewportDimensions', () {
    test('creates with width and height', () {
      const viewport = ViewportDimensions(width: 1024, height: 768);

      expect(viewport.width, 1024);
      expect(viewport.height, 768);
    });

    group('tryParse', () {
      test('parses standard format "width=1024, height=768"', () {
        final viewport = ViewportDimensions.tryParse('width=1024, height=768');

        expect(viewport, isNotNull);
        expect(viewport!.width, 1024);
        expect(viewport.height, 768);
      });

      test('parses without spaces', () {
        final viewport = ViewportDimensions.tryParse('width=800,height=600');

        expect(viewport, isNotNull);
        expect(viewport!.width, 800);
        expect(viewport.height, 600);
      });

      test('parses with extra spaces', () {
        final viewport =
            ViewportDimensions.tryParse('  width = 1920 , height = 1080  ');

        expect(viewport, isNotNull);
        expect(viewport!.width, 1920);
        expect(viewport.height, 1080);
      });

      test('parses case insensitive', () {
        final viewport = ViewportDimensions.tryParse('WIDTH=640, HEIGHT=480');

        expect(viewport, isNotNull);
        expect(viewport!.width, 640);
        expect(viewport.height, 480);
      });

      test('parses height before width', () {
        final viewport = ViewportDimensions.tryParse('height=600, width=800');

        expect(viewport, isNotNull);
        expect(viewport!.width, 800);
        expect(viewport.height, 600);
      });

      test('returns null for missing width', () {
        final viewport = ViewportDimensions.tryParse('height=600');

        expect(viewport, isNull);
      });

      test('returns null for missing height', () {
        final viewport = ViewportDimensions.tryParse('width=800');

        expect(viewport, isNull);
      });

      test('returns null for invalid format', () {
        final viewport = ViewportDimensions.tryParse('invalid');

        expect(viewport, isNull);
      });

      test('returns null for non-numeric values', () {
        final viewport = ViewportDimensions.tryParse('width=abc, height=def');

        expect(viewport, isNull);
      });

      test('returns null for zero dimensions', () {
        final viewport = ViewportDimensions.tryParse('width=0, height=0');

        expect(viewport, isNull);
      });

      test('returns null for negative dimensions', () {
        final viewport = ViewportDimensions.tryParse('width=-100, height=200');

        expect(viewport, isNull);
      });

      test('returns null for empty string', () {
        final viewport = ViewportDimensions.tryParse('');

        expect(viewport, isNull);
      });
    });

    group('aspect ratio', () {
      test('calculates aspect ratio correctly', () {
        const viewport = ViewportDimensions(width: 1920, height: 1080);

        expect(viewport.aspectRatio, closeTo(1.78, 0.01)); // 16:9
      });

      test('isLandscape returns true for wider than tall', () {
        const viewport = ViewportDimensions(width: 1024, height: 768);

        expect(viewport.isLandscape, isTrue);
        expect(viewport.isPortrait, isFalse);
        expect(viewport.isSquare, isFalse);
      });

      test('isPortrait returns true for taller than wide', () {
        const viewport = ViewportDimensions(width: 768, height: 1024);

        expect(viewport.isPortrait, isTrue);
        expect(viewport.isLandscape, isFalse);
        expect(viewport.isSquare, isFalse);
      });

      test('isSquare returns true for equal dimensions', () {
        const viewport = ViewportDimensions(width: 500, height: 500);

        expect(viewport.isSquare, isTrue);
        expect(viewport.isLandscape, isFalse);
        expect(viewport.isPortrait, isFalse);
      });
    });

    test('equality', () {
      const v1 = ViewportDimensions(width: 100, height: 200);
      const v2 = ViewportDimensions(width: 100, height: 200);
      const v3 = ViewportDimensions(width: 100, height: 300);

      expect(v1, equals(v2));
      expect(v1, isNot(equals(v3)));
    });

    test('toString', () {
      const viewport = ViewportDimensions(width: 1024, height: 768);

      expect(viewport.toString(), 'ViewportDimensions(width=1024, height=768)');
    });
  });

  group('RenditionProperties', () {
    test('default values', () {
      const props = RenditionProperties();

      expect(props.layout, RenditionLayout.reflowable);
      expect(props.orientation, RenditionOrientation.auto);
      expect(props.spread, RenditionSpread.auto);
      expect(props.viewport, isNull);
    });

    test('creates with all properties', () {
      const props = RenditionProperties(
        layout: RenditionLayout.prePaginated,
        orientation: RenditionOrientation.landscape,
        spread: RenditionSpread.none,
        viewport: ViewportDimensions(width: 1024, height: 768),
      );

      expect(props.layout, RenditionLayout.prePaginated);
      expect(props.orientation, RenditionOrientation.landscape);
      expect(props.spread, RenditionSpread.none);
      expect(props.viewport?.width, 1024);
      expect(props.viewport?.height, 768);
    });

    test('defaultProperties constant', () {
      expect(RenditionProperties.defaultProperties.layout,
          RenditionLayout.reflowable);
      expect(RenditionProperties.defaultProperties.orientation,
          RenditionOrientation.auto);
      expect(
          RenditionProperties.defaultProperties.spread, RenditionSpread.auto);
      expect(RenditionProperties.defaultProperties.viewport, isNull);
    });

    group('convenience getters', () {
      test('isFixedLayout for pre-paginated', () {
        const props = RenditionProperties(layout: RenditionLayout.prePaginated);

        expect(props.isFixedLayout, isTrue);
        expect(props.isReflowable, isFalse);
      });

      test('isReflowable for reflowable', () {
        const props = RenditionProperties(layout: RenditionLayout.reflowable);

        expect(props.isReflowable, isTrue);
        expect(props.isFixedLayout, isFalse);
      });

      test('hasViewport when viewport is set', () {
        const props = RenditionProperties(
          viewport: ViewportDimensions(width: 800, height: 600),
        );

        expect(props.hasViewport, isTrue);
      });

      test('hasViewport false when viewport is null', () {
        const props = RenditionProperties();

        expect(props.hasViewport, isFalse);
      });
    });

    test('copyWith creates modified copy', () {
      const original = RenditionProperties(
        layout: RenditionLayout.reflowable,
        orientation: RenditionOrientation.auto,
      );

      final modified = original.copyWith(
        layout: RenditionLayout.prePaginated,
        viewport: const ViewportDimensions(width: 100, height: 200),
      );

      expect(modified.layout, RenditionLayout.prePaginated);
      expect(modified.orientation, RenditionOrientation.auto); // unchanged
      expect(modified.viewport?.width, 100);
    });

    test('equality', () {
      const p1 = RenditionProperties(
        layout: RenditionLayout.prePaginated,
        spread: RenditionSpread.none,
      );
      const p2 = RenditionProperties(
        layout: RenditionLayout.prePaginated,
        spread: RenditionSpread.none,
      );
      const p3 = RenditionProperties(
        layout: RenditionLayout.reflowable,
        spread: RenditionSpread.none,
      );

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('SpineItemRendition', () {
    test('none constant has no overrides', () {
      expect(SpineItemRendition.none.layout, isNull);
      expect(SpineItemRendition.none.orientation, isNull);
      expect(SpineItemRendition.none.spread, isNull);
      expect(SpineItemRendition.none.hasOverrides, isFalse);
    });

    test('creates with layout override', () {
      const rendition =
          SpineItemRendition(layout: RenditionLayout.prePaginated);

      expect(rendition.layout, RenditionLayout.prePaginated);
      expect(rendition.hasOverrides, isTrue);
    });

    test('creates with orientation override', () {
      const rendition =
          SpineItemRendition(orientation: RenditionOrientation.portrait);

      expect(rendition.orientation, RenditionOrientation.portrait);
      expect(rendition.hasOverrides, isTrue);
    });

    test('creates with spread override', () {
      const rendition = SpineItemRendition(spread: RenditionSpread.none);

      expect(rendition.spread, RenditionSpread.none);
      expect(rendition.hasOverrides, isTrue);
    });

    test('creates with all overrides', () {
      const rendition = SpineItemRendition(
        layout: RenditionLayout.reflowable,
        orientation: RenditionOrientation.landscape,
        spread: RenditionSpread.both,
      );

      expect(rendition.layout, RenditionLayout.reflowable);
      expect(rendition.orientation, RenditionOrientation.landscape);
      expect(rendition.spread, RenditionSpread.both);
      expect(rendition.hasOverrides, isTrue);
    });

    test('equality', () {
      const r1 = SpineItemRendition(layout: RenditionLayout.prePaginated);
      const r2 = SpineItemRendition(layout: RenditionLayout.prePaginated);
      const r3 = SpineItemRendition(layout: RenditionLayout.reflowable);

      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
    });
  });

  group('RenditionLayout enum', () {
    test('has reflowable value', () {
      expect(RenditionLayout.reflowable.name, 'reflowable');
    });

    test('has prePaginated value', () {
      expect(RenditionLayout.prePaginated.name, 'prePaginated');
    });
  });

  group('RenditionOrientation enum', () {
    test('has auto value', () {
      expect(RenditionOrientation.auto.name, 'auto');
    });

    test('has portrait value', () {
      expect(RenditionOrientation.portrait.name, 'portrait');
    });

    test('has landscape value', () {
      expect(RenditionOrientation.landscape.name, 'landscape');
    });
  });

  group('RenditionSpread enum', () {
    test('has auto value', () {
      expect(RenditionSpread.auto.name, 'auto');
    });

    test('has none value', () {
      expect(RenditionSpread.none.name, 'none');
    });

    test('has landscape value', () {
      expect(RenditionSpread.landscape.name, 'landscape');
    });

    test('has both value', () {
      expect(RenditionSpread.both.name, 'both');
    });
  });
}
