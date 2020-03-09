import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  dioClientTestGroup("GET", (test) {
    test("has a mockAdapter", (server, dio) {
      expect(dio.httpClientAdapter, isA<HttpClientAdapter>());
    });

    test("allows to respond with json and JSON is converted to Map",
        (server, dio) async {
      server.get(
        "/messages",
        body: {
          "page": 1,
          "messages": ["Hello", "World"],
        },
      );
      final Response<Map> response =
          await dio.get("https://example.com/messages");

      expect(response.statusCode, 200);
      expect(response.data, {
        "page": 1,
        "messages": ["Hello", "World"],
      });
      expect(response.headers.map, {
        "content-type": ["application/json"]
      });
    });
  });
}
