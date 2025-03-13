/// Slices the given HTML string to a specified maximum length
/// of visible characters, preserving the structure of the HTML and optionally
/// preserving newlines.
///
/// The function ensures that the HTML remains valid by properly closing any
/// open tags and handling self-closing tags. It also preserves certain
/// tags (like `<img>`, `<video>`, etc.) as whole blocks without counting their
/// content towards the visible character limit.
///
/// \param html The input HTML string to be sliced.
/// \param maxLength The maximum number of visible characters to retain in the output.
/// \param preserveNewlines If true, newline characters in the input HTML are
/// preserved in the output. If false, newline characters are replaced
/// with spaces.
///
/// \returns A valid HTML string truncated to the specified number of visible characters.
String sliceHtml(
  String html,
  int maxLength, {
  bool preserveNewlines = true,
}) {
  final buffer = StringBuffer();
  final openTags = <String>[]; // store the original-case tag names

  const preserveTags = {'title', 'head', 'img', 'video', 'audio', 'iframe'};
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
  final tagNameRegExp = RegExp(r'<\s*/?\s*([^\s>/]+)');

  var visibleCount = 0;
  var i = 0;

  while (i < html.length && visibleCount < maxLength) {
    if (html[i] == '<') {
      final closeIdx = html.indexOf('>', i);
      if (closeIdx == -1) break;
      final tagText = html.substring(i, closeIdx + 1);

      // <!DOCTYPE or <!-- --> or similar
      if (tagText.startsWith('<!')) {
        buffer.write(tagText);
        i = closeIdx + 1;
        continue;
      }

      final match = tagNameRegExp.firstMatch(tagText);
      if (match == null) {
        buffer.write(tagText);
        i = closeIdx + 1;
        continue;
      }

      final rawTagName = match.group(1)!;
      final lowerTagName = rawTagName.toLowerCase();
      final isClosingTag = tagText.startsWith('</');

      // Attempt to preserve entire block
      if (!isClosingTag && preserveTags.contains(lowerTagName)) {
        final isSelfClosing =
            tagText.endsWith('/>') || voidElements.contains(lowerTagName);
        if (!isSelfClosing) {
          final closingStr = '</$lowerTagName>';
          final closePos = html.indexOf(closingStr, closeIdx + 1);
          if (closePos != -1) {
            final closeEnd = html.indexOf('>', closePos);
            if (closeEnd != -1) {
              // copy entire block
              buffer.write(html.substring(i, closeEnd + 1));
              i = closeEnd + 1;
              continue;
            }
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
      if (html[i] == '\n' || html[i] == '\r') {
        // If preserveNewlines is true => literal newline, else turn it
        // into space
        if (preserveNewlines) {
          buffer.write(html[i]);
        } else {
          // Replace with a space or remove entirely. Here we use a space:
          buffer.write(' ');
        }
        // Do NOT count newline as visible
        i++;
      } else {
        // normal visible char
        buffer.write(html[i]);
        visibleCount++;
        i++;
      }
    }
  }

  // If truncated
  if (i < html.length) {
    buffer.write('...');
  }

  // close unclosed
  while (openTags.isNotEmpty) {
    final t = openTags.removeLast();
    buffer.write('</$t>');
  }

  return buffer.toString();
}
