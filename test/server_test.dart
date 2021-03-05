import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

void main() {
  late MockedServer server;

  setUp(() {
    server = TheInternet().mockServer("foo");
  });

  test("body and bodyBuilder throws", () {
    expect(
      () => server.get("/foo", body: {}, bodyBuilder: (r) => {}),
      throwsA(isA<ArgumentError>()),
    );
  });

  test("body and responseBuilder throws", () {
    expect(
      () => server.get("/foo",
          body: {}, responseBuilder: (r) => MockedResponse(200)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test("bodyBuilder and bodyBuilder throws", () {
    expect(
      () => server.get("/foo",
          bodyBuilder: (r) => {}, responseBuilder: (r) => MockedResponse(200)),
      throwsA(isA<ArgumentError>()),
    );
  });
}
