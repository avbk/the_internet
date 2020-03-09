import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  httpClientTestGroup((test) {
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
  });
}
