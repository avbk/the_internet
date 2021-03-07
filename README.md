The Internet is a random, uncontrollable and sometimes even scary place... 😵
 
But fear not! 
Now you can build your own internet and decide on your own, how your backend has to answer in order
to create reproducible tests.

## Features
* Simple configuration of mockservers
* Path matching and argument parsing
* Custom builders to build tailored responses
* Supports dio and http
* Calls a recorded and can be verified
 

## Installation 
Add the following lines to `pubspec.yaml`
```yaml
dev_dependencies:
    the_internet: ^1.0.0
```

## Usage

A simple usage example:

```dart
import 'package:the_internet/the_internet.dart';

void main() {
  final internet = TheInternet();
  final server = internet.mockServer("https://demoapi.com");

  server
    ..get("/messages", body: [
      {"id": 5, "msg": "Hello"},
      {"id": 19, "msg": "World"}
    ])
    ..post(
      "/messages",
      bodyBuilder: (request) => request.body?.asJson + {"id": 17},
    )
    ..delete("/messages/{id}", code: 204);
}
```

This will create a mockserver, which will respond to "GET /messages", "POST /messages" and 
"DELETE /message/{id}". In order to use this server instead of the real one you need to use 
a special implementation of the http or dio client:
```dart
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;

void main() {
  /* ... */

  final http.BaseClient httpClient = internet.createHttpClient();
  final dio.Dio dioClient = dio.Dio()
    ..httpClientAdapter = internet.createDioAdapter();
}
```

## Examples

#### A simple POST with http client
```dart
  test("create a message with http", () async {
    // Install a handler for POST /messages
    server.post("/messages", code: 201);

    // create a new message via http client
    final uri = Uri.parse("https://demoapi.com/messages");
    final response = await httpClient.post(uri, body: {"title": "Hello"});

    // verify the mocked response
    expect(response.statusCode, 201);
    expect(response.body, isEmpty);

    // verify the request captured by the handler
    final recordedCall = server.nextCapturedCall();

    expect(recordedCall.request.uri, uri);
    expect(recordedCall.request.body?.asString, "title=Hello");
    expect(recordedCall.request.body?.asFormData?["title"], "Hello");
    expect(recordedCall.request.body?.asJson, isNull);
  });
```

### A simple GET with dio client
```dart
  test("get messages with dio", () async {
    // Install a handler for GET /messages
    server.get("/messages", body: [
      {"id": 5, "msg": "Hello"},
      {"id": 19, "msg": "World"},
    ]);

    // get messages via dio client
    final uri = Uri.parse("https://demoapi.com/messages");
    final response = await dioClient.get("https://demoapi.com/messages");

    // verify the mocked response
    expect(response.statusCode, 200);
    expect(response.data, [
      {"id": 5, "msg": "Hello"},
      {"id": 19, "msg": "World"},
    ]);

    // verify the request captured by the handler
    final recordedCall = server.nextCapturedCall();

    expect(recordedCall.request.uri, uri);
    expect(recordedCall.request.body, isNull);
  });
```

### Response based on request
```dart
  test("build a complex response", () async {
    // Install a handler for GET /messages/{id}
    server.get("/messages/{id}", responseBuilder: (request) {
      final id = int.tryParse(request.args["id"] ?? "");
      if (id != null) {
        return MockedResponse.fromJson({
          "id": id,
          "title": "Message $id",
        });
      } else {
        return MockedResponse(404);
      }
    });

    // get a bad message via http client
    final badResponse = await httpClient.get(
      Uri.parse("https://demoapi.com/messages/not-a-number"),
    );

    // verify the mocked response
    expect(badResponse.statusCode, 404);
    expect(badResponse.body, isEmpty);

    // get a correct message via http client
    final messageResponse = await httpClient.get(
      Uri.parse("https://demoapi.com/messages/17"),
    );

    // verify the mocked response
    expect(messageResponse.statusCode, 200);
    expect(messageResponse.body, '{"id":17,"title":"Message 17"}');
  });
```
### Queuing handlers
```dart
  test("handlers can be queued", () async {
    // Install a handler for a single GET /ping
    server.get("/ping", code: 204, times: 1);
    // Install a second handler for any subsequent GET /ping
    server.get("/ping", code: 404);

    // call /ping a couple of times
    final uri = Uri.parse("https://demoapi.com/ping");
    final response1 = await httpClient.get(uri);
    final response2 = await httpClient.get(uri);
    final response3 = await httpClient.get(uri);

    // verify the response codes
    expect(response1.statusCode, 204);
    expect(response2.statusCode, 404);
    expect(response3.statusCode, 404);
  });
```



## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/avbk/the_internet/issues
