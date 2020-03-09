import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

import 'test_utils.dart';

void main() {
  multiClientTestGroup("PATCH", (test) {
    test("respond with input data and check recorded call",
        configure: (server) => server.patch("/messages",
            body: (CapturedRequest request, _) =>
                {"newMessage": "message ${request.body.asFormData["title"]}"}),
        request: {
          "path": "/messages",
          "formData": {"title": "Hello"}
        },
        response: {
          "code": 200,
          "body": '{"newMessage":"message Hello"}',
          "headers": {"Content-Type": "application/json"}
        },
        recorded: {
          "request": {
            "url": "https://example.com/messages",
            "bodyAsString": "title=Hello",
            "bodyAsFormData": {"title": "Hello"},
            "bodyAsJson": isNull
          },
          "response": {
            "code": 200,
            "body": '{"newMessage":"message Hello"}',
            "headers": {"Content-Type": "application/json"}
          },
        });
  });
}
