import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  multiClientTestGroup("POST", (test) {
    test(
      "can create very simple POST mock",
      configure: (server) => server.post("/messages", code: 204),
      request: {"path": "/messages"},
      response: {"code": 204, "body": isEmpty, "headers": isEmpty},
    );

    test("formdata can be inspected afterwards",
        configure: (server) => server.post("/messages", code: 204),
        request: {
          "path": "/messages",
          "formData": {"title": "Hello"}
        },
        response: {
          "code": 204,
          "body": isEmpty,
          "headers": isEmpty
        },
        recorded: {
          "request": {
            "url": "https://example.com/messages",
            "bodyAsString": "title=Hello",
            "bodyAsFormData": {"title": "Hello"},
            "bodyAsJson": isNull
          },
          "response": {"code": 204, "body": isEmpty, "headers": isEmpty},
        });

    test("json can be inspected afterwards",
        configure: (server) => server.post("/messages", code: 204),
        request: {
          "path": "/messages",
          "json": {"title": "Hello"}
        },
        response: {
          "code": 204,
          "body": isEmpty,
          "headers": isEmpty
        },
        recorded: {
          "request": {
            "url": "https://example.com/messages",
            "bodyAsString": '{"title":"Hello"}',
            "bodyAsFormData": isNull,
            "bodyAsJson": {"title": "Hello"}
          },
          "response": {"code": 204, "body": isEmpty, "headers": isEmpty},
        });

    test("respond with input data",
        configure: (server) => server.post("/messages",
            bodyBuilder: (request) =>
                {"newMessage": "message ${request.body.asFormData?["title"]}"}),
        request: {
          "path": "/messages",
          "formData": {"title": "Hello"}
        },
        response: {
          "code": 200,
          "body": '{"newMessage":"message Hello"}',
          "headers": {"Content-Type": "application/json"}
        });
  });
}
