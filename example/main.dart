// ignore_for_file: avoid_print

import 'package:html_slicer/html_slicer.dart';

void main() {
  // --- Basic truncation ---
  print('=== Basic Truncation ===');
  const paragraph = '<p>This is a fairly long paragraph of text.</p>';
  print(sliceHtml(paragraph, 20));
  // Output: <p>This is a fairly lo...</p>

  // --- Preserving HTML structure ---
  print('\n=== Nested Tags ===');
  const nested = '<div><p>Hello <strong>World</strong> and more text.</p></div>';
  print(sliceHtml(nested, 11));
  // Output: <div><p>Hello <strong>World</strong>...</p></div>

  // --- DOCTYPE and full document ---
  print('\n=== Full HTML Document ===');
  const document = '''
<!DOCTYPE html>
<html>
<head><title>My Page</title></head>
<body>
<h1>Welcome</h1>
<p>This is the content of the page.</p>
</body>
</html>''';
  print(sliceHtml(document, 15));
  // <title> and <head> blocks are preserved without counting toward the limit

  // --- Media tags preserved as whole blocks ---
  print('\n=== Preserved Media Tags ===');
  const media = '''
<p>Introduction</p>
<img src="photo.jpg" alt="A photo" />
<video controls>
  <source src="clip.mp4" type="video/mp4">
  Your browser does not support video.
</video>
<p>Conclusion of the article with additional details.</p>''';
  print(sliceHtml(media, 20));
  // <img> and <video> blocks are fully preserved; only visible text is counted

  // --- Custom preserve tags ---
  print('\n=== Custom Preserve Tags ===');
  const code = '<code>const x = 42;</code><p>See the code above for details.</p>';
  print(sliceHtml(code, 10, preserveTags: {...defaultPreserveTags, 'code'}));
  // <code> block is preserved as a whole; only "See the co" counts

  // --- Newline handling ---
  print('\n=== Preserve Newlines (default) ===');
  const multiline = '<p>Line one\nLine two\nLine three</p>';
  print(sliceHtml(multiline, 16));
  // Newlines appear in output but do not count toward visible length

  print('\n=== Replace Newlines with Spaces ===');
  print(sliceHtml(multiline, 16, preserveNewlines: false));
  // Newlines become spaces in the output

  // --- HTML entities ---
  print('\n=== HTML Entities ===');
  const entities = '<p>5 &gt; 3 &amp; 3 &lt; 5</p>';
  print(sliceHtml(entities, 9));
  // Each entity (&gt; &amp; &lt;) counts as one visible character

  // --- Custom ellipsis ---
  print('\n=== Custom Ellipsis ===');
  const text = '<p>Hello World</p>';
  print(sliceHtml(text, 5, ellipsis: '\u2026')); // unicode …
  print(sliceHtml(text, 5, ellipsis: ' [more]'));
  print(sliceHtml(text, 5, ellipsis: '')); // no ellipsis

  // --- Attributes containing special characters ---
  print('\n=== Attributes with > Character ===');
  const attrHtml = '<div data-expr="a > b" title="x < y">Content here</div>';
  print(sliceHtml(attrHtml, 7));
  // Tags with > inside quoted attributes are parsed correctly

  // --- HTML comments ---
  print('\n=== HTML Comments ===');
  const commented = '<!-- TODO: review --><p>Published content</p>';
  print(sliceHtml(commented, 10));
  // Comments are preserved as-is and do not count toward visible length

  // --- Malformed HTML auto-repair ---
  print('\n=== Auto-closing Unclosed Tags ===');
  const unclosed = '<div><p><strong>Bold text';
  print(sliceHtml(unclosed, 50));
  // Output: <div><p><strong>Bold text</strong></p></div>

  // --- Empty preserve tags (nothing preserved as block) ---
  print('\n=== No Preserved Tags ===');
  const vid = '<video>fallback text</video><p>After</p>';
  print(sliceHtml(vid, 8, preserveTags: {}));
  // With empty preserveTags, video inner text counts toward the limit
}
