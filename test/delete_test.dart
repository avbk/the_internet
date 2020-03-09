import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  multiClientTestGroup("DELETE", (test) {
    test(
      "respond with 204",
      configure: (server) => server.delete("/messages/17", code: 204),
      request: {"path": "/messages/17"},
      response: {"code": 204, "body": isEmpty, "headers": isEmpty},
    );
  });
}
