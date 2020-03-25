import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

import 'test_utils.dart';

void main() {
  httpClientTestGroup((test) {
    test("bodyBuilder can be async", (server, client) async {
      server.get("/messages", bodyBuilder: (request) async {
        await Future.delayed(Duration(milliseconds: 100));
        return {"status": "okay"};
      });

      final response = await client.get("https://example.com/messages");
      expect(response.body, '{"status":"okay"}');
    });

    test("responseBuilder can be async", (server, client) async {
      server.get("/messages", responseBuilder: (request) async {
        await Future.delayed(Duration(milliseconds: 100));
        return MockedResponse(201);
      });

      final response = await client.get("https://example.com/messages");
      expect(response.statusCode, 201);
    });
  });
}
