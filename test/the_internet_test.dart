import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:the_internet/the_internet.dart';

void main() {
  group('The internet ', () {
    TheInternet internet;

    setUp(() {
      internet = TheInternet();
    });

    test('allows to obtain a httpcient', () {
      expect(internet.getHttpClient(), isA<MockClient>());
    });
  });
}
