import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

import 'test_utils.dart';

void main() {
  httpClientTestGroup((test) {
    test("GET and POST do not collide", (server, client) async {
      server.post("/messages", code: 204);
      server.get("/messages", body: ["Hello"]);

      final getResponse = await client.get("https://example.com/messages");
      final postResponse = await client.post(
        "https://example.com/messages",
        body: {"title": "Hello"},
      );

      expect(getResponse.statusCode, 200);
      expect(getResponse.body, '["Hello"]');
      expect(getResponse.headers["Content-Type"], "application/json");

      expect(postResponse.statusCode, 204);
      expect(postResponse.body, isEmpty);
      expect(postResponse.headers, isEmpty);
    });

    test("GET something unknown throws error", (server, client) async {
      server.get("/messages", body: ["Hello"]);

      expect(
        () async => await client.get("https://example.com/unknown"),
        throwsA(isA<EndOfTheInternetError>()),
      );
    });

    test("handlers can be limited", (server, client) async {
      server.get("/messages", times: 1);

      final response = await client.get("https://example.com/messages");
      expect(response.statusCode, 200);
      expect(
            () async => await client.get("https://example.com/messages"),
        throwsA(isA<EndOfTheInternetError>()),
      );
    });

    test("handlers can be queued", (server, client) async {
      server.get("/messages", times: 1);
      server.get("/messages", code: 404, times: 1);

      final response1 = await client.get("https://example.com/messages");
      expect(response1.statusCode, 200);
      final response2 = await client.get("https://example.com/messages");
      expect(response2.statusCode, 404);
      expect(
        () async => await client.get("https://example.com/messages"),
        throwsA(isA<EndOfTheInternetError>()),
      );
    });

    test("the last handler can be infinite", (server, client) async {
      server.get("/messages", times: 1);
      server.get("/messages", code: 404);

      final response1 = await client.get("https://example.com/messages");
      expect(response1.statusCode, 200);
      final response2 = await client.get("https://example.com/messages");
      expect(response2.statusCode, 404);
      final response3 = await client.get("https://example.com/messages");
      expect(response3.statusCode, 404);
    });

    test("there can only be one infinte handler", (server, client) async {
      server.get("/messages");

      expect(
        () => server.get("/messages", code: 404),
        throwsA(isA<StateError>()),
      );
    });

    test("a server can be reset", (server, client) async {
      server.get("/messages");
      await client.get("https://example.com/messages");
      server.reset();

      expect(
        () => server.nextCapturedCall(),
        throwsA(isA<StateError>()),
      );
      expect(
        () async => await client.get("https://example.com/messages"),
        throwsA(isA<EndOfTheInternetError>()),
      );
    });
    test("complex path", (server, client) async {
      server.get("/messages/{id}/tags/{tag}/search{?query,sort}");
      await client.get(
          "https://example.com/messages/17/tags/news/search?query=foo&sort=asc");

      var call = server.nextCapturedCall();
      expect(call.request.args, {
        "id": "17",
        "tag": "news",
        "query": "foo",
        "sort": "asc",
      });
    });

    test("the whole internet can be reset", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com");
      BaseClient client = internet.createHttpClient();

      server.get("/messages");
      await client.get("https://example.com/messages");
      internet.reset();

      expect(
        () => server.nextCapturedCall(),
        throwsA(isA<StateError>()),
      );
      expect(
        () async => await client.get("https://example.com/messages"),
        throwsA(isA<EndOfTheInternetError>()),
      );
    });

    test("two different servers work for the same path", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server1 = internet.mockServer("https://example.com");
      MockedServer server2 = internet.mockServer("https://foobar.com");
      BaseClient client = internet.createHttpClient();

      server1.get("/messages", body: []);
      server2.get("/messages", code: 404);

      final response1 = await client.get("https://example.com/messages");
      final response2 = await client.get("https://foobar.com/messages");

      expect(response1.statusCode, 200);
      expect(response1.body, "[]");
      expect(response2.statusCode, 404);
    });

    test("next captured calls works in the same order as the calls are made",
        (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com");
      BaseClient client = internet.createHttpClient();

      server.get("/messages/{test}");

      await client.get("https://example.com/messages/a");
      await client.get("https://example.com/messages/b");

      expect(server.nextCapturedCall().request.args, {"test": "a"});
      expect(server.nextCapturedCall().request.args, {"test": "b"});
    });

    test("captured calls can be omitted", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com");
      BaseClient client = internet.createHttpClient();

      server.get("/messages/{test}");

      await client.get("https://example.com/messages/a");
      await client.get("https://example.com/messages/b");
      await client.get("https://example.com/messages/c");

      server.omitCapturedCall(count: 2);
      expect(server.nextCapturedCall().request.args, {"test": "c"});
    });
  });
}
