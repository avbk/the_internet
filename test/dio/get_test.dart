import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

import '../test_utils.dart';

void main() {
  dioClientTestGroup("GET", (test) {
    test("has a mockAdapter", (server, dio) {
      expect(dio.httpClientAdapter, isA<HttpClientAdapter>());
    });

    test("allows to respond with json based on regex and headers",
        (server, dio) async {
      server.get(
        "/messages/(.*)",
        response: (request, args) => MockedResponse(200,
            body: "${request.headers["greeting"]} ${args[0]}"),
      );

      final response = await dio.get("https://example.com/messages/people",
          options: Options(headers: {"greeting": "Hi"}));

      expect(response.statusCode, 200);
      expect(response.data, "Hi people");
      expect(response.headers.map, isEmpty);
    });
  });
}
