import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

void main() {
  test("calling mockServer twice will return same server", () {
    final internet = TheInternet();

    final a = internet.mockServer("foo");
    final b = internet.mockServer("foo");

    expect(a == b, isTrue);
  });
}
