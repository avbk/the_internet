part of "../the_internet.dart";

const _kDefaultCode = 200;
const _kDefaultBody = "";
const _kDefaultHeaders = <String, String>{};

class TheInternet {
  final Map<String, MockedServer> _servers;

  TheInternet() : _servers = {};

  http.BaseClient createHttpClient() => MockClient(_handleHttpRequest);

  dio.HttpClientAdapter createDioAdapter() => _MockDioAdapter(this);

  MockedServer mockServer(String baseUrl) {
    _servers[baseUrl] = MockedServer._(baseUrl);
    return _servers[baseUrl];
  }

  Future<http.Response> _handleHttpRequest(http.Request request) async {
    final CapturedRequest req = CapturedRequest.fromHttp(request);
    final MockedResponse response = await _handleCapturedRequest(req);
    return response?.toHttp();
  }

  Future<dio.ResponseBody> _handleDioRequest(dio.RequestOptions request) async {
    final CapturedRequest req = CapturedRequest.fromDio(request);
    final MockedResponse response = await _handleCapturedRequest(req);
    return response?.toDio();
  }

  Future<MockedResponse> _handleCapturedRequest(CapturedRequest request) async {
    for (var server in _servers.values) {
      final MockedResponse response = server._tryHandle(request);
      if (response != null) {
        return response;
      }
    }

    throw EndOfTheInternetError(this, request);
  }

  String get humanReadableMatchers {
    String message = "";
    for (var server in _servers.values) {
      message += "${server._baseUrl}\n";
      for (var methodAndPath in server._handlers.keys) {
        message += "\t${methodAndPath}\n";
      }
    }
    return message;
  }

  void reset() {
    for (var server in _servers.values) {
      server.reset();
    }
    _servers.clear();
  }
}

class EndOfTheInternetError implements Exception {
  final TheInternet internet;
  final CapturedRequest request;

  EndOfTheInternetError(this.internet, this.request);

  String get message => """
Could not find a handler for: ${request.method} ${request.url}

Installed handlers:
${internet.humanReadableMatchers}
""";

  @override
  String toString() {
    return "EndOfTheInternetError: $message";
  }
}

class _MockDioAdapter extends dio.HttpClientAdapter {
  final TheInternet _internet;

  _MockDioAdapter(this._internet);

  @override
  Future<dio.ResponseBody> fetch(dio.RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) {
    return _internet._handleDioRequest(options);
  }

  @override
  void close({bool force = false}) {}
}
