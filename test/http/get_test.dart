import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

import '../test_utils.dart';

void main() {
  httpClientTestGroup("GET", (test) {
    test("allows to obtain a mocked BaseClient", (server, client) {
      expect(client, isA<MockClient>());
    });

    test("uses 200 <EMPTY> as default", (server, client) async {
      server.get("/nothing");

      final response = await client.get("https://example.com/nothing");

      expect(response.statusCode, 200);
      expect(response.body, isEmpty);
      expect(response.headers, isEmpty);
    });

    test("allows to create a very simple GET mock", (server, client) async {
      server.get("/messages/17", code: 404);

      final response = await client.get("https://example.com/messages/17");

      expect(response.statusCode, 404);
      expect(response.body, isEmpty);
      expect(response.headers, isEmpty);
    });

    test("allows to respond with string", (server, client) async {
      server.get("/messages", body: "Hello World!");

      final response = await client.get("https://example.com/messages");

      expect(response.statusCode, 200);
      expect(response.body, "Hello World!");
      expect(response.headers, isEmpty);
    });

    test("allows to respond with string and custom code and headers",
        (server, client) async {
      server.get("/messages",
          code: 417, body: "Hello World!", headers: {"X-Server-Type": "Mock"});

      final response = await client.get("https://example.com/messages");

      expect(response.statusCode, 417);
      expect(response.body, "Hello World!");
      expect(response.headers["X-Server-Type"], "Mock");
    });

    test("allows to respond with json", (server, client) async {
      server.get("/messages", body: {
        "page": 1,
        "messages": ["Hello", "World"],
      });

      final response = await client.get("https://example.com/messages");

      expect(response.statusCode, 200);
      expect(response.body, '{"page":1,"messages":["Hello","World"]}');
      expect(response.headers["Content-Type"], "application/json");
    });

    test("allows to respond with json and custom code and headers",
        (server, client) async {
      server.get("/messages", code: 417, headers: {
        "X-Server-Type": "Mock"
      }, body: {
        "page": 1,
        "messages": ["Hello", "World"],
      });

      final response = await client.get("https://example.com/messages");

      expect(response.statusCode, 417);
      expect(response.body, '{"page":1,"messages":["Hello","World"]}');
      expect(response.headers["Content-Type"], "application/json");
      expect(response.headers["X-Server-Type"], "Mock");
    });

    test("allows to respond with json based on regex", (server, client) async {
      server.get("/messages/(.*)",
          body: (args) => {"message": "Hello ${args[0]}"});

      final response = await client.get("https://example.com/messages/people");

      expect(response.statusCode, 200);
      expect(response.body, '{"message":"Hello people"}');
      expect(response.headers["Content-Type"], "application/json");
    });

    test("allows to respond with json based on regex and headers",
        (server, client) async {
      server.get(
        "/messages/(.*)",
        body: (CapturedRequest request, List<String> args) =>
            {"message": "${request.headers["greeting"]} ${args[0]}"},
      );

      final response = await client.get(
        "https://example.com/messages/people",
        headers: {"greeting": "Hi"},
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"message":"Hi people"}');
      expect(response.headers["Content-Type"], "application/json");
    });

    test("allows to respond with anything based on regex and request",
        (server, client) async {
      server.get(
        "/messages/(.*)",
        response: (request, args) =>
            MockedResponse(200,
                body: "${request.headers["greeting"]} ${args[0]}"),
      );

      final response = await client.get(
        "https://example.com/messages/people",
        headers: {"greeting": "Hi"},
      );

      expect(response.statusCode, 200);
      expect(response.body, "Hi people");
      expect(response.headers, isEmpty);
    });
  });
}
