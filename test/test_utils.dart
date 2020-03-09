import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:the_internet/src/the_internet_base.dart';

typedef HttpClientTestCallback = Function(
    MockedServer server, BaseClient client);
typedef HttpClientTest = Function(
    String description, HttpClientTestCallback test);
typedef HttpClientTestGroup = Function(HttpClientTest test);

void httpClientTestGroup(String method, HttpClientTestGroup innerGroup) {
  group("[HttpClient $method]", () {
    TheInternet internet;
    MockedServer server;
    BaseClient client;

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

typedef DioClientTestCallback = Function(MockedServer server, Dio dio);
typedef DioClientTest = Function(
    String description, DioClientTestCallback test);
typedef DioClientTestGroup = Function(DioClientTest test);

void dioClientTestGroup(String method, DioClientTestGroup innerGroup) {
  group("[Dio $method]", () {
    TheInternet internet;
    MockedServer server;
    Dio dio;

    setUp(() {
      internet = TheInternet();
      server = internet.mockServer("https://example.com");
      dio = Dio();
      dio.httpClientAdapter = internet.createDioAdapter();
    });

    innerGroup((String description, DioClientTestCallback callback) {
      test(description, () async {
        await callback(server, dio);
      });
    });
  });
}
