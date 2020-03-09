import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  multiClientTestGroup("HEAD", (test) {
    test(
      "respond with 204",
      configure: (server) => server.head(
        "/messages/17",
        code: 204,
        headers: {"X-Server-Type": "Mocked"},
      ),
      request: {"path": "/messages/17"},
      response: {
        "code": 204,
        "body": isEmpty,
        "headers": {"X-Server-Type": "Mocked"},
      },
    );
  });
}
