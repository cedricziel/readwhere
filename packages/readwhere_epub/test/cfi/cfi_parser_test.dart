import 'package:test/test.dart';
import 'package:readwhere_epub/readwhere_epub.dart';

void main() {
  group('EpubCfi', () {
    group('parse', () {
      test('parses minimal CFI with spine only', () {
        final cfi = EpubCfi.parse('epubcfi(/6/2!)');

        expect(cfi.spineIndex, equals(0));
        expect(cfi.path, isEmpty);
        expect(cfi.hasIndirectPath, isTrue);
      });

      test('parses CFI with second spine item', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!)');

        expect(cfi.spineIndex, equals(1));
      });

      test('parses CFI with third spine item', () {
        final cfi = EpubCfi.parse('epubcfi(/6/6!)');

        expect(cfi.spineIndex, equals(2));
      });

      test('parses CFI with element path', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!/4/2)');

        expect(cfi.spineIndex, equals(1));
        expect(cfi.path, hasLength(2));
        expect(cfi.path[0].index, equals(4));
        expect(cfi.path[1].index, equals(2));
      });

      test('parses CFI with character offset', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');

        expect(cfi.spineIndex, equals(1));
        expect(cfi.characterOffset, isNotNull);
        expect(cfi.characterOffset!.offset, equals(10));
      });

      test('parses CFI with ID assertion', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!/4/2[chapter1])');

        expect(cfi.path, hasLength(2));
        expect(cfi.path[1].id, equals('chapter1'));
      });

      test('parses CFI with type assertion', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!/4[type=div])');

        expect(cfi.path, hasLength(1));
        expect(cfi.path[0].elementType, equals('div'));
      });

      test('parses CFI with multiple assertions', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!/4[intro][type=section])');

        expect(cfi.path[0].id, equals('intro'));
        expect(cfi.path[0].elementType, equals('section'));
      });

      test('parses CFI without indirect path marker', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4/2)');

        expect(cfi.spineIndex, equals(1));
        expect(cfi.hasIndirectPath, isFalse);
        expect(cfi.path, hasLength(1));
        expect(cfi.path[0].index, equals(2));
      });

      test('parses deep element path', () {
        final cfi = EpubCfi.parse('epubcfi(/6/2!/4/2/6/8/4)');

        expect(cfi.spineIndex, equals(0));
        expect(cfi.path, hasLength(5));
        expect(cfi.path.map((s) => s.index), equals([4, 2, 6, 8, 4]));
      });
    });

    group('tryParse', () {
      test('returns null for invalid CFI format', () {
        expect(EpubCfi.tryParse('invalid'), isNull);
        expect(EpubCfi.tryParse(''), isNull);
        expect(EpubCfi.tryParse('epubcfi()'), isNull);
        expect(EpubCfi.tryParse('epubcfi(/7/2!)'), isNull); // Wrong root
        expect(EpubCfi.tryParse('/6/2!'), isNull); // Missing wrapper
      });

      test('returns null for missing spine step', () {
        expect(EpubCfi.tryParse('epubcfi(/6/)'), isNull);
      });

      test('returns null for odd spine step', () {
        expect(EpubCfi.tryParse('epubcfi(/6/3!)'), isNull);
      });

      test('returns CFI for valid input', () {
        final cfi = EpubCfi.tryParse('epubcfi(/6/4!/4/2)');
        expect(cfi, isNotNull);
        expect(cfi!.spineIndex, equals(1));
      });
    });

    group('fromSpineIndex', () {
      test('creates CFI for first spine item', () {
        final cfi = EpubCfi.fromSpineIndex(0);

        expect(cfi.spineIndex, equals(0));
        expect(cfi.toString(), equals('epubcfi(/6/2!)'));
      });

      test('creates CFI for tenth spine item', () {
        final cfi = EpubCfi.fromSpineIndex(9);

        expect(cfi.spineIndex, equals(9));
        expect(cfi.toString(), equals('epubcfi(/6/20!)'));
      });

      test('throws for negative index', () {
        expect(() => EpubCfi.fromSpineIndex(-1), throwsArgumentError);
      });
    });

    group('fromElementId', () {
      test('creates CFI with element ID', () {
        final cfi = EpubCfi.fromElementId(0, 'chapter1');

        expect(cfi.spineIndex, equals(0));
        expect(cfi.path, hasLength(1));
        expect(cfi.path[0].id, equals('chapter1'));
      });

      test('throws for empty element ID', () {
        expect(() => EpubCfi.fromElementId(0, ''), throwsArgumentError);
      });

      test('throws for negative spine index', () {
        expect(() => EpubCfi.fromElementId(-1, 'test'), throwsArgumentError);
      });
    });

    group('fromElementPath', () {
      test('creates CFI from element path', () {
        final cfi = EpubCfi.fromElementPath(0, [1, 0, 2]);

        expect(cfi.spineIndex, equals(0));
        expect(cfi.path, hasLength(3));
        // 0-based to CFI: (index + 1) * 2
        expect(cfi.path[0].index, equals(4)); // (1 + 1) * 2
        expect(cfi.path[1].index, equals(2)); // (0 + 1) * 2
        expect(cfi.path[2].index, equals(6)); // (2 + 1) * 2
      });

      test('creates CFI with character offset', () {
        final cfi = EpubCfi.fromElementPath(0, [0], characterOffset: 25);

        expect(cfi.characterOffset, isNotNull);
        expect(cfi.characterOffset!.offset, equals(25));
      });

      test('creates CFI with element ID', () {
        final cfi = EpubCfi.fromElementPath(0, [0, 1], elementId: 'para1');

        expect(cfi.path.last.id, equals('para1'));
      });
    });

    group('toString (round-trip)', () {
      test('round-trips simple CFI', () {
        const original = 'epubcfi(/6/4!)';
        final cfi = EpubCfi.parse(original);
        expect(cfi.toString(), equals(original));
      });

      test('round-trips CFI with path', () {
        const original = 'epubcfi(/6/4!/4/2)';
        final cfi = EpubCfi.parse(original);
        expect(cfi.toString(), equals(original));
      });

      test('round-trips CFI with offset', () {
        const original = 'epubcfi(/6/4!/4/2:10)';
        final cfi = EpubCfi.parse(original);
        expect(cfi.toString(), equals(original));
      });

      test('round-trips CFI with ID assertion', () {
        const original = 'epubcfi(/6/4!/4/2[chapter1])';
        final cfi = EpubCfi.parse(original);
        expect(cfi.toString(), equals(original));
      });

      test('round-trips complex CFI', () {
        const original = 'epubcfi(/6/8!/4/2/6/4[section2][type=div]:42)';
        final cfi = EpubCfi.parse(original);
        expect(cfi.toString(), equals(original));
      });
    });

    group('compareTo', () {
      test('compares by spine index', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/2!)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/4!)');

        expect(cfi1.compareTo(cfi2), lessThan(0));
        expect(cfi2.compareTo(cfi1), greaterThan(0));
      });

      test('compares equal spine indices by path', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/2!/4/2)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/2!/4/4)');

        expect(cfi1.compareTo(cfi2), lessThan(0));
      });

      test('shorter path comes before longer path', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/2!/4)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/2!/4/2)');

        expect(cfi1.compareTo(cfi2), lessThan(0));
      });

      test('compares by character offset', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/2!/4:5)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/2!/4:10)');

        expect(cfi1.compareTo(cfi2), lessThan(0));
      });

      test('equal CFIs compare to zero', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');

        expect(cfi1.compareTo(cfi2), equals(0));
      });
    });

    group('comparison operators', () {
      test('< operator works', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/2!)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/4!)');

        expect(cfi1 < cfi2, isTrue);
        expect(cfi2 < cfi1, isFalse);
      });

      test('> operator works', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/4!)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/2!)');

        expect(cfi1 > cfi2, isTrue);
        expect(cfi2 > cfi1, isFalse);
      });

      test('<= operator works', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/2!)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/2!)');

        expect(cfi1 <= cfi2, isTrue);
      });

      test('>= operator works', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/4!)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/2!)');

        expect(cfi1 >= cfi2, isTrue);
      });
    });

    group('spineOnly', () {
      test('returns CFI without element path', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');
        final spineOnly = cfi.spineOnly;

        expect(spineOnly.spineIndex, equals(cfi.spineIndex));
        expect(spineOnly.path, isEmpty);
        expect(spineOnly.characterOffset, isNull);
      });
    });

    group('withoutOffset', () {
      test('returns CFI without character offset', () {
        final cfi = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');
        final noOffset = cfi.withoutOffset;

        expect(noOffset.spineIndex, equals(cfi.spineIndex));
        expect(noOffset.path, equals(cfi.path));
        expect(noOffset.characterOffset, isNull);
      });
    });

    group('equality', () {
      test('equal CFIs are equal', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');

        expect(cfi1, equals(cfi2));
        expect(cfi1.hashCode, equals(cfi2.hashCode));
      });

      test('different CFIs are not equal', () {
        final cfi1 = EpubCfi.parse('epubcfi(/6/4!/4/2:10)');
        final cfi2 = EpubCfi.parse('epubcfi(/6/4!/4/2:11)');

        expect(cfi1, isNot(equals(cfi2)));
      });
    });
  });

  group('CfiStep', () {
    test('creates step with index', () {
      const step = CfiStep(index: 4);

      expect(step.index, equals(4));
      expect(step.id, isNull);
      expect(step.elementType, isNull);
    });

    test('creates step with all properties', () {
      const step = CfiStep(index: 4, id: 'intro', elementType: 'section');

      expect(step.index, equals(4));
      expect(step.id, equals('intro'));
      expect(step.elementType, equals('section'));
    });

    test('isElement returns true for even index', () {
      const step = CfiStep(index: 4);
      expect(step.isElement, isTrue);
      expect(step.isTextNode, isFalse);
    });

    test('isTextNode returns true for odd index', () {
      const step = CfiStep(index: 3);
      expect(step.isTextNode, isTrue);
      expect(step.isElement, isFalse);
    });

    test('toString formats correctly', () {
      const step = CfiStep(index: 4, id: 'intro', elementType: 'section');
      expect(step.toString(), equals('/4[intro][type=section]'));
    });

    test('copyWith creates modified copy', () {
      const original = CfiStep(index: 4);
      final modified = original.copyWith(id: 'newId');

      expect(modified.index, equals(4));
      expect(modified.id, equals('newId'));
    });
  });

  group('CfiCharacterOffset', () {
    test('creates offset', () {
      const offset = CfiCharacterOffset(offset: 10);

      expect(offset.offset, equals(10));
      expect(offset.assertion, isNull);
    });

    test('toString formats correctly', () {
      const offset = CfiCharacterOffset(offset: 10);
      expect(offset.toString(), equals(':10'));
    });

    test('toString includes assertion', () {
      const offset = CfiCharacterOffset(
        offset: 10,
        assertion: CfiTextAssertion(before: 'hello'),
      );
      expect(offset.toString(), contains(':10'));
      expect(offset.toString(), contains('[;s='));
    });
  });

  group('CfiTextAssertion', () {
    test('creates with before text', () {
      const assertion = CfiTextAssertion(before: 'hello');

      expect(assertion.before, equals('hello'));
      expect(assertion.after, isNull);
    });

    test('creates with both before and after', () {
      const assertion = CfiTextAssertion(before: 'hello', after: 'world');

      expect(assertion.before, equals('hello'));
      expect(assertion.after, equals('world'));
    });

    test('toString formats correctly', () {
      const assertion = CfiTextAssertion(before: 'hello', after: 'world');
      expect(assertion.toString(), equals('[;s=hello,world]'));
    });

    test('escapes special characters', () {
      const assertion = CfiTextAssertion(before: 'hello[world]');
      final result = assertion.toString();
      expect(result, contains('^['));
      expect(result, contains('^]'));
    });
  });
}
