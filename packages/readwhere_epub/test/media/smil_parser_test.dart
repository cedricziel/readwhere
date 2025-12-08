import 'package:readwhere_epub/src/media/smil_models.dart';
import 'package:readwhere_epub/src/media/smil_parser.dart';
import 'package:test/test.dart';

void main() {
  group('TextReference', () {
    test('creates with src', () {
      const ref = TextReference(src: 'chapter1.xhtml#p1');

      expect(ref.src, 'chapter1.xhtml#p1');
    });

    test('href returns document without fragment', () {
      const ref = TextReference(src: 'chapter1.xhtml#p1');

      expect(ref.href, 'chapter1.xhtml');
    });

    test('href returns full src when no fragment', () {
      const ref = TextReference(src: 'chapter1.xhtml');

      expect(ref.href, 'chapter1.xhtml');
    });

    test('elementId returns fragment identifier', () {
      const ref = TextReference(src: 'chapter1.xhtml#para-5');

      expect(ref.elementId, 'para-5');
    });

    test('elementId returns null when no fragment', () {
      const ref = TextReference(src: 'chapter1.xhtml');

      expect(ref.elementId, isNull);
    });

    test('elementId returns null for trailing hash', () {
      const ref = TextReference(src: 'chapter1.xhtml#');

      expect(ref.elementId, isNull);
    });

    test('equality', () {
      const r1 = TextReference(src: 'a.xhtml#p1');
      const r2 = TextReference(src: 'a.xhtml#p1');
      const r3 = TextReference(src: 'a.xhtml#p2');

      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
    });
  });

  group('AudioClip', () {
    test('creates with required fields', () {
      const clip = AudioClip(
        src: 'audio/ch1.mp3',
        clipBegin: Duration(seconds: 5),
        clipEnd: Duration(seconds: 10),
      );

      expect(clip.src, 'audio/ch1.mp3');
      expect(clip.clipBegin, const Duration(seconds: 5));
      expect(clip.clipEnd, const Duration(seconds: 10));
    });

    test('duration calculates correctly', () {
      const clip = AudioClip(
        src: 'audio.mp3',
        clipBegin: Duration(seconds: 5, milliseconds: 500),
        clipEnd: Duration(seconds: 10, milliseconds: 200),
      );

      expect(clip.duration, const Duration(seconds: 4, milliseconds: 700));
    });

    test('equality', () {
      const c1 = AudioClip(
        src: 'a.mp3',
        clipBegin: Duration(seconds: 0),
        clipEnd: Duration(seconds: 5),
      );
      const c2 = AudioClip(
        src: 'a.mp3',
        clipBegin: Duration(seconds: 0),
        clipEnd: Duration(seconds: 5),
      );
      const c3 = AudioClip(
        src: 'a.mp3',
        clipBegin: Duration(seconds: 0),
        clipEnd: Duration(seconds: 10),
      );

      expect(c1, equals(c2));
      expect(c1, isNot(equals(c3)));
    });
  });

  group('SmilParallel', () {
    test('creates minimal', () {
      const par = SmilParallel();

      expect(par.id, isNull);
      expect(par.textRef, isNull);
      expect(par.audio, isNull);
      expect(par.text, isNull);
      expect(par.hasAudio, isFalse);
      expect(par.hasText, isFalse);
    });

    test('creates with all fields', () {
      const par = SmilParallel(
        id: 'p1',
        textRef: 'chapter1.xhtml#para1',
        audio: AudioClip(
          src: 'audio.mp3',
          clipBegin: Duration.zero,
          clipEnd: Duration(seconds: 5),
        ),
        text: TextReference(src: 'chapter1.xhtml#para1'),
      );

      expect(par.id, 'p1');
      expect(par.textRef, 'chapter1.xhtml#para1');
      expect(par.hasAudio, isTrue);
      expect(par.hasText, isTrue);
    });

    test('effectiveTextRef prefers text.src over textRef', () {
      const par = SmilParallel(
        textRef: 'from-attribute',
        text: TextReference(src: 'from-element'),
      );

      expect(par.effectiveTextRef, 'from-element');
    });

    test('effectiveTextRef falls back to textRef', () {
      const par = SmilParallel(textRef: 'from-attribute');

      expect(par.effectiveTextRef, 'from-attribute');
    });
  });

  group('SmilSequence', () {
    test('creates empty', () {
      const seq = SmilSequence(id: 's1');

      expect(seq.id, 's1');
      expect(seq.isEmpty, isTrue);
      expect(seq.length, 0);
    });

    test('creates with children', () {
      const seq = SmilSequence(
        id: 's1',
        children: [
          SmilParallel(id: 'p1'),
          SmilParallel(id: 'p2'),
        ],
      );

      expect(seq.length, 2);
      expect(seq.isNotEmpty, isTrue);
    });

    test('flattenedParallels flattens nested sequences', () {
      const seq = SmilSequence(
        children: [
          SmilParallel(id: 'p1'),
          SmilSequence(children: [
            SmilParallel(id: 'p2'),
            SmilParallel(id: 'p3'),
          ]),
          SmilParallel(id: 'p4'),
        ],
      );

      final parallels = seq.flattenedParallels;

      expect(parallels.length, 4);
      expect(parallels.map((p) => p.id), ['p1', 'p2', 'p3', 'p4']);
    });
  });

  group('MediaOverlay', () {
    test('creates minimal', () {
      const overlay = MediaOverlay(id: 'mo1', href: 'chapter1.smil');

      expect(overlay.id, 'mo1');
      expect(overlay.href, 'chapter1.smil');
      expect(overlay.totalDuration, isNull);
      expect(overlay.isEmpty, isTrue);
      expect(overlay.syncPointCount, 0);
    });

    test('allParallels flattens elements', () {
      const overlay = MediaOverlay(
        id: 'mo1',
        href: 'chapter1.smil',
        elements: [
          SmilParallel(id: 'p1'),
          SmilSequence(children: [
            SmilParallel(id: 'p2'),
            SmilParallel(id: 'p3'),
          ]),
        ],
      );

      expect(overlay.allParallels.length, 3);
      expect(overlay.syncPointCount, 3);
    });

    test('audioSources collects unique sources', () {
      const overlay = MediaOverlay(
        id: 'mo1',
        href: 'chapter1.smil',
        elements: [
          SmilParallel(
            audio: AudioClip(
              src: 'audio1.mp3',
              clipBegin: Duration.zero,
              clipEnd: Duration(seconds: 5),
            ),
          ),
          SmilParallel(
            audio: AudioClip(
              src: 'audio1.mp3',
              clipBegin: Duration(seconds: 5),
              clipEnd: Duration(seconds: 10),
            ),
          ),
          SmilParallel(
            audio: AudioClip(
              src: 'audio2.mp3',
              clipBegin: Duration.zero,
              clipEnd: Duration(seconds: 5),
            ),
          ),
        ],
      );

      expect(overlay.audioSources, {'audio1.mp3', 'audio2.mp3'});
    });

    test('findByTextId finds matching parallels', () {
      const overlay = MediaOverlay(
        id: 'mo1',
        href: 'chapter1.smil',
        elements: [
          SmilParallel(id: 'p1', textRef: 'chapter.xhtml#para1'),
          SmilParallel(id: 'p2', textRef: 'chapter.xhtml#para2'),
          SmilParallel(id: 'p3', textRef: 'chapter.xhtml#para1'),
        ],
      );

      final matches = overlay.findByTextId('para1');

      expect(matches.length, 2);
      expect(matches.map((p) => p.id), ['p1', 'p3']);
    });

    test('findAtTime finds correct parallel', () {
      const overlay = MediaOverlay(
        id: 'mo1',
        href: 'chapter1.smil',
        elements: [
          SmilParallel(
            id: 'p1',
            audio: AudioClip(
              src: 'audio.mp3',
              clipBegin: Duration.zero,
              clipEnd: Duration(seconds: 5),
            ),
          ),
          SmilParallel(
            id: 'p2',
            audio: AudioClip(
              src: 'audio.mp3',
              clipBegin: Duration(seconds: 5),
              clipEnd: Duration(seconds: 10),
            ),
          ),
        ],
      );

      expect(overlay.findAtTime(const Duration(seconds: 2))?.id, 'p1');
      expect(overlay.findAtTime(const Duration(seconds: 7))?.id, 'p2');
      expect(overlay.findAtTime(const Duration(seconds: 15)), isNull);
    });
  });

  group('SmilParser', () {
    group('parseClipTime', () {
      test('parses clock value hh:mm:ss.mmm', () {
        expect(
          SmilParser.parseClipTime('01:23:45.678'),
          const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678),
        );
      });

      test('parses clock value mm:ss.mmm', () {
        expect(
          SmilParser.parseClipTime('05:30.500'),
          const Duration(minutes: 5, seconds: 30, milliseconds: 500),
        );
      });

      test('parses clock value ss.mmm', () {
        expect(
          SmilParser.parseClipTime('45.250'),
          const Duration(seconds: 45, milliseconds: 250),
        );
      });

      test('parses clock value without milliseconds', () {
        expect(
          SmilParser.parseClipTime('01:30'),
          const Duration(minutes: 1, seconds: 30),
        );
      });

      test('parses seconds with s suffix', () {
        expect(
          SmilParser.parseClipTime('83.5s'),
          const Duration(seconds: 83, milliseconds: 500),
        );
      });

      test('parses milliseconds with ms suffix', () {
        expect(
          SmilParser.parseClipTime('5000ms'),
          const Duration(seconds: 5),
        );
      });

      test('parses minutes with min suffix', () {
        expect(
          SmilParser.parseClipTime('1.5min'),
          const Duration(minutes: 1, seconds: 30),
        );
      });

      test('parses hours with h suffix', () {
        expect(
          SmilParser.parseClipTime('0.5h'),
          const Duration(minutes: 30),
        );
      });

      test('handles partial milliseconds', () {
        // .5 should be 500ms, not 5ms
        expect(
          SmilParser.parseClipTime('0:00.5'),
          const Duration(milliseconds: 500),
        );
      });

      test('returns zero for empty string', () {
        expect(SmilParser.parseClipTime(''), Duration.zero);
      });

      test('returns zero for invalid format', () {
        expect(SmilParser.parseClipTime('invalid'), Duration.zero);
      });
    });

    test('parses simple SMIL document', () {
      const smilContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<smil xmlns="http://www.w3.org/ns/SMIL" xmlns:epub="http://www.idpf.org/2007/ops" version="3.0">
  <head>
    <meta name="duration" content="00:05:30.000"/>
  </head>
  <body>
    <par id="p1" epub:textref="chapter1.xhtml#para1">
      <audio src="audio/chapter1.mp3" clipBegin="00:00:00.000" clipEnd="00:00:05.234"/>
      <text src="chapter1.xhtml#para1"/>
    </par>
    <par id="p2" epub:textref="chapter1.xhtml#para2">
      <audio src="audio/chapter1.mp3" clipBegin="00:00:05.234" clipEnd="00:00:10.567"/>
      <text src="chapter1.xhtml#para2"/>
    </par>
  </body>
</smil>
''';

      final overlay = SmilParser.parse(smilContent, 'mo1', 'chapter1.smil');

      expect(overlay, isNotNull);
      expect(overlay!.id, 'mo1');
      expect(overlay.href, 'chapter1.smil');
      expect(overlay.totalDuration, const Duration(minutes: 5, seconds: 30));
      expect(overlay.syncPointCount, 2);

      final p1 = overlay.allParallels[0];
      expect(p1.id, 'p1');
      expect(p1.audio?.src, 'audio/chapter1.mp3');
      expect(p1.audio?.clipBegin, Duration.zero);
      expect(p1.audio?.clipEnd, const Duration(seconds: 5, milliseconds: 234));
      expect(p1.text?.src, 'chapter1.xhtml#para1');
    });

    test('parses SMIL with sequences', () {
      const smilContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<smil xmlns="http://www.w3.org/ns/SMIL" version="3.0">
  <body>
    <seq id="s1">
      <par id="p1">
        <audio src="audio.mp3" clipBegin="0s" clipEnd="5s"/>
      </par>
      <par id="p2">
        <audio src="audio.mp3" clipBegin="5s" clipEnd="10s"/>
      </par>
    </seq>
  </body>
</smil>
''';

      final overlay = SmilParser.parse(smilContent, 'mo1', 'chapter1.smil');

      expect(overlay, isNotNull);
      expect(overlay!.elements.length, 1);
      expect(overlay.elements[0], isA<SmilSequence>());

      final seq = overlay.elements[0] as SmilSequence;
      expect(seq.id, 's1');
      expect(seq.children.length, 2);

      expect(overlay.allParallels.length, 2);
    });

    test('parses SMIL without namespaces', () {
      const smilContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<smil version="3.0">
  <body>
    <par id="p1">
      <audio src="audio.mp3" clipBegin="0s" clipEnd="5s"/>
    </par>
  </body>
</smil>
''';

      final overlay = SmilParser.parse(smilContent, 'mo1', 'chapter1.smil');

      expect(overlay, isNotNull);
      expect(overlay!.syncPointCount, 1);
    });

    test('returns null for invalid XML', () {
      final overlay =
          SmilParser.parse('<not valid xml', 'mo1', 'chapter1.smil');

      expect(overlay, isNull);
    });

    test('handles missing audio clipEnd', () {
      const smilContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<smil version="3.0">
  <body>
    <par id="p1">
      <audio src="audio.mp3" clipBegin="5s"/>
    </par>
  </body>
</smil>
''';

      final overlay = SmilParser.parse(smilContent, 'mo1', 'chapter1.smil');
      expect(overlay, isNotNull);

      final audio = overlay!.allParallels[0].audio;
      expect(audio?.clipBegin, const Duration(seconds: 5));
      expect(
          audio?.clipEnd, const Duration(seconds: 5)); // Defaults to clipBegin
    });

    test('handles audio without src', () {
      const smilContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<smil version="3.0">
  <body>
    <par id="p1">
      <audio clipBegin="0s" clipEnd="5s"/>
    </par>
  </body>
</smil>
''';

      final overlay = SmilParser.parse(smilContent, 'mo1', 'chapter1.smil');
      expect(overlay, isNotNull);
      expect(overlay!.allParallels[0].audio, isNull);
    });

    test('parses nested sequences', () {
      const smilContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<smil version="3.0">
  <body>
    <seq id="outer">
      <par id="p1">
        <audio src="a.mp3" clipBegin="0s" clipEnd="5s"/>
      </par>
      <seq id="inner">
        <par id="p2">
          <audio src="a.mp3" clipBegin="5s" clipEnd="10s"/>
        </par>
      </seq>
    </seq>
  </body>
</smil>
''';

      final overlay = SmilParser.parse(smilContent, 'mo1', 'chapter1.smil');

      expect(overlay, isNotNull);
      expect(overlay!.allParallels.length, 2);
      expect(overlay.allParallels.map((p) => p.id), ['p1', 'p2']);
    });
  });
}
