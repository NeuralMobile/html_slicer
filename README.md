# Html Slicer

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

The `html_slicer` package is a lightweight and efficient utility for slicing
HTML strings while preserving the structure and validity of the HTML. It is
designed for both **Dart** and **Flutter** projects, making it ideal for
scenarios where you need to truncate HTML content to a specified maximum length
of visible characters without breaking the HTML tags or structure. This package
is particularly useful for applications that handle rich text or HTML content,
such as web apps, mobile apps, or server-side Dart projects.

---

## Features

- **Preserves HTML Structure**: Ensures the HTML remains valid by properly
  closing open tags and handling self-closing tags.
- **Customizable Length**: Slice HTML content to a specified maximum number of
  visible characters.
- **Preserve Newlines**: Optionally preserve newline characters or replace them
  with spaces.
- **Handles Special Tags**: Preserves entire blocks of specific tags (e.g.,
  `<img>`, `<video>`, `<audio>`, etc.) without counting their content toward the
  visible character limit.
- **Cross-Platform**: Works seamlessly in **Dart** projects (e.g., server-side
  or CLI apps) and **Flutter** projects (mobile, web, and desktop).
- **Lightweight and Fast**: Optimized for performance, making it suitable for
  both small and large-scale applications.

---

## Installation 💻

**❗ In order to start using Html Slicer you must have
the [Dart SDK][dart_install_link] installed on your machine.**

### **For Dart Projects**

Run the following command in your terminal:

```bash
dart pub add html_slicer
```

### **For Flutter Projects**

Run the following command in your terminal:

```bash
flutter pub add html_slicer
```

### **Manual Installation**

Alternatively, you can manually add the `html_slicer` package to your
`pubspec.yaml` file under `dependencies`:

```yaml
dependencies:
  html_slicer: ^0.1.0
```

Then, run the following command to install the package:

- For Dart projects:
  ```bash
  dart pub get
  ```
- For Flutter projects:
  ```bash
  flutter pub get
  ```

### **Importing the Package**

Once installed, import the package in your Dart or Flutter code:

```dart
import 'package:html_slicer/html_slicer.dart';
```

---

## Usage

The package provides a single method, `sliceHtml`, which can be used to slice
HTML strings while preserving their structure.

### **Method Signature**

```dart
String sliceHtml(String html,
    int maxLength, {
      bool preserveNewlines = true,
      Set<String> preserveTags = defaultPreserveTags,
      String ellipsis = '...',
    });
```

### **Parameters**

- **`html`**: The input HTML string to be sliced.
- **`maxLength`**: The maximum number of visible characters to retain in the
  output.
- **`preserveNewlines`**: If `true`, newline characters in the input HTML are
  preserved in the output. If `false`, newline characters are replaced with
  spaces.
- **`preserveTags`**: A set of tag names whose full blocks are preserved
  without counting their inner content toward `maxLength`.
- **`ellipsis`**: The string appended only when visible content is truncated.

### **Returns**

- A valid HTML string truncated to the specified number of visible characters.

---

### **Example in Dart**

```dart
import 'package:html_slicer/html_slicer.dart';

void main() {
  String htmlContent = '''
    <div>
      <h1>Hello, World!</h1>
      <p>This is a <strong>sample</strong> HTML content.</p>
      <img src="image.jpg" alt="Sample Image">
    </div>
  ''';

  // Slice the HTML to a maximum of 20 visible characters
  String slicedHtml = sliceHtml(htmlContent, 20, preserveNewlines: true);

  print(slicedHtml);
}
```

### **Output**

The output will be a valid HTML string truncated to the specified number of
visible characters:

```html

<div>
    <h1>Hello, World!</h1>
    <p>This is a <strong>sample</strong> HTML...</p>
    <img src="image.jpg" alt="Sample Image">
</div>
```

---

### **Example in Flutter**

If you're using Flutter, you can use the `html_slicer` package to truncate HTML
content for display in a `Text` widget or other UI components:

```dart
import 'package:flutter/material.dart';
import 'package:html_slicer/html_slicer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String htmlContent = '''
      <div>
        <h1>Hello, World!</h1>
        <p>This is a <strong>sample</strong> HTML content.</p>
        <img src="image.jpg" alt="Sample Image">
      </div>
    ''';

    String slicedHtml = sliceHtml(htmlContent, 20, preserveNewlines: true);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('HTML Slicer Example')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(slicedHtml),
        ),
      ),
    );
  }
}
```

---

## Use Cases

- **Truncating Rich Text**: Display a preview of HTML content (e.g., blog posts,
  articles) without breaking the structure.
- **Social Media Previews**: Generate shortened HTML snippets for sharing on
  social media platforms.
- **Email Clients**: Truncate HTML emails while preserving their formatting and
  embedded media.
- **Server-Side Dart**: Use in backend applications to process and serve
  truncated HTML content.
- **CLI Tools**: Integrate into Dart command-line tools for HTML manipulation.

---

## Continuous Integration 🤖

Html Slicer comes with a built-in [GitHub Actions workflow][github_actions_link]
powered by [Very Good Workflows][very_good_workflows_link] but you can also add
your preferred CI/CD solution.

Out of the box, on each pull request and push, the CI `formats`, `lints`, and
`tests` the code. This ensures the code remains consistent and behaves correctly
as you add functionality or make changes. The project
uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis
options used by our team. Code coverage is enforced using
the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests �

To run all unit tests:

```sh
dart pub global activate coverage 1.2.0
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can
use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

---

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions for
improvements, please open an issue on
the [GitHub repository](https://github.com/NeuralMobile/html_slicer). If you'd
like to contribute code, feel free to fork the repository and submit a pull
request.

### **Steps to Contribute**

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Make your changes and ensure all tests pass.
4. Submit a pull request with a detailed description of your changes.

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE)
file for details.

---

## Acknowledgments

- Thanks to the Dart and Flutter communities for their continuous support and
  contributions.

[dart_install_link]: https://dart.dev/get-dart

[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg

[license_link]: https://opensource.org/licenses/MIT

[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg

[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis

[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage

[very_good_ventures_link]: https://verygood.ventures

[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only

[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only

[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
