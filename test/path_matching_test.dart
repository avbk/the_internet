import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

import 'test_utils.dart';

void main() {
  httpClientTestGroup((test) {
    test("GET and POST do not collide", (server, client) async {
      server.post("/messages", code: 204);
      server.get("/messages", body: ["Hello"]);

      final getResponse =
          await client.get("https://example.com/messages".asUri);
      final postResponse = await client.post(
        "https://example.com/messages".asUri,
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

      await expectNoHandler(
        () => client.get("https://example.com/unknown".asUri),
      );
    });

    test("handlers can be limited", (server, client) async {
      server.get("/messages", times: 1);

      final response = await client.get("https://example.com/messages".asUri);
      expect(response.statusCode, 200);
      await expectNoHandler(
        () => client.get("https://example.com/messages".asUri),
      );
    });

    test("handlers can be queued", (server, client) async {
      server.get("/messages", times: 1);
      server.get("/messages", code: 404, times: 1);

      final response1 = await client.get("https://example.com/messages".asUri);
      expect(response1.statusCode, 200);
      final response2 = await client.get("https://example.com/messages".asUri);
      expect(response2.statusCode, 404);
      await expectNoHandler(
        () => client.get("https://example.com/messages".asUri),
      );
    });

    test("the last handler can be infinite", (server, client) async {
      server.get("/messages", times: 1);
      server.get("/messages", code: 404);

      final response1 = await client.get("https://example.com/messages".asUri);
      expect(response1.statusCode, 200);
      final response2 = await client.get("https://example.com/messages".asUri);
      expect(response2.statusCode, 404);
      final response3 = await client.get("https://example.com/messages".asUri);
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
      await client.get("https://example.com/messages".asUri);
      server.reset();

      expect(
        () => server.nextCapturedCall(),
        throwsA(isA<StateError>()),
      );
      await expectNoHandler(
        () => client.get("https://example.com/messages".asUri),
      );
    });
    test("complex path", (server, client) async {
      server.get("/messages/{id}/tags/{tag}/search{?query,sort}");
      await client.get(
        "https://example.com/messages/17/tags/news/search?query=foo&sort=asc"
            .asUri,
      );

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
      await client.get("https://example.com/messages".asUri);
      internet.reset();

      expect(
        () => server.nextCapturedCall(),
        throwsA(isA<StateError>()),
      );
      await expectNoHandler(
        () => client.get("https://example.com/messages".asUri),
      );
    });

    test("two different servers work for the same path", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server1 = internet.mockServer("https://example.com");
      MockedServer server2 = internet.mockServer("https://foobar.com");
      BaseClient client = internet.createHttpClient();

      server1.get("/messages", body: []);
      server2.get("/messages", code: 404);

      final response1 = await client.get("https://example.com/messages".asUri);
      final response2 = await client.get("https://foobar.com/messages".asUri);

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

      await client.get("https://example.com/messages/a".asUri);
      await client.get("https://example.com/messages/b".asUri);

      expect(server.nextCapturedCall().request.args, {"test": "a"});
      expect(server.nextCapturedCall().request.args, {"test": "b"});
    });

    test("captured calls can be omitted", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com");
      BaseClient client = internet.createHttpClient();

      server.get("/messages/{test}");

      await client.get("https://example.com/messages/a".asUri);
      await client.get("https://example.com/messages/b".asUri);
      await client.get("https://example.com/messages/c".asUri);

      server.omitCapturedCall(count: 2);
      expect(server.nextCapturedCall().request.args, {"test": "c"});
    });

    test("removing all handlers for one route", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com");
      BaseClient client = internet.createHttpClient();
      server.get("/messages");
      server.post("/messages");
      server.get("/messages/v2");

      server.remove("/messages");
      await expectNoHandler(
        () => client.get("https://example.com/messages".asUri),
      );
      await expectNoHandler(
        () => client.post("https://example.com/messages".asUri),
      );

      await client.get("https://example.com/messages/v2".asUri);
      expect(server.nextCapturedCall().request.uri.path, "/messages/v2");
    });

    test("removing a single handler for one route", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com");
      BaseClient client = internet.createHttpClient();
      server.get("/messages");
      server.post("/messages");
      server.get("/messages/v2");

      server.remove("/messages", method: "POST");

      await client.get("https://example.com/messages".asUri);
      expect(server.nextCapturedCall().request.uri.path, "/messages");

      await expectNoHandler(
          () => client.post("https://example.com/messages".asUri));

      await client.get("https://example.com/messages/v2".asUri);
      expect(server.nextCapturedCall().request.uri.path, "/messages/v2");
    });

    test("replacing a call works", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com");
      BaseClient client = internet.createHttpClient();

      server.get("/messages");
      final response1 = await client.get("https://example.com/messages".asUri);

      server
        ..remove("/messages")
        ..get("/messages", code: 404);

      final response2 = await client.get("https://example.com/messages".asUri);

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 404);
    });

    test("using a basepath and not only a baseurl works", (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://example.com/foobar");
      BaseClient client = internet.createHttpClient();
      server.get("/messages");

      await client.get("https://example.com/foobar/messages".asUri);
      expect(server.nextCapturedCall().request.uri.path, "/foobar/messages");
    });
    test("using a basepath, which is also part of the host, works",
        (_, __) async {
      TheInternet internet = TheInternet();
      MockedServer server = internet.mockServer("https://foobar.com/foobar");
      BaseClient client = internet.createHttpClient();
      server.get("/messages");

      await client.get("https://foobar.com/foobar/messages".asUri);
      expect(server.nextCapturedCall().request.uri.path, "/foobar/messages");
    });
  });
}
