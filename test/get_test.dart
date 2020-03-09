import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

import 'test_utils.dart';

void main() {
  multiClientTestGroup("GET", (test) {
    test(
      "uses 200 <EMPTY> as default",
      configure: (server) => server.get("/nothing"),
      request: {"path": "/nothing"},
      response: {"code": 200, "body": isEmpty, "headers": isEmpty},
    );

    test(
      "allows to create a very simple GET mock",
      configure: (server) => server.get("/messages/17", code: 404),
      request: {"path": "/messages/17"},
      response: {"code": 404, "body": isEmpty, "headers": isEmpty},
    );

    test(
      "allows to respond with string",
      configure: (server) => server.get("/messages", body: "Hello World!"),
      request: {"path": "/messages"},
      response: {"code": 200, "body": "Hello World!", "headers": isEmpty},
    );

    test(
      "allows to respond with string and custom code and headers",
      configure: (server) => server.get(
        "/messages",
        code: 417,
        body: "Hello World!",
        headers: {"X-Server-Type": "Mock"},
      ),
      request: {"path": "/messages"},
      response: {
        "code": 417,
        "body": "Hello World!",
        "headers": {"X-Server-Type": "Mock"}
      },
    );

    test(
      "allows to respond with json",
      configure: (server) => server.get(
        "/messages",
        body: {
          "page": 1,
          "messages": ["Hello", "World"],
        },
      ),
      request: {"path": "/messages"},
      response: {
        "code": 200,
        "body": '{"page":1,"messages":["Hello","World"]}',
        "headers": {"Content-Type": "application/json"}
      },
    );

    test(
      "allows to respond with json and custom code and headers",
      configure: (server) => server.get("/messages", code: 417, headers: {
        "X-Server-Type": "Mock"
      }, body: {
        "page": 1,
        "messages": ["Hello", "World"],
      }),
      request: {"path": "/messages"},
      response: {
        "code": 417,
        "body": '{"page":1,"messages":["Hello","World"]}',
        "headers": {"Content-Type": "application/json", "X-Server-Type": "Mock"}
      },
    );

    test(
      "allows to respond with json based on regex",
      configure: (server) => server.get("/messages/(.*)",
          body: (args) => {"message": "Hello ${args[0]}"}),
      request: {"path": "/messages/people"},
      response: {
        "code": 200,
        "body": '{"message":"Hello people"}',
        "headers": {"Content-Type": "application/json"}
      },
    );

    test(
      "allows to respond with json based on regex and headers",
      configure: (server) => server.get("/messages/(.*)",
          body: (CapturedRequest request, List<String> args) =>
              {"message": "${request.headers["greeting"]} ${args[0]}"}),
      request: {
        "path": "/messages/people",
        "headers": {"greeting": "Hi"},
      },
      response: {
        "code": 200,
        "body": '{"message":"Hi people"}',
        "headers": {"Content-Type": "application/json"}
      },
    );

    test(
      "allows to respond with anything based on regex and headers",
      configure: (server) {
        server.get(
          "/messages/(.*)",
          response: (request, args) => MockedResponse(200,
              body: "${request.headers["greeting"]} ${args[0]}"),
        );
      },
      request: {
        "path": "/messages/people",
        "headers": {"greeting": "Hi"},
      },
      response: {
        "code": 200,
        "body": "Hi people",
        "headers": isEmpty,
      },
    );
  });
}
