import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:the_internet/src/the_internet_base.dart';

typedef HttpClientTestCallback = Function(
    MockedServer server, http.BaseClient client);
typedef HttpClientTest = Function(
    String description, HttpClientTestCallback test);
typedef HttpClientTestGroup = Function(HttpClientTest test);

void httpClientTestGroup(HttpClientTestGroup innerGroup) {
  group("HttpClient", () {
    TheInternet internet;
    MockedServer server;
    http.BaseClient client;

    setUp(() {
      internet = TheInternet();
      server = internet.mockServer("https://example.com");
      client = internet.createHttpClient();
    });

    innerGroup((String description, HttpClientTestCallback callback) {
      test(description, () async {
        await callback(server, client);
      });
    });
  });
}

typedef DioClientTestCallback = Function(MockedServer server, dio.Dio dio);
typedef DioClientTest = Function(
    String description, DioClientTestCallback test);
typedef DioClientTestGroup = Function(DioClientTest test);

void dioClientTestGroup(DioClientTestGroup innerGroup) {
  group("Dio", () {
    TheInternet internet;
    MockedServer server;
    dio.Dio dioClient;

    setUp(() {
      internet = TheInternet();
      server = internet.mockServer("https://example.com");
      dioClient = dio.Dio();
      dioClient.httpClientAdapter = internet.createDioAdapter();
    });

    innerGroup((String description, DioClientTestCallback callback) {
      test(description, () async {
        await callback(server, dioClient);
      });
    });
  });
}

typedef MultiClientConfigCallback = Function(MockedServer server);
typedef MultiClientTest = Function(
  String description, {
  MultiClientConfigCallback configure,
  Map<String, dynamic> request,
  Map<String, dynamic> response,
  Map<String, dynamic> recorded,
});
typedef MultiClientTestGroup = Function(MultiClientTest test);

void multiClientTestGroup(String method, MultiClientTestGroup innerGroup) {
  innerGroup((String description, {
    MultiClientConfigCallback configure,
    Map<String, dynamic> request,
    Map<String, dynamic> response,
    Map<String, dynamic> recorded,
  }) {
    group(description, () {
      TheInternet internet;
      MockedServer server;
      http.BaseClient httpClient;
      dio.Dio dioClient;
      String url;

      setUp(() {
        internet = TheInternet();
        server = internet.mockServer("https://example.com");

        httpClient = internet.createHttpClient();
        dioClient = dio.Dio();
        dioClient.httpClientAdapter = internet.createDioAdapter();

        configure(server);
        url = request["url"] ?? "https://example.com${request["path"]}";
      });

      test("with http", () async {
        http.Response resp;
        if (method == "GET")
          resp = await httpClient.get(
            url,
            headers: request["headers"],
          );
        else if (method == "POST") {
          if (request["formData"] != null)
            resp = await httpClient.post(
              url,
              headers: request["headers"],
              body: request["formData"],
            );
          else if (request["json"] != null) {
            final headers = request["headers"];
            if (headers != null) headers["Content-Type"] = "application/json";

            resp = await httpClient.post(
              url,
              headers: headers,
              body: jsonEncode(request["json"]),
            );
          } else {
            resp = await httpClient.post(
              url,
              headers: request["headers"],
              body: request["body"],
            );
          }
        }

        expect(resp.statusCode, response["code"]);
        expect(resp.body, response["body"]);
        expect(resp.headers, response["headers"]);

        if (recorded != null) {
          final recordedCall = server.nextCapturedCall();

          if (recorded["response"] != null) {
            expect(recordedCall.response.code, recorded["response"]["code"]);
            expect(recordedCall.response.body, recorded["response"]["body"]);
            expect(
                recordedCall.response.headers, recorded["response"]["headers"]);
          }

          if (recorded["request"] != null) {
            expect(recordedCall.request.url, recorded["request"]["url"]);
            expect(recordedCall.request.body?.asString,
                recorded["request"]["bodyAsString"]);
            expect(recordedCall.request.body?.asFormData,
                recorded["request"]["bodyAsFormData"]);
            expect(recordedCall.request.body?.asJson,
                recorded["request"]["bodyAsJson"]);

            // only check extra headers (not content type or alike)
            if (recorded["request"]["headers"] != null)
              expect(recordedCall.request.headers.entries,
                  containsAll(recorded["request"]["headers"].entries));
          }
        }
      });
      test("with dio", () async {
        dio.Response resp;
        final dio.Options options = dio.Options(
          headers: request["headers"],
          responseType: dio.ResponseType.plain,
        );
        try {
          if (method == "GET")
            resp = await dioClient.get(url, options: options);
          else if (method == "POST") {
            if (request["formData"] != null) {
              resp = await dioClient.post(url,
                  data: dio.FormData.fromMap(
                    request["formData"],
                  ),
                  options: options);
            } else if (request["json"] != null) {
              resp = await dioClient.post(
                url,
                data: request["json"],
                options: options,
              );
            } else {
              resp = await dioClient.post(
                url,
                data: request["body"],
                options: options,
              );
            }
          }
        } catch (e) {
          expect(e, isA<dio.DioError>());
          dio.DioError error = e as dio.DioError;
          resp = error.response;
        }

        if (response['headers'] is Map && response['headers'].isNotEmpty)
          response['headers'] = Map.fromEntries(
              (response['headers'] as Map<String, String>)
                  .entries
                  .map((e) => MapEntry(e.key.toLowerCase(), [e.value])));

        expect(resp.statusCode, response["code"]);
        expect(resp.data, response["body"]);
        expect(resp.headers.map, response["headers"]);

        if (recorded != null) {
          final recordedCall = server.nextCapturedCall();

          if (recorded["response"] != null) {
            expect(recordedCall.response.code, recorded["response"]["code"]);
            expect(recordedCall.response.body, recorded["response"]["body"]);
            expect(
                recordedCall.response.headers, recorded["response"]["headers"]);
          }

          if (recorded["request"] != null) {
            String url = recordedCall.request.url;
            if (method == "POST" && url.contains("?"))
              url = url
                  .split("?")
                  .first;

            expect(url, recorded["request"]["url"]);
            expect(recordedCall.request.body?.asString,
                recorded["request"]["bodyAsString"]);
            expect(recordedCall.request.body?.asFormData,
                recorded["request"]["bodyAsFormData"]);
            expect(recordedCall.request.body?.asJson,
                recorded["request"]["bodyAsJson"]);

            // only check extra headers (not content type or alike)
            if (recorded["request"]["headers"] != null)
              expect(recordedCall.request.headers.entries,
                  containsAll(recorded["request"]["headers"].entries));
          }
        }
      });
    });
  });
}
