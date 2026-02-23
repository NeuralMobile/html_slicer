# 0.2.0

### Bug Fixes
- Fix HTML entities (`&amp;`, `&#65;`, `&#x41;`) miscounted as multiple characters instead of one
- Fix case-insensitive protected tag closing search (`<Video>...</Video>` now works)
- Fix HTML comments with `>` inside breaking the parser
- Fix tag attributes with `>` inside quoted values breaking the parser
- Fix CRLF (`\r\n`) producing double line breaks

### Features
- Add customizable `preserveTags` parameter with exported `defaultPreserveTags` constant
- Add customizable `ellipsis` parameter (defaults to `...`)
- Add input validation (`ArgumentError` for negative `maxLength`, early return for empty input)

### Improvements
- Add `example/main.dart` with 14 extensive use cases
- Expand test suite from 16 to 55+ test cases
- Update doc comments to Dart-style `[param]` notation
- Remove unused `mocktail` dev dependency

# 0.1.0+1

- feat: initial commit 🎉
