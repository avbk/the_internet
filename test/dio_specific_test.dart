import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  dioClientTestGroup((test) {
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

    test("formdata header is added to request", (server, dio) async {
      server.post("/messages", code: 204);

      await dio.post(
        "https://example.com/messages",
        data: FormData.fromMap({"title": "Hello"}),
      );

      final recordedCall = server.nextCapturedCall();

      expect(
        recordedCall.request.headers["content-type"],
        // ignore random boundary string
        startsWith("multipart/form-data; boundary=--dio-boundary-"),
      );
      expect(
        recordedCall.request.headers["content-length"],
        "115",
      );
    });

    test("json header is added to request", (server, dio) async {
      server.post("/messages", code: 204);

      await dio.post(
        "https://example.com/messages",
        data: {"title": "Hello"},
      );

      final recordedCall = server.nextCapturedCall();

      expect(
        recordedCall.request.headers["content-type"],
        "application/json; charset=utf-8",
      );
      expect(
        recordedCall.request.headers["content-length"],
        "17",
      );
    });
  });
}
