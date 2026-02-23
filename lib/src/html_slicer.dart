import 'package:characters/characters.dart';

/// Regex for extracting a tag name from an HTML tag string.
final RegExp _tagNameRegExp = RegExp(r'<\s*/?\s*([^\s>/]+)');

/// Regex for matching valid HTML entities: `&name;`, `&#digits;`, `&#xhex;`.
final RegExp _entityRegExp =
    RegExp('&(?:#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');

/// Finds the closing `>` of an HTML tag starting at [start], respecting
/// quoted attribute values and `<!-- -->` comment syntax.
///
/// Returns the index of the closing `>`, or `-1` if not found.
int _findTagClose(String html, int start) {
  // Handle HTML comments: <!-- ... -->
  if (start + 3 < html.length &&
      html[start] == '<' &&
      html[start + 1] == '!' &&
      html[start + 2] == '-' &&
      html[start + 3] == '-') {
    final commentEnd = html.indexOf('-->', start + 4);
    if (commentEnd == -1) return -1;
    return commentEnd + 2; // index of '>' in '-->'
  }

  var inQuote = '';
  for (var j = start + 1; j < html.length; j++) {
    final ch = html[j];
    if (inQuote.isNotEmpty) {
      if (ch == inQuote) {
        inQuote = '';
      }
    } else if (ch == '"' || ch == "'") {
      inQuote = ch;
    } else if (ch == '>') {
      return j;
    }
  }
  return -1;
}

/// If [html] at index [i] starts with `&` and forms a valid HTML entity,
/// returns the index just past the closing `;`. Otherwise returns `-1`.
int _advancePastEntity(String html, int i) {
  final match = _entityRegExp.matchAsPrefix(html, i);
  if (match == null) return -1;
  return match.end;
}

/// Finds the end index (`>`) of the matching closing tag for a preserved block.
///
/// Supports nested tags with the same name and performs case-insensitive
/// matching. Returns `-1` if no matching closing tag is found.
int _findPreservedBlockEnd(
  String html,
  int start,
  String lowerTagName,
  Set<String> voidElements,
) {
  var depth = 1;
  var i = start;

  while (i < html.length) {
    if (html[i] != '<') {
      i++;
      continue;
    }

    final closeIdx = _findTagClose(html, i);
    if (closeIdx == -1) return -1;
    final tagText = html.substring(i, closeIdx + 1);

    if (tagText.startsWith('<!')) {
      i = closeIdx + 1;
      continue;
    }

    final match = _tagNameRegExp.firstMatch(tagText);
    if (match == null) {
      i = closeIdx + 1;
      continue;
    }

    final tagName = match.group(1)!.toLowerCase();
    if (tagName != lowerTagName) {
      i = closeIdx + 1;
      continue;
    }

    final isClosingTag = tagText.startsWith('</');
    final isSelfClosing =
        tagText.endsWith('/>') || voidElements.contains(tagName);

    if (isClosingTag) {
      depth--;
      if (depth == 0) return closeIdx;
    } else if (!isSelfClosing) {
      depth++;
    }

    i = closeIdx + 1;
  }

  return -1;
}

class _TrailingScanResult {
  const _TrailingScanResult(
    this.index, {
    required this.hasRemainingVisibleText,
  });

  final int index;
  final bool hasRemainingVisibleText;
}

