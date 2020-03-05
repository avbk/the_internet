import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

void main() {
  group('The internet ', () {
    TheInternet internet;
    MockedServer server;
    BaseClient client;

    setUp(() {
      internet = TheInternet();
      server = internet.mockServer("https://example.com");
      client = internet.createHttpClient();
    });

    test('allows to obtain a httpclient', () {
      expect(client, isA<MockClient>());
    });

    test('uses 200 <EMPTY> as default', () async {
      server.get("/nothing");

      final response = await client.get("https://example.com/nothing");

      expect(response.statusCode, 200);
      expect(response.body, isEmpty);
      expect(response.headers, isEmpty);
    });

    test('allows to create a very simple get mock', () async {
      server.get("/messages/17", code: 404);

      final response = await client.get("https://example.com/messages/17");

      expect(response.statusCode, 404);
      expect(response.body, isEmpty);
      expect(response.headers, isEmpty);
    });
  });
}
