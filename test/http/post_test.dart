import 'dart:convert';

import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  httpClientTestGroup("POST", (test) {
    test("can create very simple POST mock", (server, client) async {
      server.post("/messages", code: 204);

      final response = await client.post(
        "https://example.com/messages",
        body: {"title": "Hello"},
      );

      expect(response.statusCode, 204);
      expect(response.body, isEmpty);
      expect(response.headers, isEmpty);
    });

    test("GET and POST do not collide", (server, client) async {
      server.post("/messages", code: 204);
      server.get("/messages", body: ["Hello"]);

      final getResponse = await client.get("https://example.com/messages");
      final postResponse = await client.post(
        "https://example.com/messages",
        body: {"title": "Hello"},
      );

      expect(getResponse.statusCode, 200);
      expect(getResponse.body, '["Hello"]');
      expect(getResponse.headers["Content-Type"], "application/json");

      expect(postResponse.statusCode, 204);
      expect(postResponse.body, isEmpty);
      expect(postResponse.headers, isEmpty);
    });

    test("formdata can be inspected afterwards", (server, client) async {
      server.post("/messages", code: 204);

      final response = await client.post(
        "https://example.com/messages",
        body: {"title": "Hello"},
      );

      expect(response.statusCode, 204);
      expect(response.body, isEmpty);
      expect(response.headers, isEmpty);

      final recordedCall = server.nextCapturedCall();

      expect(recordedCall.response.code, 204);
      expect(recordedCall.response.body, isEmpty);
      expect(recordedCall.response.headers, isEmpty);

      expect(recordedCall.request.url, "https://example.com/messages");
      expect(recordedCall.request.body.asString, "title=Hello");
      expect(recordedCall.request.body.asFormData["title"], "Hello");
      expect(recordedCall.request.body.asJson, isNull);

      expect(
        recordedCall.request.headers["Content-Type"],
        // ignore encoding ("; charset=utf-8" is appended)
        startsWith("application/x-www-form-urlencoded"),
      );
    });

    test("json can be inspected afterwards", (server, client) async {
      server.post("/messages", code: 204);

      await client.post("https://example.com/messages",
          body: jsonEncode({"title": "Hello"}),
          headers: {"Content-Type": "application/json"});

      final recordedCall = server.nextCapturedCall();

      expect(recordedCall.response.code, 204);
      expect(recordedCall.response.body, isEmpty);
      expect(recordedCall.response.headers, isEmpty);

      expect(recordedCall.request.url, "https://example.com/messages");
      expect(recordedCall.request.body.asString, '{"title":"Hello"}');
      expect(recordedCall.request.body.asFormData, isNull);
      expect(recordedCall.request.body.asJson["title"], "Hello");

      expect(
        recordedCall.request.headers["Content-Type"],
        // ignore encoding ("; charset=utf-8" is appended)
        startsWith("application/json"),
      );
    });
  });
}