/// After the visible limit is reached, consume and append trailing non-visible
/// content (tags/comments/newlines) until visible text is found or input ends.
_TrailingScanResult _consumeTrailingNonVisible(
  String html,
  int start, {
  required StringBuffer buffer,
  required List<String> openTags,
  required bool preserveNewlines,
  required Set<String> preserveTags,
  required Set<String> voidElements,
}) {
  var i = start;
  while (i < html.length) {
    if (html[i] == '<') {
      final closeIdx = _findTagClose(html, i);
      if (closeIdx == -1) {
        return _TrailingScanResult(i, hasRemainingVisibleText: true);
      }
      final tagText = html.substring(i, closeIdx + 1);

      if (tagText.startsWith('<!')) {
        buffer.write(tagText);
        i = closeIdx + 1;
        continue;
      }

      final match = _tagNameRegExp.firstMatch(tagText);
      if (match == null) {
        buffer.write(tagText);
        i = closeIdx + 1;
        continue;
      }

      final rawTagName = match.group(1)!;
      final lowerTagName = rawTagName.toLowerCase();
      final isClosingTag = tagText.startsWith('</');

      if (!isClosingTag && preserveTags.contains(lowerTagName)) {
        final isSelfClosing =
            tagText.endsWith('/>') || voidElements.contains(lowerTagName);
        if (!isSelfClosing) {
          final closeEnd = _findPreservedBlockEnd(
            html,
            closeIdx + 1,
            lowerTagName,
            voidElements,
          );
          if (closeEnd != -1) {
            buffer.write(html.substring(i, closeEnd + 1));
            i = closeEnd + 1;
            continue;
          }
        }
      }

      if (isClosingTag) {
        if (openTags.isNotEmpty &&
            openTags.last.toLowerCase() == lowerTagName) {
          final openedName = openTags.removeLast();
          buffer.write('</$openedName>');
        } else {
          buffer.write(tagText);
        }
      } else {
        buffer.write(tagText);
        final isSelfClosing =
            tagText.endsWith('/>') || voidElements.contains(lowerTagName);
        if (!isSelfClosing) {
          openTags.add(rawTagName);
        }
      }
      i = closeIdx + 1;
      continue;
    }

    if (html[i] == '\r') {
      if (i + 1 < html.length && html[i + 1] == '\n') {
        buffer.write(preserveNewlines ? '\n' : ' ');
        i += 2;
      } else {
        buffer.write(preserveNewlines ? '\r' : ' ');
        i++;
      }
      continue;
    }

    if (html[i] == '\n') {
      buffer.write(preserveNewlines ? '\n' : ' ');
      i++;
      continue;
    }

    return _TrailingScanResult(i, hasRemainingVisibleText: true);
  }

  return _TrailingScanResult(i, hasRemainingVisibleText: false);
}

/// The default set of tag names whose entire block is preserved without
/// counting inner content toward the visible character limit.
const Set<String> defaultPreserveTags = {
  'title',
  'head',
  'img',
  'video',
  'audio',
  'iframe',
};

