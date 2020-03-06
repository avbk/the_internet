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
