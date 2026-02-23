import 'dart:math';

import 'package:html_slicer/html_slicer.dart';
import 'package:test/test.dart';

void main() {
  group('sliceHtml boundary behavior', () {
    test(
      'does not append ellipsis when max length equals visible text in HTML',
      () {
        const input = '<p>Hello</p>';
        final result = sliceHtml(input, 5);
        expect(result, equals('<p>Hello</p>'));
      },
    );

    test('does not append ellipsis on exact entity boundary', () {
      const input = '<p>A&amp;B</p>';
      final result = sliceHtml(input, 3);
      expect(result, equals('<p>A&amp;B</p>'));
    });

    test('appends ellipsis when one additional visible character exists', () {
      const input = '<p>Hello!</p>';
      final result = sliceHtml(input, 5);
      expect(result, equals('<p>Hello...</p>'));
    });

    test('does not append ellipsis when only trailing tags/comments remain',
        () {
      const input = '<p>Hello</p><!--x-->';
      final result = sliceHtml(input, 5);
      expect(result, equals('<p>Hello</p><!--x-->'));
    });

    test('appends ellipsis when visible text remains after trailing newline',
        () {
      const input = 'Hello\nX';
      final result = sliceHtml(input, 5);
      expect(result, equals('Hello\n...'));
    });

    test('does not append ellipsis when only trailing preserved block remains',
        () {
      const input = 'Hello<video>v</video>';
      final result = sliceHtml(input, 5);
      expect(result, equals('Hello<video>v</video>'));
    });
  });

  group('sliceHtml preserveTags behavior', () {
    test('preserves full outer block for nested protected tags', () {
      const input = '<video>outer<video>inner</video>end</video><p>Hi</p>';
      final result = sliceHtml(input, 1);
      expect(
        result,
        equals('<video>outer<video>inner</video>end</video><p>H...</p>'),
      );
    });

    test('matches custom preserveTags case-insensitively', () {
      const input = '<code>1234</code><p>ABCD</p>';
      final result = sliceHtml(input, 2, preserveTags: const {'CODE'});
      expect(result, equals('<code>1234</code><p>AB...</p>'));
    });
  });

  group('sliceHtml entity behavior', () {
    test('treats uppercase hex entity prefix as a single visible character',
        () {
      const input = 'A&#X41;B';
      final result = sliceHtml(input, 2);
      expect(result, equals('A&#X41;...'));
    });

    test('preserves long entity sequences up to boundary', () {
      const input = '&amp;&lt;&gt;&quot;';
      final result = sliceHtml(input, 3);
      expect(result, equals('&amp;&lt;&gt;...'));
    });
  });

  group('sliceHtml maxLength zero behavior', () {
    test('returns empty string when maxLength is zero and ellipsis is empty',
        () {
      const input = 'Hello';
      final result = sliceHtml(input, 0, ellipsis: '');
      expect(result, isEmpty);
    });
  });

  group('sliceHtml stress and fuzzing', () {
    test('handles deep nesting while keeping tag counts balanced', () {
      const depth = 300;
      final opening = List.generate(depth, (_) => '<span>').join();
      final closing = List.generate(depth, (_) => '</span>').join();
      final input = '${opening}abcdefghijklmnopqrstuvwxyz$closing';
      final result = sliceHtml(input, 8);

      final openCount = RegExp('<span>').allMatches(result).length;
      final closeCount = RegExp('</span>').allMatches(result).length;
      expect(openCount, equals(depth));
      expect(closeCount, equals(depth));
      expect(result, contains('abcdefgh...'));
    });

    test('handles very large mixed input without throwing', () {
      const block = '<p>Hello &amp; goodbye</p><img src="a.jpg" /><div>x</div>';
      final input = List.filled(5000, block).join();
      expect(() => sliceHtml(input, 2000), returnsNormally);
    });

    test('does not throw for randomized malformed HTML-like snippets', () {
      final random = Random(42);
      for (var i = 0; i < 1000; i++) {
        final input = _randomHtmlish(random, maxLength: 120);
        final maxLength = random.nextInt(30);
        expect(
          () => sliceHtml(
            input,
            maxLength,
            preserveNewlines: random.nextBool(),
            ellipsis: random.nextBool() ? '...' : '~',
          ),
          returnsNormally,
          reason: 'Failed on iteration $i for input: $input',
        );
      }
    });
  });
}

String _randomHtmlish(Random random, {required int maxLength}) {
  const alphabet = [
    '<',
    '>',
    '/',
    '!',
    '-',
    '=',
    '"',
    "'",
    '&',
    ';',
    'a',
    'b',
    'c',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    ' ',
    '\n',
    '\r',
  ];

  final length = random.nextInt(maxLength + 1);
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }
  return buffer.toString();
}
