import 'package:http/http.dart';
import 'package:http/testing.dart';

class TheInternet {
  MockClient _client;

  TheInternet() {
    _client = MockClient(_handleRequest);
  }

  Future<Response> _handleRequest(Request request) async {
    return Response("", 0);
  }

  MockClient getHttpClient() {
    return _client;
  }
}
