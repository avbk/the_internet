import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

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

typedef _simpleHttpRequest = Future<http.Response> Function(
  String url, {
  Map<String, String> headers,
});
typedef _bodyHttpRequest = Future<http.Response> Function(
  String url, {
  Map<String, String> headers,
  dynamic body,
  Encoding encoding,
});

typedef _simpleDioRequest = Future<dio.Response> Function(
  String path, {
  Map<String, dynamic> queryParameters,
  dio.Options options,
  dio.CancelToken cancelToken,
  dio.ProgressCallback onReceiveProgress,
});
typedef _simpleBodyDioRequest = Future<dio.Response> Function(
  String path, {
  dynamic data,
  Map<String, dynamic> queryParameters,
  dio.Options options,
  dio.CancelToken cancelToken,
});

typedef _bodyDioRequest = Future<dio.Response> Function(
  String path, {
  dynamic data,
  Map<String, dynamic> queryParameters,
  dio.Options options,
  dio.CancelToken cancelToken,
  dio.ProgressCallback onSendProgress,
  dio.ProgressCallback onReceiveProgress,
});

void multiClientTestGroup(String method, MultiClientTestGroup innerGroup) {
  innerGroup((
    String description, {
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

      Future<http.Response> executeSimpleHttpCall(_simpleHttpRequest call) =>
          call(url, headers: request["headers"]);

      Future<http.Response> executeBodyHttpCall(_bodyHttpRequest call) {
        if (request["formData"] != null)
          return call(
            url,
            headers: request["headers"],
            body: request["formData"],
          );
        else if (request["json"] != null) {
          final headers = request["headers"];
          if (headers != null) headers["Content-Type"] = "application/json";

          return call(
            url,
            headers: headers,
            body: jsonEncode(request["json"]),
          );
        } else {
          return call(
            url,
            headers: request["headers"],
            body: request["body"],
          );
        }
      }

      final dio.Options dioOptions = dio.Options(
        headers: request["headers"],
        responseType: dio.ResponseType.plain,
      );

      Future<dio.Response> executeSimpleDioCall(_simpleDioRequest call) {
        return call(url, options: dioOptions);
      }

      Future<dio.Response> executeSimpleBodyDioCall(
          _simpleBodyDioRequest call) {
        if (request["formData"] != null) {
          return call(url,
              data: dio.FormData.fromMap(
                request["formData"],
              ),
              options: dioOptions);
        } else if (request["json"] != null) {
          return call(
            url,
            data: request["json"],
            options: dioOptions,
          );
        } else {
          return call(
            url,
            data: request["body"],
            options: dioOptions,
          );
        }
      }

      Future<dio.Response> executeBodyDioCall(_bodyDioRequest call) =>
          executeSimpleBodyDioCall((path,
              {cancelToken, data, options, queryParameters}) =>
              call(path, data: data, options: options));

      void verifyRecordedCall() {
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
      }

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
          resp = await executeSimpleHttpCall(httpClient.get);
        else if (method == "DELETE")
          resp = await executeSimpleHttpCall(httpClient.delete);
        else if (method == "HEAD")
          resp = await executeSimpleHttpCall(httpClient.head);
        else if (method == "POST")
          resp = await executeBodyHttpCall(httpClient.post);
        else if (method == "PUT")
          resp = await executeBodyHttpCall(httpClient.put);
        else if (method == "PATCH")
          resp = await executeBodyHttpCall(httpClient.patch);

        expect(resp.statusCode, response["code"]);
        expect(resp.body, response["body"]);
        expect(resp.headers, response["headers"]);

        verifyRecordedCall();
      });
      test("with dio", () async {
        dio.Response resp;
        try {
          if (method == "GET")
            resp = await executeSimpleDioCall(dioClient.get);
          else if (method == "DELETE")
            resp = await executeSimpleBodyDioCall(dioClient.delete);
          else if (method == "HEAD")
            resp = await executeSimpleBodyDioCall(dioClient.head);
          else if (method == "POST")
            resp = await executeBodyDioCall(dioClient.post);
          else if (method == "PUT")
            resp = await executeBodyDioCall(dioClient.put);
          else if (method == "PATCH")
            resp = await executeBodyDioCall(dioClient.patch);
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

        verifyRecordedCall();
      });
    });
  });
}