/// Slices the given [html] string to a specified [maxLength] of visible
/// characters, preserving the structure of the HTML and optionally
/// preserving newlines.
///
/// The function ensures that the HTML remains valid by properly closing any
/// open tags and handling self-closing tags. It also preserves certain
/// tags (like `<img>`, `<video>`, etc.) as whole blocks without counting their
/// content towards the visible character limit.
///
/// If [preserveNewlines] is `true`, newline characters in the input HTML are
/// preserved in the output. If `false`, they are replaced with spaces.
///
/// [preserveTags] controls which tags are preserved as whole blocks. Defaults
/// to [defaultPreserveTags].
///
/// [ellipsis] is the string appended when truncation occurs. Defaults to
/// `'...'`.
///
/// Throws an [ArgumentError] if [maxLength] is negative.
String sliceHtml(
  String html,
  int maxLength, {
  bool preserveNewlines = true,
  Set<String> preserveTags = defaultPreserveTags,
  String ellipsis = '...',
}) {
  if (maxLength < 0) {
    throw ArgumentError.value(maxLength, 'maxLength', 'must not be negative');
  }
  if (html.isEmpty) return html;
  if (maxLength == 0) return ellipsis;

  final buffer = StringBuffer();
  final openTags = <String>[]; // store the original-case tag names
  final normalizedPreserveTags =
      preserveTags.map((tag) => tag.toLowerCase()).toSet();

  const voidElements = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  };

  var visibleCount = 0;
  var i = 0;

  while (i < html.length && visibleCount < maxLength) {
    if (html[i] == '<') {
      final closeIdx = _findTagClose(html, i);
      if (closeIdx == -1) break;
      final tagText = html.substring(i, closeIdx + 1);

      // <!DOCTYPE or <!-- --> or similar
      if (tagText.startsWith('<!')) {
        buffer.write(tagText);
        i = closeIdx + 1;
        continue;
      }

      final match = _tagNameRegExp.firstMatch(tagText);
      if (match == null) {
        buffer.write(tagText);
        i = closeIdx + 1;
        continue;
      }

      final rawTagName = match.group(1)!;
      final lowerTagName = rawTagName.toLowerCase();
      final isClosingTag = tagText.startsWith('</');

      // Attempt to preserve entire block
      if (!isClosingTag && normalizedPreserveTags.contains(lowerTagName)) {
        final isSelfClosing =
            tagText.endsWith('/>') || voidElements.contains(lowerTagName);
        if (!isSelfClosing) {
          final closeEnd = _findPreservedBlockEnd(
            html,
            closeIdx + 1,
            lowerTagName,
            voidElements,
          );
          if (closeEnd != -1) {
            // copy entire block
            buffer.write(html.substring(i, closeEnd + 1));
            i = closeEnd + 1;
            continue;
          }
        }
      }

      // Normal tag handling
      if (isClosingTag) {
        // pop if matching top
        if (openTags.isNotEmpty &&
            openTags.last.toLowerCase() == lowerTagName) {
          final openedName = openTags.removeLast();
          buffer.write('</$openedName>');
        } else {
          // mismatch
          buffer.write(tagText);
        }
      } else {
        // opening tag
        buffer.write(tagText);
        final selfClose =
            tagText.endsWith('/>') || voidElements.contains(lowerTagName);
        if (!selfClose) {
          openTags.add(rawTagName);
        }
      }
      i = closeIdx + 1;
    } else {
      // text character
      if (html[i] == '\r') {
        // CRLF: treat \r\n as a single newline
        if (i + 1 < html.length && html[i + 1] == '\n') {
          buffer.write(preserveNewlines ? '\n' : ' ');
          i += 2;
        } else {
          // lone \r
          buffer.write(preserveNewlines ? html[i] : ' ');
          i++;
        }
      } else if (html[i] == '\n') {
        buffer.write(preserveNewlines ? html[i] : ' ');
        i++;
      } else if (html[i] == '&') {
        // HTML entity handling
        final entityEnd = _advancePastEntity(html, i);
        if (entityEnd != -1) {
          buffer.write(html.substring(i, entityEnd));
          visibleCount++;
          i = entityEnd;
        } else {
          // bare '&', treat as literal character
          buffer.write(html[i]);
          visibleCount++;
          i++;
        }
      } else {
        // Fast path for plain ASCII that cannot be part of a multi-code-point
        // grapheme cluster with the next code unit.
        if (html.codeUnitAt(i) <= 0x7f &&
            (i + 1 >= html.length || html.codeUnitAt(i + 1) <= 0x7f)) {
          buffer.writeCharCode(html.codeUnitAt(i));
          visibleCount++;
          i++;
          continue;
        }

        final range = CharacterRange.at(html, i);
        if (!range.moveNext()) {
          break;
        }
        final grapheme = range.current;
        buffer.write(grapheme);
        visibleCount++;
        i += grapheme.length;
      }
    }
  }

  var isTruncated = false;
  if (i < html.length) {
    if (visibleCount >= maxLength) {
      final scan = _consumeTrailingNonVisible(
        html,
        i,
        buffer: buffer,
        openTags: openTags,
        preserveNewlines: preserveNewlines,
        preserveTags: normalizedPreserveTags,
        voidElements: voidElements,
      );
      i = scan.index;
      isTruncated = scan.hasRemainingVisibleText;
    } else {
      isTruncated = true;
    }
  }

  // If truncated
  if (isTruncated) {
    buffer.write(ellipsis);
  }

  // close unclosed
  while (openTags.isNotEmpty) {
    final t = openTags.removeLast();
    buffer.write('</$t>');
  }

  return buffer.toString();
}
