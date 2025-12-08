import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere_epub/src/fxl/rendition_properties.dart';
import 'package:readwhere_epub/src/package/spine/spine.dart';

void main() {
  group('SpineItem', () {
    group('constructor', () {
      test('creates item with required idref only', () {
        const item = SpineItem(idref: 'ch1');

        expect(item.idref, equals('ch1'));
        expect(item.linear, isTrue);
        expect(item.properties, isEmpty);
      });

      test('creates item with all parameters', () {
        const item = SpineItem(
          idref: 'ch1',
          linear: false,
          properties: {'page-spread-left', 'rendition:spread-none'},
          rendition: SpineItemRendition(),
        );

        expect(item.idref, equals('ch1'));
        expect(item.linear, isFalse);
        expect(item.properties, hasLength(2));
      });

      test('defaults linear to true', () {
        const item = SpineItem(idref: 'ch1');
        expect(item.linear, isTrue);
      });

      test('defaults properties to empty set', () {
        const item = SpineItem(idref: 'ch1');
        expect(item.properties, isEmpty);
      });
    });

    group('pageSpread', () {
      test('returns left for page-spread-left property', () {
        const item = SpineItem(
          idref: 'ch1',
          properties: {'page-spread-left'},
        );
        expect(item.pageSpread, equals(PageSpread.left));
      });

      test('returns right for page-spread-right property', () {
        const item = SpineItem(
          idref: 'ch1',
          properties: {'page-spread-right'},
        );
        expect(item.pageSpread, equals(PageSpread.right));
      });

      test('returns center for page-spread-center property', () {
        const item = SpineItem(
          idref: 'ch1',
          properties: {'page-spread-center'},
        );
        expect(item.pageSpread, equals(PageSpread.center));
      });

      test('returns null when no page spread property', () {
        const item = SpineItem(idref: 'ch1');
        expect(item.pageSpread, isNull);
      });

      test('returns null for unrelated properties', () {
        const item = SpineItem(
          idref: 'ch1',
          properties: {'other-property'},
        );
        expect(item.pageSpread, isNull);
      });
    });

    group('renditionSpreadNone', () {
      test('returns true when rendition:spread-none property present', () {
        const item = SpineItem(
          idref: 'ch1',
          properties: {'rendition:spread-none'},
        );
        expect(item.renditionSpreadNone, isTrue);
      });

      test('returns false when rendition:spread-none property absent', () {
        const item = SpineItem(idref: 'ch1');
        expect(item.renditionSpreadNone, isFalse);
      });
    });

    group('Equatable', () {
      test('equal items are equal', () {
        const item1 = SpineItem(idref: 'ch1', linear: true);
        const item2 = SpineItem(idref: 'ch1', linear: true);
        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('different idrefs are not equal', () {
        const item1 = SpineItem(idref: 'ch1');
        const item2 = SpineItem(idref: 'ch2');
        expect(item1, isNot(equals(item2)));
      });

      test('different linear values are not equal', () {
        const item1 = SpineItem(idref: 'ch1', linear: true);
        const item2 = SpineItem(idref: 'ch1', linear: false);
        expect(item1, isNot(equals(item2)));
      });

      test('different properties are not equal', () {
        const item1 = SpineItem(idref: 'ch1', properties: {'a'});
        const item2 = SpineItem(idref: 'ch1', properties: {'b'});
        expect(item1, isNot(equals(item2)));
      });
    });

    group('toString', () {
      test('includes idref and linear status', () {
        const item = SpineItem(idref: 'ch1', linear: true);
        expect(item.toString(), equals('SpineItem(ch1, linear: true)'));
      });

      test('shows non-linear status', () {
        const item = SpineItem(idref: 'ch1', linear: false);
        expect(item.toString(), equals('SpineItem(ch1, linear: false)'));
      });
    });
  });

  group('PageSpread', () {
    test('has left value', () {
      expect(PageSpread.left, isNotNull);
    });

    test('has right value', () {
      expect(PageSpread.right, isNotNull);
    });

    test('has center value', () {
      expect(PageSpread.center, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(PageSpread.values, hasLength(3));
    });
  });

  group('PageProgression', () {
    test('has ltr value', () {
      expect(PageProgression.ltr, isNotNull);
    });

    test('has rtl value', () {
      expect(PageProgression.rtl, isNotNull);
    });

    test('has defaultDirection value', () {
      expect(PageProgression.defaultDirection, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(PageProgression.values, hasLength(3));
    });
  });

  group('EpubSpine', () {
    late EpubSpine spine;

    setUp(() {
      spine = const EpubSpine(
        items: [
          SpineItem(idref: 'cover', linear: false),
          SpineItem(idref: 'ch1'),
          SpineItem(idref: 'ch2'),
          SpineItem(idref: 'ch3'),
          SpineItem(idref: 'notes', linear: false),
        ],
        toc: 'ncx',
        pageProgression: PageProgression.ltr,
      );
    });

    group('constructor', () {
      test('creates spine with required items', () {
        const minimalSpine = EpubSpine(items: []);
        expect(minimalSpine.items, isEmpty);
        expect(minimalSpine.toc, isNull);
        expect(
          minimalSpine.pageProgression,
          equals(PageProgression.defaultDirection),
        );
      });

      test('creates spine with all parameters', () {
        expect(spine.items, hasLength(5));
        expect(spine.toc, equals('ncx'));
        expect(spine.pageProgression, equals(PageProgression.ltr));
      });
    });

    group('length', () {
      test('returns number of items', () {
        expect(spine.length, equals(5));
      });

      test('returns 0 for empty spine', () {
        const empty = EpubSpine(items: []);
        expect(empty.length, equals(0));
      });
    });

    group('isEmpty', () {
      test('returns false for non-empty spine', () {
        expect(spine.isEmpty, isFalse);
      });

      test('returns true for empty spine', () {
        const empty = EpubSpine(items: []);
        expect(empty.isEmpty, isTrue);
      });
    });

    group('isNotEmpty', () {
      test('returns true for non-empty spine', () {
        expect(spine.isNotEmpty, isTrue);
      });

      test('returns false for empty spine', () {
        const empty = EpubSpine(items: []);
        expect(empty.isNotEmpty, isFalse);
      });
    });

    group('operator []', () {
      test('returns item at index', () {
        expect(spine[0].idref, equals('cover'));
        expect(spine[1].idref, equals('ch1'));
        expect(spine[4].idref, equals('notes'));
      });

      test('throws on out of bounds', () {
        expect(() => spine[10], throwsRangeError);
      });
    });

    group('indexOfIdref', () {
      test('returns index for existing idref', () {
        expect(spine.indexOfIdref('ch1'), equals(1));
        expect(spine.indexOfIdref('ch3'), equals(3));
      });

      test('returns -1 for non-existing idref', () {
        expect(spine.indexOfIdref('unknown'), equals(-1));
      });

      test('returns first index when multiple not possible', () {
        expect(spine.indexOfIdref('cover'), equals(0));
      });
    });

    group('getByIdref', () {
      test('returns item for existing idref', () {
        final item = spine.getByIdref('ch2');
        expect(item, isNotNull);
        expect(item!.idref, equals('ch2'));
      });

      test('returns null for non-existing idref', () {
        final item = spine.getByIdref('unknown');
        expect(item, isNull);
      });
    });

    group('linearItems', () {
      test('returns only linear items', () {
        final linear = spine.linearItems;
        expect(linear, hasLength(3));
        expect(linear.every((i) => i.linear), isTrue);
      });

      test('preserves order', () {
        final linear = spine.linearItems;
        expect(linear[0].idref, equals('ch1'));
        expect(linear[1].idref, equals('ch2'));
        expect(linear[2].idref, equals('ch3'));
      });

      test('returns empty list when all non-linear', () {
        const nonLinearSpine = EpubSpine(items: [
          SpineItem(idref: 'a', linear: false),
          SpineItem(idref: 'b', linear: false),
        ]);
        expect(nonLinearSpine.linearItems, isEmpty);
      });
    });

    group('nonLinearItems', () {
      test('returns only non-linear items', () {
        final nonLinear = spine.nonLinearItems;
        expect(nonLinear, hasLength(2));
        expect(nonLinear.every((i) => !i.linear), isTrue);
      });

      test('returns empty list when all linear', () {
        const linearSpine = EpubSpine(items: [
          SpineItem(idref: 'a'),
          SpineItem(idref: 'b'),
        ]);
        expect(linearSpine.nonLinearItems, isEmpty);
      });
    });

    group('hasNcxReference', () {
      test('returns true when toc is set', () {
        expect(spine.hasNcxReference, isTrue);
      });

      test('returns false when toc is null', () {
        const noNcx = EpubSpine(items: []);
        expect(noNcx.hasNcxReference, isFalse);
      });
    });

    group('isRtl', () {
      test('returns true for rtl page progression', () {
        const rtlSpine = EpubSpine(
          items: [],
          pageProgression: PageProgression.rtl,
        );
        expect(rtlSpine.isRtl, isTrue);
      });

      test('returns false for ltr page progression', () {
        expect(spine.isRtl, isFalse);
      });

      test('returns false for default page progression', () {
        const defaultSpine = EpubSpine(items: []);
        expect(defaultSpine.isRtl, isFalse);
      });
    });

    group('Equatable', () {
      test('equal spines are equal', () {
        const spine1 = EpubSpine(items: [SpineItem(idref: 'ch1')]);
        const spine2 = EpubSpine(items: [SpineItem(idref: 'ch1')]);
        expect(spine1, equals(spine2));
      });

      test('different items are not equal', () {
        const spine1 = EpubSpine(items: [SpineItem(idref: 'ch1')]);
        const spine2 = EpubSpine(items: [SpineItem(idref: 'ch2')]);
        expect(spine1, isNot(equals(spine2)));
      });

      test('different toc are not equal', () {
        const spine1 = EpubSpine(items: [], toc: 'ncx1');
        const spine2 = EpubSpine(items: [], toc: 'ncx2');
        expect(spine1, isNot(equals(spine2)));
      });

      test('different page progression are not equal', () {
        const spine1 = EpubSpine(
          items: [],
          pageProgression: PageProgression.ltr,
        );
        const spine2 = EpubSpine(
          items: [],
          pageProgression: PageProgression.rtl,
        );
        expect(spine1, isNot(equals(spine2)));
      });
    });
  });
}
