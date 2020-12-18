The Internet is a random, uncontrollable and sometimes even scary place... 😵
 
But fear not! 
Now you can build your own internet and decide on your own 


A library to easily create and configure a MockHttpClient.

## Installation 
Add the following lines to `pubspec.yaml`
```yaml
dependencies:
    the_internet: 
      git: https://github.com/avbk/the_internet.git
      ref: 1.0.0
```
_This method is only temporary until the package is published via pub.dev_


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
