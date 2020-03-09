import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  httpClientTestGroup("GET", (test) {
    test("allows to obtain a mocked BaseClient", (server, client) {
      expect(client, isA<MockClient>());
    });
  });
}
