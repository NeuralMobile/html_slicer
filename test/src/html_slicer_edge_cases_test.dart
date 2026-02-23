import 'package:html_slicer/html_slicer.dart';
import 'package:test/test.dart';

void main() {
  // ===========================================================================
  // 1. Boundary & Off-by-one Tests
  // ===========================================================================
  group('boundary & off-by-one', () {
    test('maxLength exactly equals visible char count → no ellipsis', () {
      expect(sliceHtml('ABCDE', 5), equals('ABCDE'));
    });

    test('maxLength one less than visible count → ellipsis', () {
      expect(sliceHtml('ABCDE', 4), equals('ABCD...'));
    });

    test('maxLength one more than visible count → no ellipsis', () {
      expect(sliceHtml('ABCDE', 6), equals('ABCDE'));
    });

    test('maxLength = 1 on single char → no ellipsis', () {
      expect(sliceHtml('A', 1), equals('A'));
    });

    test('maxLength = 1 on two chars → ellipsis', () {
      expect(sliceHtml('AB', 1), equals('A...'));
    });

    test('maxLength larger than input → no ellipsis', () {
      expect(sliceHtml('Hello', 1000), equals('Hello'));
    });

    test('exact match with tags → no ellipsis, tags closed', () {
      expect(sliceHtml('<b>Hi</b>', 2), equals('<b>Hi</b>'));
    });

    test('one char over with tags → ellipsis before close', () {
      expect(sliceHtml('<b>Hi!</b>', 2), equals('<b>Hi...</b>'));
    });

    test('maxLength 0 returns just ellipsis', () {
      expect(sliceHtml('Hello', 0), equals('...'));
    });

    test('maxLength 0 with custom empty ellipsis returns empty', () {
      expect(sliceHtml('Hello', 0, ellipsis: ''), equals(''));
    });

    test('maxLength 0 with tags returns just ellipsis', () {
      expect(sliceHtml('<p>Hello</p>', 0), equals('...'));
    });

    test('empty input returns empty regardless of maxLength', () {
      expect(sliceHtml('', 0), equals(''));
      expect(sliceHtml('', 10), equals(''));
      expect(sliceHtml('', 1000), equals(''));
    });

    test('negative maxLength throws ArgumentError', () {
      expect(() => sliceHtml('x', -1), throwsA(isA<ArgumentError>()));
      expect(() => sliceHtml('x', -100), throwsA(isA<ArgumentError>()));
    });
  });

  // ===========================================================================
  // 2. Newline & Whitespace Counting
  // ===========================================================================
  group('newline & whitespace counting', () {
    test('newlines are not counted as visible characters', () {
      expect(sliceHtml('AB\nCD\nEF', 6), equals('AB\nCD\nEF'));
    });

    test('newlines not counted — truncation happens on visible only', () {
      expect(sliceHtml('AB\nCD\nEFG', 6), equals('AB\nCD\nEF...'));
    });

    test('spaces ARE counted as visible characters', () {
      expect(sliceHtml('A B C', 3), equals('A B...'));
    });

    test('tabs ARE counted as visible characters', () {
      expect(sliceHtml('A\tB', 2), equals('A\t...'));
    });

    test('only newlines → no visible chars, no ellipsis', () {
      expect(sliceHtml('\n\n\n', 5), equals('\n\n\n'));
    });

    test('only spaces → all visible, truncation applies', () {
      expect(sliceHtml('     ', 3), equals('   ...'));
    });

    test('text with leading newlines', () {
      expect(sliceHtml('\n\nHello', 3), equals('\n\nHel...'));
    });

    test('text with trailing newlines', () {
      expect(sliceHtml('Hello\n\n', 5), equals('Hello\n\n'));
    });

    test('CRLF at end of text → treated as single newline', () {
      expect(sliceHtml('Hello\r\n', 5), equals('Hello\n'));
    });

    test('multiple CRLFs → each becomes single newline', () {
      expect(sliceHtml('A\r\nB\r\nC', 3), equals('A\nB\nC'));
    });

    test('CRLF with preserveNewlines false → single space', () {
      expect(
        sliceHtml('A\r\nB\r\nC', 3, preserveNewlines: false),
        equals('A B C'),
      );
    });

    test('lone CR followed by non-LF character', () {
      expect(sliceHtml('A\rB', 2), equals('A\rB'));
    });

    test('lone CR with preserveNewlines false → space', () {
      expect(sliceHtml('A\rB', 2, preserveNewlines: false), equals('A B'));
    });

    test('mixed CRLF, LF, and lone CR', () {
      expect(sliceHtml('A\r\nB\nC\rD', 4), equals('A\nB\nC\rD'));
    });

    test('newlines inside tags are not counted', () {
      expect(
        sliceHtml('<p>\nHello\n</p>', 5),
        equals('<p>\nHello\n</p>'),
      );
    });

    test('preserveNewlines false replaces LF with space', () {
      expect(
        sliceHtml('Hello\nWorld', 10, preserveNewlines: false),
        equals('Hello World'),
      );
    });
  });

  // ===========================================================================
  // 3. HTML Entity Edge Cases
  // ===========================================================================
  group('HTML entity edge cases', () {
    test('named entity counts as one visible char', () {
      expect(sliceHtml('&amp;', 1), equals('&amp;'));
    });

    test('multiple entities each count as one', () {
      expect(sliceHtml('&amp;&lt;&gt;', 3), equals('&amp;&lt;&gt;'));
    });

    test('entity truncation at boundary', () {
      expect(sliceHtml('&amp;&lt;&gt;', 2), equals('&amp;&lt;...'));
    });

    test('decimal numeric entity', () {
      expect(sliceHtml('&#65;&#66;', 2), equals('&#65;&#66;'));
    });

    test('hex entity lowercase x', () {
      expect(sliceHtml('&#x41;X', 2), equals('&#x41;X'));
    });

    test('hex entity uppercase X', () {
      expect(sliceHtml('&#X41;X', 2), equals('&#X41;X'));
    });

    test('bare & is treated as single visible char', () {
      expect(sliceHtml('A&B', 2), equals('A&...'));
      expect(sliceHtml('A&B', 3), equals('A&B'));
    });

    test('& followed by space is bare ampersand', () {
      expect(sliceHtml('A& B', 3), equals('A& ...'));
    });

    test('&; (empty name) is bare ampersand', () {
      // &; doesn't match the entity regex → bare &, then ; is next char
      expect(sliceHtml('&;X', 2), equals('&;...'));
    });

    test('&#; (no digits) is bare ampersand', () {
      expect(sliceHtml('&#;X', 3), equals('&#;...'));
    });

    test('&#x; (no hex digits) is bare ampersand', () {
      expect(sliceHtml('&#x;X', 3), equals('&#x...'));
    });

    test('&amp without semicolon is bare ampersand', () {
      // &amp without ; → bare &, then a, m, p are separate chars
      expect(sliceHtml('&ampX', 4), equals('&amp...'));
    });

    test('entity followed immediately by entity', () {
      expect(sliceHtml('&lt;&gt;', 2), equals('&lt;&gt;'));
    });

    test('entity mixed with regular text', () {
      expect(sliceHtml('A&amp;B&lt;C', 5), equals('A&amp;B&lt;C'));
    });

    test('entity at the very start', () {
      expect(sliceHtml('&amp;Hello', 1), equals('&amp;...'));
    });

    test('entity at the very end', () {
      expect(sliceHtml('Hello&amp;', 6), equals('Hello&amp;'));
    });

    test('entity inside tag attribute is not counted', () {
      expect(
        sliceHtml('<a href="a&amp;b">XY</a>', 2),
        equals('<a href="a&amp;b">XY</a>'),
      );
    });

    test('multiple bare ampersands', () {
      expect(sliceHtml('&&&', 2), equals('&&...'));
    });

    test('numeric entity with many digits', () {
      expect(sliceHtml('&#12345;X', 1), equals('&#12345;...'));
    });

    test('hex entity with many digits', () {
      expect(sliceHtml('&#xABCDEF;X', 1), equals('&#xABCDEF;...'));
    });

    test('long named entity', () {
      expect(
        sliceHtml('&RightUpDownVector;X', 1),
        equals('&RightUpDownVector;...'),
      );
    });
  });

  // ===========================================================================
  // 4. HTML Comment Edge Cases
  // ===========================================================================
  group('HTML comment edge cases', () {
    test('empty comment', () {
      expect(sliceHtml('<!---->Hello', 5), equals('<!---->Hello'));
    });

    test('comment with > inside', () {
      expect(
        sliceHtml('<!-- a > b --><p>Hi</p>', 10),
        equals('<!-- a > b --><p>Hi</p>'),
      );
    });

    test('comment with multiple > inside', () {
      expect(
        sliceHtml('<!-- >> --><p>AB</p>', 2),
        equals('<!-- >> --><p>AB</p>'),
      );
    });

    test('comment with -- inside (but not -->)', () {
      expect(
        sliceHtml('<!-- a -- b --><p>Hi</p>', 10),
        equals('<!-- a -- b --><p>Hi</p>'),
      );
    });

    test('comment before and after text', () {
      expect(
        sliceHtml('<!--A-->Hello<!--B-->', 5),
        equals('<!--A-->Hello<!--B-->'),
      );
    });

    test('only comments, no visible text', () {
      expect(
        sliceHtml('<!--x--><!--y--><!--z-->', 10),
        equals('<!--x--><!--y--><!--z-->'),
      );
    });

    test('unterminated comment stops processing', () {
      expect(sliceHtml('<!-- no end', 100), equals('...'));
    });

    test('comment with truncation after', () {
      expect(
        sliceHtml('<!--c--><p>Hello World</p>', 5),
        equals('<!--c--><p>Hello...</p>'),
      );
    });

    test('comment between tags during trailing scan', () {
      expect(
        sliceHtml('Hello<!--mid--><br/>', 5),
        equals('Hello<!--mid--><br/>'),
      );
    });

    test('comment containing HTML-like content', () {
      expect(
        sliceHtml('<!-- <p>not a tag</p> -->AB', 2),
        equals('<!-- <p>not a tag</p> -->AB'),
      );
    });
  });

  // ===========================================================================
  // 5. Tag Attribute Edge Cases
  // ===========================================================================
  group('tag attribute edge cases', () {
    test('double-quoted attribute with >', () {
      expect(
        sliceHtml('<div x="a>b">Hi</div>', 2),
        equals('<div x="a>b">Hi</div>'),
      );
    });

    test('single-quoted attribute with >', () {
      expect(
        sliceHtml("<div x='a>b'>Hi</div>", 2),
        equals("<div x='a>b'>Hi</div>"),
      );
    });

    test('attribute with both quote types', () {
      expect(
        sliceHtml('''<div x="it's>ok">Hi</div>''', 2),
        equals('''<div x="it's>ok">Hi</div>'''),
      );
    });

    test('unclosed quoted attribute → tag never closes', () {
      final result = sliceHtml('<div class="foo>bar</div>rest', 100);
      // _findTagClose treats everything from " as inside quote
      // so > inside quote doesn't close, but </div> has > outside quote
      // The quote starts at ", goes through foo>bar</div, then > closes the
      // quote? No — the quote opened at " never finds another " so it goes
      // to end of string, returns -1 → break from main loop
      expect(result, equals('...'));
    });

    test('empty attribute value with >', () {
      expect(
        sliceHtml('<div x="">Hi</div>', 2),
        equals('<div x="">Hi</div>'),
      );
    });

    test('multiple attributes with >', () {
      expect(
        sliceHtml('<div a=">" b=\'>\'>AB</div>', 2),
        equals('<div a=">" b=\'>\'>AB</div>'),
      );
    });

    test('tag with newline in attributes', () {
      expect(
        sliceHtml('<div\nclass="x">AB</div>', 2),
        equals('<div\nclass="x">AB</div>'),
      );
    });
  });

  // ===========================================================================
  // 6. Void Elements
  // ===========================================================================
  group('void elements', () {
    test('<br> is void — no closing tag needed', () {
      expect(sliceHtml('<br>AB', 2), equals('<br>AB'));
    });

    test('<br/> self-closing syntax', () {
      expect(sliceHtml('<br/>AB', 2), equals('<br/>AB'));
    });

    test('<hr> is void', () {
      expect(sliceHtml('<hr>AB', 2), equals('<hr>AB'));
    });

    test('<img> as void element (not in preserveTags context)', () {
      expect(
        sliceHtml('<img src="x">AB', 2, preserveTags: const {}),
        equals('<img src="x">AB'),
      );
    });

    test('<input> is void', () {
      expect(
        sliceHtml('<input type="text">AB', 2),
        equals('<input type="text">AB'),
      );
    });

    test('<meta> is void', () {
      expect(
        sliceHtml('<meta charset="utf-8">AB', 2),
        equals('<meta charset="utf-8">AB'),
      );
    });

    test('<link> is void', () {
      expect(
        sliceHtml('<link rel="stylesheet" href="x">AB', 2),
        equals('<link rel="stylesheet" href="x">AB'),
      );
    });

    test('void elements do not push onto open tags stack', () {
      expect(
        sliceHtml('<p>A<br>B</p>', 2),
        equals('<p>A<br>B</p>'),
      );
    });

    test('multiple consecutive void elements', () {
      expect(
        sliceHtml('<br><hr><br>AB', 2),
        equals('<br><hr><br>AB'),
      );
    });

    test('<source> is void (inside non-preserved video)', () {
      expect(
        sliceHtml(
          '<video><source src="x"><source src="y">text</video>',
          4,
          preserveTags: const {},
        ),
        equals('<video><source src="x"><source src="y">text</video>'),
      );
    });
  });

  // ===========================================================================
  // 7. Self-Closing Tags
  // ===========================================================================
  group('self-closing tags', () {
    test('custom self-closing tag with />', () {
      expect(
        sliceHtml('<widget/>AB', 2),
        equals('<widget/>AB'),
      );
    });

    test('self-closing tag with space before />', () {
      expect(
        sliceHtml('<widget />AB', 2),
        equals('<widget />AB'),
      );
    });

    test('self-closing tag not pushed onto stack', () {
      // If it were pushed, we'd see </widget> at end
      expect(
        sliceHtml('<widget/>Hello', 3),
        equals('<widget/>Hel...'),
      );
    });

    test('self-closing tag with attributes', () {
      expect(
        sliceHtml('<img src="x" alt="y"/>AB', 2, preserveTags: const {}),
        equals('<img src="x" alt="y"/>AB'),
      );
    });
  });

  // ===========================================================================
  // 8. Preserved Tags Edge Cases
  // ===========================================================================
  group('preserved tags edge cases', () {
    test('preserved tag block not counted toward visible limit', () {
      expect(
        sliceHtml('<video>content</video>ABCDE', 5),
        equals('<video>content</video>ABCDE'),
      );
    });

    test('preserved tag block + partial text = truncation', () {
      expect(
        sliceHtml('<video>content</video>ABCDEF', 5),
        equals('<video>content</video>ABCDE...'),
      );
    });

    test('preserved tag with nested same-name tags', () {
      expect(
        sliceHtml('<video>a<video>b</video>c</video>XY', 2),
        equals('<video>a<video>b</video>c</video>XY'),
      );
    });

    test('preserved tag with no closing tag → treated as normal', () {
      // _findPreservedBlockEnd returns -1, so content is counted
      final result = sliceHtml(
        '<video>content',
        5,
        preserveTags: const {'video'},
      );
      expect(result, equals('<video>conte...</video>'));
    });

    test('preserved void element (img) — self-closing', () {
      expect(
        sliceHtml('<img src="x">Hello', 5),
        equals('<img src="x">Hello'),
      );
    });

    test('preserved self-closing tag with />', () {
      expect(
        sliceHtml('<img src="x"/>Hello', 5),
        equals('<img src="x"/>Hello'),
      );
    });

    test('case-insensitive preserveTags matching', () {
      expect(
        sliceHtml('<VIDEO>x</VIDEO>AB', 2, preserveTags: const {'video'}),
        equals('<VIDEO>x</VIDEO>AB'),
      );
    });

    test('custom preserveTags with mixed case in set', () {
      expect(
        sliceHtml('<code>x=1</code>AB', 2, preserveTags: const {'CODE'}),
        equals('<code>x=1</code>AB'),
      );
    });

    test('empty preserveTags → nothing preserved as block', () {
      // "text" = 4 visible chars, X is 5th → truncated
      expect(
        sliceHtml('<video>text</video>X', 4, preserveTags: const {}),
        equals('<video>text</video>...'),
      );
    });

    test('empty preserveTags → visible fits with higher limit', () {
      expect(
        sliceHtml('<video>text</video>X', 5, preserveTags: const {}),
        equals('<video>text</video>X'),
      );
    });

    test('empty preserveTags → content inside counts', () {
      expect(
        sliceHtml('<video>ABCDEF</video>', 3, preserveTags: const {}),
        equals('<video>ABC...</video>'),
      );
    });

    test('preserved block in trailing section after truncation', () {
      expect(
        sliceHtml('Hello<video>vid</video>', 5),
        equals('Hello<video>vid</video>'),
      );
    });

    test('preserved block in trailing section followed by visible text', () {
      expect(
        sliceHtml('Hello<video>vid</video>More', 5),
        equals('Hello<video>vid</video>...'),
      );
    });

    test('multiple preserved blocks', () {
      expect(
        sliceHtml('<video>v1</video><audio>a1</audio>AB', 2),
        equals('<video>v1</video><audio>a1</audio>AB'),
      );
    });

    test('nested different preserved tags', () {
      expect(
        sliceHtml('<video><audio>nested</audio></video>AB', 2),
        equals('<video><audio>nested</audio></video>AB'),
      );
    });

    test('title tag preserved by default', () {
      expect(
        sliceHtml('<title>My Page</title>Hello', 5),
        equals('<title>My Page</title>Hello'),
      );
    });

    test('head tag preserved by default', () {
      expect(
        sliceHtml('<head><meta charset="utf-8"></head>AB', 2),
        equals('<head><meta charset="utf-8"></head>AB'),
      );
    });

    test('iframe preserved by default', () {
      expect(
        sliceHtml('<iframe src="x">fallback</iframe>AB', 2),
        equals('<iframe src="x">fallback</iframe>AB'),
      );
    });
  });

  // ===========================================================================
  // 9. Tag Matching & Mismatched Tags
  // ===========================================================================
  group('tag matching & mismatched tags', () {
    test('properly nested tags → all closed correctly', () {
      expect(
        sliceHtml('<div><p><span>ABC</span></p></div>', 3),
        equals('<div><p><span>ABC</span></p></div>'),
      );
    });

    test('unclosed tag → auto-closed at end', () {
      expect(sliceHtml('<p>Hello', 5), equals('<p>Hello</p>'));
    });

    test('multiple unclosed tags → all auto-closed in reverse order', () {
      expect(
        sliceHtml('<div><p><span>Hello', 5),
        equals('<div><p><span>Hello</span></p></div>'),
      );
    });

    test('closing tag with no matching open → copied verbatim', () {
      expect(sliceHtml('</div>AB', 2), equals('</div>AB'));
    });

    test('extra closing tag after valid pair', () {
      expect(
        sliceHtml('<p>Hi</p></div>', 10),
        equals('<p>Hi</p></div>'),
      );
    });

    test('mismatched closing order', () {
      // <p><b>text</p></b> → </p> doesn't match top (b), written verbatim;
      // </b> matches top (b), popped; <p> left unclosed → auto-closed
      expect(
        sliceHtml('<p><b>text</p></b>', 100),
        equals('<p><b>text</p></b></p>'),
      );
    });

    test('closing tag case mismatch pops correctly', () {
      expect(
        sliceHtml('<DIV>Hello</div>', 5),
        equals('<DIV>Hello</DIV>'),
      );
    });

    test('mixed case preserves original opening case in auto-close', () {
      expect(
        sliceHtml('<Span>Hello', 5),
        equals('<Span>Hello</Span>'),
      );
    });

    test('deeply nested unclosed tags all auto-close', () {
      const input = '<a><b><c><d><e>X';
      final result = sliceHtml(input, 10);
      expect(result, equals('<a><b><c><d><e>X</e></d></c></b></a>'));
    });

    test('tag opened in trailing section gets auto-closed', () {
      // After "Hello" (5 chars), trailing scan sees <span>, adds to openTags
      final result = sliceHtml('Hello<span>', 5);
      expect(result, equals('Hello<span></span>'));
    });

    test('tag opened and closed in trailing section', () {
      final result = sliceHtml('Hello<span></span>', 5);
      expect(result, equals('Hello<span></span>'));
    });

    test('void tag in trailing section does not push stack', () {
      final result = sliceHtml('Hello<br>', 5);
      expect(result, equals('Hello<br>'));
    });
  });

  // ===========================================================================
  // 10. Trailing Content After Truncation
  // ===========================================================================
  group('trailing content after truncation', () {
    test('trailing closing tag consumed without ellipsis', () {
      expect(
        sliceHtml('<p>Hello</p>', 5),
        equals('<p>Hello</p>'),
      );
    });

    test('trailing comment consumed without ellipsis', () {
      expect(
        sliceHtml('Hello<!--x-->', 5),
        equals('Hello<!--x-->'),
      );
    });

    test('trailing newline consumed without ellipsis if no more text', () {
      expect(sliceHtml('Hello\n', 5), equals('Hello\n'));
    });

    test('trailing newline + visible text → ellipsis', () {
      expect(sliceHtml('Hello\nX', 5), equals('Hello\n...'));
    });

    test('trailing CRLF consumed', () {
      expect(sliceHtml('Hello\r\n', 5), equals('Hello\n'));
    });

    test('trailing CRLF + visible text → ellipsis', () {
      expect(sliceHtml('Hello\r\nX', 5), equals('Hello\n...'));
    });

    test('trailing lone CR consumed (preserveNewlines true)', () {
      expect(sliceHtml('Hello\r', 5), equals('Hello\r'));
    });

    test('trailing lone CR with preserveNewlines false', () {
      expect(
        sliceHtml('Hello\r', 5, preserveNewlines: false),
        equals('Hello '),
      );
    });

    test('trailing tags then visible text → ellipsis', () {
      expect(
        sliceHtml('Hello</p>More', 5),
        equals('Hello</p>...'),
      );
    });

    test('trailing multiple tags then visible text → ellipsis', () {
      expect(
        sliceHtml('<p>Hello</p><div>More</div>', 5),
        equals('<p>Hello</p><div>...</div>'),
      );
    });

    test('trailing preserved block consumed', () {
      expect(
        sliceHtml('Hello<video>v</video>', 5),
        equals('Hello<video>v</video>'),
      );
    });

    test('trailing preserved block then visible text → ellipsis', () {
      expect(
        sliceHtml('Hello<video>v</video>X', 5),
        equals('Hello<video>v</video>...'),
      );
    });

    test('trailing unclosed tag → treated as truncated', () {
      final result = sliceHtml('Hello<div class="', 5);
      // _findTagClose returns -1 for unclosed tag in trailing scan
      // → hasRemainingVisibleText = true → ellipsis
      expect(result, equals('Hello...'));
    });

    test('all trailing with no remaining visible text → no ellipsis', () {
      expect(
        sliceHtml('<p>Hello</p><!--x--><br>', 5),
        equals('<p>Hello</p><!--x--><br>'),
      );
    });
  });

  // ===========================================================================
  // 11. DOCTYPE & Special Declarations
  // ===========================================================================
  group('DOCTYPE & special declarations', () {
    test('<!DOCTYPE html> preserved, not counted', () {
      expect(
        sliceHtml('<!DOCTYPE html><p>AB</p>', 2),
        equals('<!DOCTYPE html><p>AB</p>'),
      );
    });

    test('<!DOCTYPE> with truncation', () {
      expect(
        sliceHtml('<!DOCTYPE html><p>Hello World</p>', 5),
        equals('<!DOCTYPE html><p>Hello...</p>'),
      );
    });

    test('<![CDATA[...]]> treated as declaration', () {
      // Starts with <!, so treated as comment-like and passed through
      expect(
        sliceHtml('<![CDATA[data]]>AB', 2),
        equals('<![CDATA[data]]>AB'),
      );
    });
  });

  // ===========================================================================
  // 12. Unicode & Multi-byte Characters
  // ===========================================================================
  group('unicode & multi-byte characters', () {
    test('multi-byte characters each count as one', () {
      expect(sliceHtml('日本語', 2), equals('日本...'));
    });

    test('emoji — surrogate pairs should not be broken', () {
      // 🌍 is a surrogate pair (2 code units). The code should treat it as
      // one visible character, or at minimum never split a surrogate pair.
      // "Hello " = 6 visible, 🌍 = 7th visible char (ideally).
      expect(sliceHtml('Hello 🌍🌎🌏', 7), equals('Hello 🌍...'));
    });

    test('emoji only input', () {
      // Each emoji is a surrogate pair; should count as 1 visible char each
      expect(sliceHtml('🌍🌎🌏', 2), equals('🌍🌎...'));
    });

    test('ZWJ family emoji is treated as one visible grapheme', () {
      expect(sliceHtml('👨‍👩‍👧‍👦AB', 1), equals('👨‍👩‍👧‍👦...'));
    });

    test('flag emoji is treated as one visible grapheme', () {
      expect(sliceHtml('🇺🇸AB', 1), equals('🇺🇸...'));
    });

    test('mixed ASCII and unicode', () {
      expect(sliceHtml('café', 4), equals('café'));
    });

    test('unicode with tags', () {
      expect(sliceHtml('<p>日本語</p>', 2), equals('<p>日本...</p>'));
    });

    test('accented characters', () {
      expect(sliceHtml('résumé', 3), equals('rés...'));
    });

    test('combining marks stay in same grapheme cluster', () {
      // e + combining acute accent should count as one visible character.
      expect(sliceHtml('e\u0301AB', 1), equals('e\u0301...'));
    });
  });

  // ===========================================================================
  // 13. Only Tags / No Visible Text
  // ===========================================================================
  group('only tags / no visible text', () {
    test('only opening and closing tags → no ellipsis', () {
      expect(
        sliceHtml('<div><p></p></div>', 10),
        equals('<div><p></p></div>'),
      );
    });

    test('only void elements → no ellipsis', () {
      expect(sliceHtml('<br><hr><br>', 10), equals('<br><hr><br>'));
    });

    test('only self-closing tags → no ellipsis', () {
      expect(sliceHtml('<br/><hr/>', 10), equals('<br/><hr/>'));
    });

    test('only comments → no ellipsis', () {
      expect(
        sliceHtml('<!--a--><!--b-->', 10),
        equals('<!--a--><!--b-->'),
      );
    });

    test('tags + newlines only → no ellipsis', () {
      expect(
        sliceHtml('<p>\n</p>\n<br>\n', 10),
        equals('<p>\n</p>\n<br>\n'),
      );
    });

    test('empty tags with maxLength 0 → ellipsis', () {
      expect(sliceHtml('<p></p>', 0), equals('...'));
    });
  });

  // ===========================================================================
  // 14. Complex Nested Structures
  // ===========================================================================
  group('complex nested structures', () {
    test('nested tags with text at various levels', () {
      // A(1)B(2)C(3)D(4) → limit reached; trailing scan consumes </span>,
      // then E is visible → truncated
      expect(
        sliceHtml('<div><p>AB<span>CD</span>EF</p></div>', 4),
        equals('<div><p>AB<span>CD</span>...</p></div>'),
      );
    });

    test('sibling tags with truncation in second', () {
      expect(
        sliceHtml('<p>AB</p><p>CD</p>', 3),
        equals('<p>AB</p><p>C...</p>'),
      );
    });

    test('deeply nested single char per level', () {
      // A(1)B(2) → limit reached; trailing scan consumes <c> (non-visible),
      // then C is visible → truncated; <c> auto-closed
      expect(
        sliceHtml('<a>A<b>B<c>C</c></b></a>', 2),
        equals('<a>A<b>B<c>...</c></b></a>'),
      );
    });

    test('interleaved text and tags', () {
      // A(1)B(2)C(3) → limit reached; trailing scan consumes <i> (non-visible),
      // then D is visible → truncated; <i> auto-closed
      expect(
        sliceHtml('A<b>B</b>C<i>D</i>E', 3),
        equals('A<b>B</b>C<i>...</i>'),
      );
    });

    test('adjacent tags with no whitespace', () {
      expect(
        sliceHtml('<b>X</b><i>Y</i><u>Z</u>', 3),
        equals('<b>X</b><i>Y</i><u>Z</u>'),
      );
    });

    test('table structure', () {
      // A(1) → limit reached; trailing scan consumes </td><td> (non-visible),
      // then B is visible → truncated
      const input = '<table><tr><td>A</td><td>B</td></tr></table>';
      expect(
        sliceHtml(input, 1),
        equals('<table><tr><td>A</td><td>...</td></tr></table>'),
      );
    });

    test('list structure', () {
      const input = '<ul><li>One</li><li>Two</li><li>Three</li></ul>';
      expect(
        sliceHtml(input, 5),
        equals('<ul><li>One</li><li>Tw...</li></ul>'),
      );
    });
  });

  // ===========================================================================
  // 15. Custom Ellipsis Edge Cases
  // ===========================================================================
  group('custom ellipsis edge cases', () {
    test('empty ellipsis → no indicator on truncation', () {
      expect(sliceHtml('Hello World', 5, ellipsis: ''), equals('Hello'));
    });

    test('single char ellipsis', () {
      expect(sliceHtml('Hello World', 5, ellipsis: '~'), equals('Hello~'));
    });

    test('multi-char ellipsis', () {
      expect(
        sliceHtml('Hello World', 5, ellipsis: ' [more]'),
        equals('Hello [more]'),
      );
    });

    test('HTML in ellipsis (gets written verbatim)', () {
      expect(
        sliceHtml('Hello World', 5, ellipsis: '<span>...</span>'),
        equals('Hello<span>...</span>'),
      );
    });

    test('unicode ellipsis character', () {
      expect(
        sliceHtml('Hello World', 5, ellipsis: '\u2026'),
        equals('Hello\u2026'),
      );
    });

    test('ellipsis with maxLength 0', () {
      expect(sliceHtml('X', 0, ellipsis: '[CUT]'), equals('[CUT]'));
    });

    test('ellipsis not added when no truncation', () {
      expect(sliceHtml('Hi', 10, ellipsis: '!!!'), equals('Hi'));
    });
  });

  // ===========================================================================
  // 16. Mixed Content Stress Tests
  // ===========================================================================
  group('mixed content', () {
    test('text + entity + tag + comment + newline', () {
      const input = 'A&amp;<!--c--><b>B\nC</b>';
      // A(1), &amp;(2), comment(0), <b>(0), B(3) → limit reached;
      // trailing scan consumes \n (non-visible), then C is visible → truncated
      expect(sliceHtml(input, 3), equals('A&amp;<!--c--><b>B\n...</b>'));
    });

    test('preserved block + entity + newline + text', () {
      const input = '<video>v</video>&amp;\nHello';
      // video preserved(0), &amp;(1), \n(0), Hello(2-6)
      expect(sliceHtml(input, 3), equals('<video>v</video>&amp;\nHe...'));
    });

    test('DOCTYPE + head + body with truncation', () {
      // ignore: missing_whitespace_between_adjacent_strings
      const input = '<!DOCTYPE html><html><head><title>T</title></head><body>'
          '<p>Hello World</p></body></html>';
      final result = sliceHtml(input, 5);
      expect(
        result,
        equals(
          // ignore: missing_whitespace_between_adjacent_strings
          '<!DOCTYPE html><html><head><title>T</title></head><body>'
          '<p>Hello...</p></body></html>',
        ),
      );
    });

    test('complex real-world-like HTML', () {
      const input = '''
<html>
<head><title>Test</title></head>
<body>
<div class="container">
<h1>Welcome</h1>
<p>This is a <strong>test</strong> paragraph.</p>
<img src="photo.jpg" alt="Photo" />
<p>Another paragraph with &amp; entities.</p>
</div>
</body>
</html>''';
      final result = sliceHtml(input, 20);
      expect(
        result,
        equals(
          '<html>\n<head><title>Test</title></head>\n<body>\n'
          '<div class="container">\n<h1>Welcome</h1>\n<p>This is a '
          '<strong>tes...</strong></p></div></body></html>',
        ),
      );
    });
  });

  // ===========================================================================
  // 17. Tag Name Edge Cases
  // ===========================================================================
  group('tag name edge cases', () {
    test('tag with numbers in name', () {
      expect(
        sliceHtml('<h1>Title</h1><h2>Sub</h2>', 8),
        equals('<h1>Title</h1><h2>Sub</h2>'),
      );
    });

    test('tag with hyphen in name', () {
      expect(
        sliceHtml('<my-component>Hi</my-component>', 2),
        equals('<my-component>Hi</my-component>'),
      );
    });

    test('tag with colon in name (XML namespace)', () {
      expect(
        sliceHtml('<ns:tag>Hi</ns:tag>', 2),
        equals('<ns:tag>Hi</ns:tag>'),
      );
    });

    test('single letter tag', () {
      expect(sliceHtml('<b>X</b>', 1), equals('<b>X</b>'));
    });

    test('tag with leading/trailing whitespace in name area', () {
      // < p > → regex extracts rawTagName "p", so closing is reconstructed as </p>
      expect(
        sliceHtml('< p >Hi</ p >', 2),
        equals('< p >Hi</p>'),
      );
    });

    test('empty tag <> → no tag name match, written verbatim', () {
      expect(sliceHtml('<>AB', 2), equals('<>AB'));
    });
  });

  // ===========================================================================
  // 18. Malformed HTML Stress Tests
  // ===========================================================================
  group('malformed HTML stress tests', () {
    test('< at end of string', () {
      final result = sliceHtml('Hello<', 5);
      // _findTagClose('<', 5) searches from index 6 onward, nothing -> -1.
      // i < html.length, visibleCount == maxLength → trailing scan
      // At index 5 it's '<' and _findTagClose returns -1.
      // The input is treated as truncated.
      expect(result, equals('Hello...'));
    });

    test('lone < in middle of text', () {
      // For 'A<B', _findTagClose starts after '<' and finds no '>'.
      final result = sliceHtml('A<B', 10);
      expect(result, equals('A...'));
    });

    test('> in plain text', () {
      // > is just a regular character in text context
      expect(sliceHtml('A>B', 3), equals('A>B'));
    });

    test('multiple unclosed <', () {
      final result = sliceHtml('A<B<C<D', 10);
      expect(result, equals('A...'));
    });

    test('tag immediately followed by another tag', () {
      expect(
        sliceHtml('<p><b>AB</b></p>', 2),
        equals('<p><b>AB</b></p>'),
      );
    });

    test('closing tag without opening', () {
      expect(sliceHtml('</span>Hello', 5), equals('</span>Hello'));
    });

    test('only closing tags', () {
      expect(sliceHtml('</a></b></c>', 10), equals('</a></b></c>'));
    });

    test('nested unclosed tags with visible text', () {
      expect(
        sliceHtml('<a><b><c>XY', 2),
        equals('<a><b><c>XY</c></b></a>'),
      );
    });

    test('duplicate open tags', () {
      expect(
        sliceHtml('<p><p>AB</p></p>', 2),
        equals('<p><p>AB</p></p>'),
      );
    });

    test('broken comment-like — <! without --', () {
      // <!foo> starts with <!, so it's treated as declaration/comment-like
      expect(
        sliceHtml('<!foo>AB', 2),
        equals('<!foo>AB'),
      );
    });

    test('script-like tag not in preserveTags → content counts', () {
      // <script> is not in default preserveTags, so "al" = 2 visible chars
      expect(
        sliceHtml('<script>alert("hi")</script>AB', 2),
        equals('<script>al...</script>'),
      );
    });
  });

  // ===========================================================================
  // 19. preserveNewlines Interaction with Tags
  // ===========================================================================
  group('preserveNewlines with tags', () {
    test('newline between tags preserved', () {
      expect(
        sliceHtml('<p>A</p>\n<p>B</p>', 2),
        equals('<p>A</p>\n<p>B</p>'),
      );
    });

    test('newline between tags replaced with space', () {
      expect(
        sliceHtml('<p>A</p>\n<p>B</p>', 2, preserveNewlines: false),
        equals('<p>A</p> <p>B</p>'),
      );
    });

    test('CRLF between tags', () {
      expect(
        sliceHtml('<p>A</p>\r\n<p>B</p>', 2),
        equals('<p>A</p>\n<p>B</p>'),
      );
    });

    test('CRLF in trailing section preserved', () {
      expect(
        sliceHtml('Hello\r\n<br>', 5),
        equals('Hello\n<br>'),
      );
    });

    test('CRLF in trailing section replaced', () {
      expect(
        sliceHtml('Hello\r\n<br>', 5, preserveNewlines: false),
        equals('Hello <br>'),
      );
    });

    test('multiple newlines in trailing section', () {
      expect(
        sliceHtml('Hello\n\n\n', 5),
        equals('Hello\n\n\n'),
      );
    });

    test('newline in trailing section followed by text → ellipsis', () {
      expect(
        sliceHtml('Hello\n\nX', 5),
        equals('Hello\n\n...'),
      );
    });
  });

  // ===========================================================================
  // 20. Real-world HTML Patterns
  // ===========================================================================
  group('real-world HTML patterns', () {
    test('email-style HTML', () {
      const input = '''
<div style="font-family: Arial;">
<p>Dear User,</p>
<p>Thank you for your <strong>purchase</strong>.</p>
<img src="logo.png" alt="Logo" />
<p>Best regards,<br>The Team</p>
      </div>''';
      final result = sliceHtml(input, 30);
      expect(
        result,
        equals(
          '<div style="font-family: Arial;">\n<p>Dear User,</p>\n'
          '<p>Thank you for your <strong>p...</strong></p></div>',
        ),
      );
    });

    test('blog post excerpt', () {
      const input = '<article><h1>Title</h1> '
          '<p>First paragraph of the blog post with lots of content.</p> '
          '<p>Second paragraph continues here.</p></article>';
      final result = sliceHtml(input, 25);
      expect(
        result,
        equals(
          '<article><h1>Title</h1> <p>First paragraph of ...</p></article>',
        ),
      );
    });

    test('HTML with inline styles and classes', () {
      const input = '<div class="container" style="color: red;"><span '
          'class="highlight">Important</span> text here.</div>';
      // "Important" = 9 visible chars, space = 10th → limit reached;
      // trailing scan hits "t" (visible) → truncated
      final result = sliceHtml(input, 10);
      expect(
        result,
        equals(
          '<div class="container" style="color: red;"><span '
          'class="highlight">Important</span> ...</div>',
        ),
      );
    });

    test('anchor tags with href', () {
      const input = '<a href="https://example.com?a=1&b=2">Click here</a>';
      final result = sliceHtml(input, 5);
      expect(
        result,
        equals('<a href="https://example.com?a=1&b=2">Click...</a>'),
      );
    });

    test('nested lists', () {
      const input = '<ul><li>Item 1<ul><li>Sub A</li><li>Sub B</li></ul></li> '
          '<li>Item 2</li></ul>';
      final result = sliceHtml(input, 10);
      expect(
        result,
        equals('<ul><li>Item 1<ul><li>Sub ...</li></ul></li></ul>'),
      );
    });
  });

  // ===========================================================================
  // 21. Comprehensive Truncation Precision Tests
  // ===========================================================================
  group('truncation precision', () {
    test('exact count with entity at end → no ellipsis', () {
      expect(sliceHtml('ABC&amp;', 4), equals('ABC&amp;'));
    });

    test('one over with entity at end → no ellipsis if exact', () {
      expect(sliceHtml('ABCD&amp;', 5), equals('ABCD&amp;'));
    });

    test('truncation right before entity', () {
      expect(sliceHtml('ABCD&amp;E', 4), equals('ABCD...'));
    });

    test('truncation right after entity', () {
      expect(sliceHtml('ABC&amp;DE', 4), equals('ABC&amp;...'));
    });

    test('visible count with newlines interspersed', () {
      // A(1) \n B(2) \n C(3) \n D(4) \n E(5)
      expect(sliceHtml('A\nB\nC\nD\nE', 5), equals('A\nB\nC\nD\nE'));
    });

    test('visible count with newlines - one short', () {
      expect(sliceHtml('A\nB\nC\nD\nE\nF', 5), equals('A\nB\nC\nD\nE\n...'));
    });

    test('spaces count as visible', () {
      // 'H e l l o' = 9 chars (5 letters + 4 spaces)
      expect(sliceHtml('H e l l o', 5), equals('H e l...'));
    });
  });

  // ===========================================================================
  // 22. Edge Cases in _findPreservedBlockEnd
  // ===========================================================================
  group('preserved block end finding', () {
    test('preserved block with comments inside', () {
      expect(
        sliceHtml('<video><!--comment--></video>AB', 2),
        equals('<video><!--comment--></video>AB'),
      );
    });

    test('preserved block with nested different tags', () {
      expect(
        sliceHtml('<video><div><span>x</span></div></video>AB', 2),
        equals('<video><div><span>x</span></div></video>AB'),
      );
    });

    test('preserved block with self-closing same-name tag inside', () {
      // <img> is both void and in preserveTags by default
      // For custom preserveTags, nested <custom/> should not break depth logic.
      expect(
        sliceHtml(
          '<custom>before<custom/>after</custom>XY',
          2,
          preserveTags: const {'custom'},
        ),
        equals('<custom>before<custom/>after</custom>XY'),
      );
    });

    test('three levels of same-name nesting', () {
      expect(
        sliceHtml(
          '<div><div><div>deep</div></div></div>AB',
          2,
          preserveTags: const {'div'},
        ),
        equals('<div><div><div>deep</div></div></div>AB'),
      );
    });
  });

  // ===========================================================================
  // 23. Whitespace-only Visible Content
  // ===========================================================================
  group('whitespace-only visible content', () {
    test('only spaces → counted and truncated', () {
      expect(sliceHtml('   ', 2), equals('  ...'));
    });

    test('only tabs → counted and truncated', () {
      expect(sliceHtml('\t\t\t', 2), equals('\t\t...'));
    });

    test('space in tags', () {
      expect(sliceHtml('<p> </p>', 1), equals('<p> </p>'));
    });

    test('multiple spaces in tags truncated', () {
      expect(sliceHtml('<p>   </p>', 2), equals('<p>  ...</p>'));
    });
  });

  // ===========================================================================
  // 24. Regression-style tests
  // ===========================================================================
  group('regression tests', () {
    test('preserved tag immediately after truncation point', () {
      // Visible: "ABCDE" = 5, then <video> block in trailing scan
      expect(
        sliceHtml('ABCDE<video>x</video>', 5),
        equals('ABCDE<video>x</video>'),
      );
    });

    test('closing tag in trailing scan matches open tag from main loop', () {
      expect(
        sliceHtml('<p>Hello</p>', 5),
        equals('<p>Hello</p>'),
      );
    });

    test('entity in trailing section is visible → triggers ellipsis', () {
      // "Hello" = 5 chars, then &amp; is visible → truncated
      expect(sliceHtml('Hello&amp;', 5), equals('Hello...'));
    });

    test('bare & in trailing section is visible → triggers ellipsis', () {
      expect(sliceHtml('Hello&', 5), equals('Hello...'));
    });

    test('text after only-tags content', () {
      expect(
        sliceHtml('<br><hr>AB', 2),
        equals('<br><hr>AB'),
      );
    });

    test('text after only-comments content', () {
      expect(
        sliceHtml('<!--x-->AB', 2),
        equals('<!--x-->AB'),
      );
    });

    test('maxLength very large on small input', () {
      expect(
        sliceHtml('<p>Hi</p>', 999999),
        equals('<p>Hi</p>'),
      );
    });

    test('sequential entities no truncation', () {
      expect(
        sliceHtml('&amp;&lt;&gt;&quot;&apos;', 5),
        equals('&amp;&lt;&gt;&quot;&apos;'),
      );
    });

    test('sequential entities with truncation', () {
      expect(
        sliceHtml('&amp;&lt;&gt;&quot;&apos;', 3),
        equals('&amp;&lt;&gt;...'),
      );
    });
  });

  // ===========================================================================
  // 25. Stress / Performance Tests
  // ===========================================================================
  group('stress tests', () {
    test('very long plain text', () {
      final input = 'A' * 100000;
      final result = sliceHtml(input, 100);
      expect(result, equals('${'A' * 100}...'));
    });

    test('many tags with small text', () {
      final input = List.generate(1000, (i) => '<span>X</span>').join();
      final result = sliceHtml(input, 10);
      expect(result, contains('...'));
      // Count that spans are balanced
      final openCount = RegExp('<span>').allMatches(result).length;
      final closeCount = RegExp('</span>').allMatches(result).length;
      expect(openCount, equals(closeCount));
    });

    test('many entities', () {
      final input = List.filled(10000, '&amp;').join();
      final result = sliceHtml(input, 50);
      final entityCount = RegExp('&amp;').allMatches(result).length;
      expect(entityCount, equals(50));
      expect(result, endsWith('&amp;...'));
    });

    test('many comments', () {
      final input = '${List.filled(500, '<!--comment-->').join()}AB';
      final result = sliceHtml(input, 2);
      expect(result, contains('AB'));
      expect(
        result,
        isNot(contains('...')),
        reason: 'Comments are not visible, all fit',
      );
    });

    test('many preserved blocks', () {
      final input = '${List.filled(100, '<video>v</video>').join()}ABCDE';
      final result = sliceHtml(input, 5);
      expect(result, contains('ABCDE'));
      expect(result, isNot(contains('...')));
    });

    test('alternating tags and single chars', () {
      final input = List.generate(500, (i) => '<b>X</b>').join();
      final result = sliceHtml(input, 10);
      final openCount = RegExp('<b>').allMatches(result).length;
      final closeCount = RegExp('</b>').allMatches(result).length;
      expect(openCount, equals(closeCount));
    });
  });

  // ===========================================================================
  // 26. Combination / Integration Tests
  // ===========================================================================
  group('combination tests', () {
    test('all features together', () {
      // ignore: missing_whitespace_between_adjacent_strings
      const input =
          '<!DOCTYPE html><!-- intro --><html><head><title>T</title></head><body>\n'
          '<p>Hello &amp; <b>World</b></p>\n'
          '<img src="x" /><video>vid</video><p>More &lt;content&gt; here.</p></body></html>';
      final result = sliceHtml(input, 15);
      expect(
        result,
        equals(
          // ignore: leading_newlines_in_multiline_strings
          '''<!DOCTYPE html><!-- intro --><html><head><title>T</title></head><body>
<p>Hello &amp; <b>World</b></p>
<img src="x" /><video>vid</video><p>Mo...</p></body></html>''',
        ),
      );
    });

    test('preserveNewlines false with CRLF and entities', () {
      const input = 'A&amp;\r\nB&lt;\r\nC';
      // A(1), &amp;(2), \r\n→space(not counted), B(3), &lt;(4) → limit;
      // trailing \r\n consumed as space, then C is visible → truncated
      final result = sliceHtml(input, 4, preserveNewlines: false);
      expect(result, equals('A&amp; B&lt; ...'));
    });

    test('custom preserveTags + custom ellipsis + preserveNewlines false', () {
      const input = '<code>x=1</code>\nHello World';
      // code block preserved (0 visible). \n → space (not counted).
      // H(1)e(2)l(3)l(4)o(5) → limit; " World" causes truncation
      final result = sliceHtml(
        input,
        5,
        preserveTags: const {'code'},
        ellipsis: '>>>',
        preserveNewlines: false,
      );
      expect(result, equals('<code>x=1</code> Hello>>>'));
    });

    test('void element inside preserved block does not break nesting', () {
      expect(
        sliceHtml('<video><source src="x"><br>text</video>AB', 2),
        equals('<video><source src="x"><br>text</video>AB'),
      );
    });
  });

  // ===========================================================================
  // 27. _consumeTrailingNonVisible Specific Edge Cases
  // ===========================================================================
  group('trailing scan specific cases', () {
    test('opening tag in trailing that has no close → auto-closed', () {
      final result = sliceHtml('Hello<div>', 5);
      expect(result, equals('Hello<div></div>'));
    });

    test('multiple opening tags in trailing → all auto-closed in order', () {
      final result = sliceHtml('Hello<div><span>', 5);
      expect(result, equals('Hello<div><span></span></div>'));
    });

    test('closing tag in trailing matching earlier open → pops stack', () {
      final result = sliceHtml('<p>Hello</p>', 5);
      expect(result, equals('<p>Hello</p>'));
    });

    test('closing tag in trailing not matching → written verbatim', () {
      // <p> opened, then Hello (5), trailing has </div> (mismatch)
      final result = sliceHtml('<p>Hello</div>', 5);
      expect(result, equals('<p>Hello</div></p>'));
    });

    test('preserved block in trailing → fully consumed', () {
      expect(
        sliceHtml('ABCDE<audio>sound</audio>', 5),
        equals('ABCDE<audio>sound</audio>'),
      );
    });

    test(
      'preserved block in trailing without close → not consumed as block',
      () {
        // <audio> with no </audio> → _findPreservedBlockEnd returns -1
        // Falls through to normal tag handling, pushes to openTags
        final result = sliceHtml('Hello<audio>sound', 5);
        expect(result, contains('Hello'));
        expect(result, contains('<audio>'));
      },
    );

    test('declaration (<!...>) in trailing consumed', () {
      expect(
        sliceHtml('Hello<!DOCTYPE html>', 5),
        equals('Hello<!DOCTYPE html>'),
      );
    });
  });

  // ===========================================================================
  // 28. Idempotency & Double-slicing
  // ===========================================================================
  group('idempotency', () {
    test('slicing already-short text is idempotent', () {
      const input = '<p>Hi</p>';
      final once = sliceHtml(input, 10);
      final twice = sliceHtml(once, 10);
      expect(once, equals(twice));
    });

    test('slicing result again with same limit preserves content', () {
      const input = '<p>Hello World</p>';
      final once = sliceHtml(input, 5);
      final twice = sliceHtml(once, 5);
      expect(once, equals(twice));
    });

    test('slicing result with larger limit keeps it unchanged', () {
      const input = '<div><p>Long text content here</p></div>';
      final once = sliceHtml(input, 5);
      final twice = sliceHtml(once, 100);
      expect(once, equals(twice));
    });
  });

  // ===========================================================================
  // 29. Edge Cases with < and > in Text
  // ===========================================================================
  group('angle brackets in text', () {
    test('> in text is a normal visible char', () {
      expect(sliceHtml('1>0', 3), equals('1>0'));
    });

    test('> in text truncated', () {
      expect(sliceHtml('1>0 yes', 3), equals('1>0...'));
    });

    test('< in text without valid tag → breaks parsing', () {
      // This is inherently ambiguous / malformed
      final result = sliceHtml('1<2 and 3>4', 10);
      // The < starts a "tag", _findTagClose looks for >, finds one at 3>4's >
      // tagText = "<2 and 3>", _tagNameRegExp extracts "2"
      // Not a closing tag, not in preserveTags, not void → pushed as open tag
      expect(result, isNotEmpty);
    });
  });

  // ===========================================================================
  // 30. defaultPreserveTags constant
  // ===========================================================================
  group('defaultPreserveTags', () {
    test('contains expected tags', () {
      expect(defaultPreserveTags, contains('title'));
      expect(defaultPreserveTags, contains('head'));
      expect(defaultPreserveTags, contains('img'));
      expect(defaultPreserveTags, contains('video'));
      expect(defaultPreserveTags, contains('audio'));
      expect(defaultPreserveTags, contains('iframe'));
    });

    test('has exactly 6 entries', () {
      expect(defaultPreserveTags.length, equals(6));
    });
  });
}
