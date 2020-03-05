A library to easily create and configure a MockHttpClient.

## Usage

A simple usage example:

```dart
import 'package:the_internet/the_internet.dart';

main() {
  final internet = TheInternet();
  final server = internet.mockServer("https://example.com");
  server
      ..get("/messages", json: ["Hello", "World"])
      ..post("/messages", code: 204);
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/avbk/the_internet/issues
