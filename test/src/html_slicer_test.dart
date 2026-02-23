import 'package:html_slicer/html_slicer.dart';
import 'package:test/test.dart';

/// Tests for the [sliceHtml] function, including scenarios with malformed HTML.
void main() {
  group('sliceHtml tests', () {
    // -----------------------------------------------
    // Original tests (preserved)
    // -----------------------------------------------

    test('No truncation needed, short text', () {
      const input = '<p>Hello world!</p>';
      final result = sliceHtml(input, 50);
      expect(
        result,
        equals('<p>Hello world!</p>'),
        reason: 'Should not truncate because length < 50',
      );
    });

    test('Basic truncation with text only', () {
      const input = 'Hello world!';
      final result = sliceHtml(input, 5);
      expect(
        result,
        equals('Hello...'),
        reason: 'Should truncate to 5 visible chars then add ellipsis',
      );
    });

    test('Basic truncation with !DOCTYPE', () {
      const input = '''
<!DOCTYPE html>
<html>
<head>
<title>Page Title</title>
</head>
<body>
<h1>This is a Heading</h1>
<p>This is a paragraph.</p>
</body>
</html>
      ''';
      final result = sliceHtml(input, 5);
      expect(
        result,
        equals('''
<!DOCTYPE html>
<html>
<head>
<title>Page Title</title>
</head>
<body>
<h1>This ...</h1></body></html>'''),
        reason: 'Should truncate to 5 visible chars then add ellipsis',
      );
    });

    test('Truncation in the middle of a paragraph', () {
      const input = '<p>Some text here that is fairly long.</p>';
      final result = sliceHtml(input, 10);
      expect(
        result,
        equals('<p>Some text ...</p>'),
        reason: 'Should truncate text inside <p>, then close the tag.',
      );
    });

    test('Truncation with newline characters (ignored in count)', () {
      const input = '''
<p>Hello
World</p>''';
      final result = sliceHtml(input, 8);
      expect(
        result,
        equals('<p>Hello\nWor...</p>'),
        reason:
            'Should include the original newline in output, but not count it',
      );
    });

    test('Preserve tag: <img> is fully preserved', () {
      const input = '''
<p>Intro text</p>
<img src="image.jpg" alt="Sample Image" />
<p>More text</p>
''';
      final result = sliceHtml(input, 12);
      expect(
        result.trim(),
        equals(
          '''
<p>Intro text</p>
<img src="image.jpg" alt="Sample Image" />
<p>Mo...</p>'''
              .trim(),
        ),
        reason: 'Should preserve <img> fully, '
            'then truncate text in next paragraph.',
      );
    });

    test('Preserve tag with matching end: <video>some content</video>', () {
      const input = '''
<video controls>
  <source src="video.mp4" type="video/mp4">
  Some text in video (not typically displayed).
</video>
<p>Following text.</p>
''';
      final result = sliceHtml(input, 5);
      expect(
        result.trim(),
        equals(
          '''
<video controls>
  <source src="video.mp4" type="video/mp4">
  Some text in video (not typically displayed).
</video>
<p>Follo...</p>'''
              .trim(),
        ),
        reason: "Entire <video> block is preserved and doesn't count toward "
            'visible text limit.',
      );
    });

    test('Case-insensitive tag matching', () {
      const input = '<P>ABC</P><BoDy>Hello!</bOdY>';
      final result = sliceHtml(input, 100);
      expect(
        result,
        equals('<P>ABC</P><BoDy>Hello!</BoDy>'),
        reason: 'Should preserve the case of originally opened tags, but match '
            'them ignoring case.',
      );
    });

    test('Mismatched tags do not pop stack incorrectly', () {
      const input = '<p><h1>Title</p></h1>';
      final result = sliceHtml(input, 100);
      expect(
        result,
        equals('<p><h1>Title</p></h1></p>'),
        reason: 'Shows how mismatched tags cause leftover closures, '
            'but no duplication.',
      );
    });

    test('Truncation on a large block of plain text ignoring newlines', () {
      const input = '''
<p>This is a
paragraph with
multiple lines
of text</p>
''';
      final result = sliceHtml(input, 20);
      expect(
        result.trim(),
        equals('<p>This is a\nparagraph w...</p>'),
        reason: 'Should count newlines as 0 and produce 20 visible '
            'characters plus ellipsis.',
      );
    });

    test('Preserve newlines', () {
      const input = '<p>Hello\nWorld</p>';
      final result = sliceHtml(input, 10);
      expect(result, '<p>Hello\nWorld</p>');
    });

    test('Remove/ignore newlines', () {
      const input = '<p>This is a\nparagraph with multiple lines</p>';
      final result = sliceHtml(input, 20, preserveNewlines: false);
      expect(result, '<p>This is a paragraph w...</p>');
    });

    // -----------------------------------------------
    // Malformed / invalid HTML tests (preserved)
    // -----------------------------------------------

    test('Missing closing tag for <p>', () {
      const input = '<p>Hello World!';
      final result = sliceHtml(input, 50);
      expect(
        result,
        equals('<p>Hello World!</p>'),
        reason: 'Should auto-close the missing </p> tag.',
      );
    });

    test('Extra closing tag with no matching open tag', () {
      const input = '<p>Hello</p></div>';
      final result = sliceHtml(input, 50);
      expect(
        result,
        equals('<p>Hello</p></div>'),
        reason:
            'Unmatched </div> is copied verbatim, no duplication or mis-pop '
            'from the stack.',
      );
    });

    // -----------------------------------------------
    // Bug fix: HTML entities (Bug #1)
    // -----------------------------------------------

    group('HTML entity handling', () {
      test('Named entity counts as one visible character', () {
        expect(
          sliceHtml('AB&amp;CD', 3),
          equals('AB&amp;...'),
          reason: '&amp; is 1 visible char, so A(1) B(2) &amp;(3) then '
              'truncate',
        );
      });

      test('Numeric decimal entity counts as one visible character', () {
        // &#65; is the letter A
        expect(
          sliceHtml('X&#65;Y', 3),
          equals('X&#65;Y'),
          reason: 'X(1) &#65;(2) Y(3) = 3 visible chars, no truncation',
        );
      });

      test('Hex entity counts as one visible character', () {
        // &#x41; is the letter A
        expect(
          sliceHtml('&#x41;BC', 2),
          equals('&#x41;B...'),
          reason: '&#x41;(1) B(2) then truncate before C',
        );
      });

      test('Bare ampersand without valid entity is a literal character', () {
        expect(
          sliceHtml('A&B', 2),
          equals('A&...'),
          reason: 'A(1) &(2) then truncate before B',
        );
      });

      test('Entity at truncation boundary', () {
        expect(
          sliceHtml('AB&lt;CD', 3),
          equals('AB&lt;...'),
          reason: 'A(1) B(2) &lt;(3) then truncate',
        );
      });

      test('Multiple entities in text', () {
        expect(
          sliceHtml('&lt;&gt;&amp;', 2),
          equals('&lt;&gt;...'),
          reason: '&lt;(1) &gt;(2) then truncate before &amp;',
        );
      });

      test('Entity inside tag attribute does not affect visible count', () {
        const input = '<a href="foo&amp;bar">Link</a>';
        final result = sliceHtml(input, 10);
        expect(
          result,
          equals('<a href="foo&amp;bar">Link</a>'),
          reason: 'Entities inside tag attributes are not visible text',
        );
      });
    });

    // -----------------------------------------------
    // Bug fix: Case-insensitive protected tag close (Bug #2)
    // -----------------------------------------------

    group('case-insensitive protected tag closing', () {
      test('Protected tag closing is case-insensitive', () {
        const input = '<Video controls>content</Video><p>Hello</p>';
        final result = sliceHtml(input, 3);
        expect(
          result,
          equals('<Video controls>content</Video><p>Hel...</p>'),
          reason: 'Should find </Video> when searching case-insensitively for '
              'closing of <video>',
        );
      });

      test('Mixed case protected tag with nested content', () {
        const input = '<AUDIO>track</AUDIO><p>Text</p>';
        final result = sliceHtml(input, 2);
        expect(
          result,
          equals('<AUDIO>track</AUDIO><p>Te...</p>'),
          reason: '<AUDIO> block should be fully preserved',
        );
      });
    });

    // -----------------------------------------------
    // Bug fix: HTML comments with > (Bug #3)
    // -----------------------------------------------

    group('HTML comment handling', () {
      test('HTML comment containing > does not break parsing', () {
        const input = '<!-- a > b --><p>Hello</p>';
        final result = sliceHtml(input, 10);
        expect(
          result,
          equals('<!-- a > b --><p>Hello</p>'),
          reason: 'Comment should be preserved intact including > inside',
        );
      });

      test('HTML comment with multiple > characters', () {
        const input = '<!-- x > y > z --><p>AB</p>';
        final result = sliceHtml(input, 10);
        expect(
          result,
          equals('<!-- x > y > z --><p>AB</p>'),
          reason: 'All > chars inside comment should be ignored',
        );
      });

      test('HTML comment with truncation after', () {
        const input = '<!-- comment --><p>Hello World</p>';
        final result = sliceHtml(input, 5);
        expect(
          result,
          equals('<!-- comment --><p>Hello...</p>'),
          reason: 'Comment preserved, then visible text truncated at 5',
        );
      });

      test('Unterminated HTML comment stops processing', () {
        const input = '<!-- no end';
        final result = sliceHtml(input, 100);
        expect(
          result,
          equals('...'),
          reason: '_findTagClose returns -1, loop breaks, '
              'then ellipsis appended since i < html.length',
        );
      });
    });

    // -----------------------------------------------
    // Bug fix: Tag attributes with > (Bug #4)
    // -----------------------------------------------

    group('tag attributes containing >', () {
      test('Double-quoted attribute with >', () {
        const input = '<div data-value="a > b">Hello</div>';
        final result = sliceHtml(input, 10);
        expect(
          result,
          equals('<div data-value="a > b">Hello</div>'),
          reason: '> inside double quotes should not close the tag',
        );
      });

      test('Double-quoted attribute with > and truncation', () {
        const input = '<div data-value="a > b">Hello World</div>';
        final result = sliceHtml(input, 5);
        expect(
          result,
          equals('<div data-value="a > b">Hello...</div>'),
          reason: 'Tag parsed correctly despite > in attribute, then truncated',
        );
      });

      test('Single-quoted attribute with >', () {
        const input = "<div data-value='a > b'>Hello</div>";
        final result = sliceHtml(input, 3);
        expect(
          result,
          equals("<div data-value='a > b'>Hel...</div>"),
          reason: '> inside single quotes should not close the tag',
        );
      });
    });

    // -----------------------------------------------
    // Bug fix: CRLF handling (Bug #5)
    // -----------------------------------------------

    group('CRLF handling', () {
      test('CRLF is treated as single newline', () {
        const input = 'Hello\r\nWorld';
        final result = sliceHtml(input, 10);
        expect(
          result,
          equals('Hello\nWorld'),
          reason: r'\r\n should produce a single \n in output',
        );
      });

      test('CRLF with preserveNewlines false produces single space', () {
        const input = 'A\r\nB';
        final result = sliceHtml(input, 10, preserveNewlines: false);
        expect(
          result,
          equals('A B'),
          reason: r'\r\n should produce a single space, not two',
        );
      });

      test('Lone CR is preserved when preserveNewlines is true', () {
        const input = 'A\rB';
        final result = sliceHtml(input, 10);
        expect(
          result,
          equals('A\rB'),
          reason: r'Lone \r should be preserved as-is',
        );
      });

      test('Lone CR replaced with space when preserveNewlines is false', () {
        const input = 'A\rB';
        final result = sliceHtml(input, 10, preserveNewlines: false);
        expect(
          result,
          equals('A B'),
          reason: r'Lone \r should become a space',
        );
      });
    });

    // -----------------------------------------------
    // Improvement: Custom preserveTags (Improvement #6)
    // -----------------------------------------------

    group('custom preserveTags', () {
      test('Custom preserveTags set is respected', () {
        const input = '<code>x = 1</code><p>Hello</p>';
        final result = sliceHtml(
          input,
          3,
          preserveTags: const {'code'},
        );
        expect(
          result,
          equals('<code>x = 1</code><p>Hel...</p>'),
          reason: '<code> should be preserved as whole block',
        );
      });

      test('Empty preserveTags means nothing is preserved as block', () {
        const input = '<video controls>content</video><p>Hi</p>';
        final result = sliceHtml(
          input,
          5,
          preserveTags: const {},
        );
        // <video> is not preserved; its inner text "content" counts
        expect(
          result,
          equals('<video controls>conte...</video>'),
          reason: 'With empty preserveTags, video content counts toward limit',
        );
      });

      test('defaultPreserveTags constant has expected values', () {
        expect(
          defaultPreserveTags,
          equals({'title', 'head', 'img', 'video', 'audio', 'iframe'}),
        );
      });
    });

    // -----------------------------------------------
    // Improvement: Custom ellipsis (Improvement #7)
    // -----------------------------------------------

    group('custom ellipsis', () {
      test('Custom ellipsis string', () {
        expect(
          sliceHtml('Hello World', 5, ellipsis: '~'),
          equals('Hello~'),
        );
      });

      test('Empty ellipsis string', () {
        expect(
          sliceHtml('Hello World', 5, ellipsis: ''),
          equals('Hello'),
        );
      });

      test('Unicode ellipsis character', () {
        expect(
          sliceHtml('Hello World', 5, ellipsis: '\u2026'),
          equals('Hello\u2026'),
        );
      });

      test('Custom preserveTags with custom ellipsis', () {
        const input = '<video>vid</video><p>Hello World</p>';
        final result = sliceHtml(
          input,
          5,
          ellipsis: '[...]',
        );
        expect(
          result,
          equals('<video>vid</video><p>Hello[...]</p>'),
        );
      });
    });

    // -----------------------------------------------
    // Improvement: Input validation (Improvement #8)
    // -----------------------------------------------

    group('input validation', () {
      test('Negative maxLength throws ArgumentError', () {
        expect(
          () => sliceHtml('<p>Hello</p>', -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Empty html returns empty string', () {
        expect(sliceHtml('', 10), equals(''));
      });

      test('maxLength of zero with plain text', () {
        expect(
          sliceHtml('Hello', 0),
          equals('...'),
          reason: 'No visible chars allowed, but ellipsis is appended',
        );
      });

      test('maxLength of zero returns ellipsis only', () {
        expect(
          sliceHtml('<p>Hello</p>', 0),
          equals('...'),
          reason: 'With maxLength 0, loop never executes; only ellipsis output',
        );
      });
    });
  });
}
