import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

void main() {
  late TheInternet internet;
  late MockedServer server;
  late http.BaseClient httpClient;
  late dio.Dio dioClient;

  setUp(() {
    internet = TheInternet();

    // Mock a server
    server = internet.mockServer("https://demoapi.com");

    httpClient = internet.createHttpClient();
    dioClient = dio.Dio();
    dioClient.httpClientAdapter = internet.createDioAdapter();
  });

  tearDown(() {
    internet.reset();
  });

  test("create a message with http", () async {
    // Install a handler for POST /messages
    server.post("/messages", code: 204);

    // create a new message via http client
    final uri = Uri.parse("https://demoapi.com/messages");
    final response = await httpClient.post(uri, body: {"title": "Hello"});

    // verify the mocked response
    expect(response.statusCode, 204);
    expect(response.body, isEmpty);

    // verify the request captured by the handler
    final recordedCall = server.nextCapturedCall();

    expect(recordedCall.request.uri, uri);
    expect(recordedCall.request.body?.asString, "title=Hello");
    expect(recordedCall.request.body?.asFormData?["title"], "Hello");
    expect(recordedCall.request.body?.asJson, isNull);
  });

  test("get messages with dio", () async {
    // Install a handler for GET /messages
    server.get("/messages", body: [
      {"title": "Hello"},
      {"title": "World"},
      {"title": "test"},
    ]);

    // get messages via dio client
    final uri = Uri.parse("https://demoapi.com/messages");
    final response = await dioClient.get("https://demoapi.com/messages");

    // verify the mocked response
    expect(response.statusCode, 200);
    expect(response.data, [
      {"title": "Hello"},
      {"title": "World"},
      {"title": "test"},
    ]);

    // verify the request captured by the handler
    final recordedCall = server.nextCapturedCall();

    expect(recordedCall.request.uri, uri);
    expect(recordedCall.request.body, isNull);
  });

  test("build a complex response", () async {
    // Install a handler for GET /messages/{id}
    server.get("/messages/{id}", responseBuilder: (request) {
      final id = int.tryParse(request.args["id"] ?? "");
      if (id != null) {
        return MockedResponse.fromJson({
          "id": id,
          "title": "Message $id",
        });
      } else {
        return MockedResponse(404);
      }
    });

    // get a bad message via http client
    final badResponse = await httpClient.get(
      Uri.parse("https://demoapi.com/messages/not-a-number"),
    );

    // verify the mocked response
    expect(badResponse.statusCode, 404);
    expect(badResponse.body, isEmpty);

    // get a correct message via http client
    final messageResponse = await httpClient.get(
      Uri.parse("https://demoapi.com/messages/17"),
    );

    // verify the mocked response
    expect(messageResponse.statusCode, 200);
    expect(messageResponse.body, '{"id":17,"title":"Message 17"}');
  });

  test("handlers can be queued", () async {
    // Install a handler for a single GET /ping
    server.get("/ping", code: 204, times: 1);
    // Install a second handler for any subsequent GET /ping
    server.get("/ping", code: 404);

    // call /ping a couple of times
    final uri = Uri.parse("https://demoapi.com/ping");
    final response1 = await httpClient.get(uri);
    final response2 = await httpClient.get(uri);
    final response3 = await httpClient.get(uri);

    // verify the response codes
    expect(response1.statusCode, 204);
    expect(response2.statusCode, 404);
    expect(response3.statusCode, 404);
  });
}
