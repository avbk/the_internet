import 'dart:convert';

import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  httpClientTestGroup((test) {
    test("allows to obtain a mocked BaseClient", (server, client) {
      expect(client, isA<MockClient>());
    });

    test("formdata header is added to request", (server, client) async {
      server.post("/messages", code: 204);

      await client.post(
        "https://example.com/messages".asUri,
        body: {"title": "Hello"},
      );

      final recordedCall = server.nextCapturedCall();

      expect(
        recordedCall.request.headers["Content-Type"],
        "application/x-www-form-urlencoded; charset=utf-8",
      );
    });

    test("formdata can be inspected afterwards", (server, client) async {
      server.post("/messages", code: 204);

      final response = await client.post(
        "https://example.com/messages".asUri,
        body: {"title": "Hello"},
      );

      expect(response.statusCode, 204);
      expect(response.body, isEmpty);
      expect(response.headers, isEmpty);

      final recordedCall = server.nextCapturedCall();

      expect(recordedCall.response.code, 204);
      expect(recordedCall.response.body, isEmpty);
      expect(recordedCall.response.headers, isEmpty);

      expect(
          recordedCall.request.uri, Uri.parse("https://example.com/messages"));
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

      await client.post("https://example.com/messages".asUri,
          body: jsonEncode({"title": "Hello"}),
          headers: {"Content-Type": "application/json"});

      final recordedCall = server.nextCapturedCall();

      expect(
        recordedCall.request.headers["Content-Type"],
        // ignore encoding ("; charset=utf-8" is appended)
        startsWith("application/json"),
      );
    });
  });
}
