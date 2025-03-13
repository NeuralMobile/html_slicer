import 'package:html_slicer/html_slicer.dart';
import 'package:test/test.dart';

/// Tests for the [sliceHtml] function, including scenarios with malformed HTML.
void main() {
  group('truncateHtml tests', () {
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
        reason: 'Entire <video> block is preserved and doesn’t count toward '
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
      expect(result, '<p>Hello\nWorld...</p>');
    });

    test('Remove/ignore newlines', () {
      const input = '<p>This is a\nparagraph with multiple lines</p>';
      final result = sliceHtml(input, 20, preserveNewlines: false);
      expect(result, '<p>This is a paragraph w...</p>');
    });

    // ---------------------------------------
    // Malformed / invalid HTML tests
    // ---------------------------------------

    test('Missing closing tag for <p>', () {
      // The HTML has an opening <p> but no corresponding </p>.
      // The function should still produce valid HTML by closing the tag
      // at the end,
      // appending '</p>' automatically. Visible text is only 12 chars: "Hello World!"
      const input = '<p>Hello World!';
      final result = sliceHtml(input, 50);
      expect(
        result,
        equals('<p>Hello World!</p>'),
        reason: 'Should auto-close the missing </p> tag.',
      );
    });

    test('Extra closing tag with no matching open tag', () {
      // The HTML has an extra </div> that does not match anything on the stack.
      // The library should just copy the unmatched closing tag as-is,
      // without popping anything from the stack, then close any unclosed tags
      // at the end.
      const input = '<p>Hello</p></div>';
      final result = sliceHtml(input, 50);
      // The <p> gets closed properly, then we see </div> which doesn't match the top of the stack.
      // So we just output it.
      // The final output is '<p>Hello</p></div>'
      // plus no leftover unclosed tags.
      expect(
        result,
        equals('<p>Hello</p></div>'),
        reason:
            'Unmatched </div> is copied verbatim, no duplication or mis-pop from the stack.',
      );
    });
  });
}
