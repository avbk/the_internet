part of "../the_internet.dart";

const _kDefaultCode = 200;
const _kDefaultBody = "";
const _kDefaultHeaders = <String, String>{};

/// [TheInternet] replaces the real internet with a local mocked and controlled
/// version.
///
/// Use [mockServer] to create a [MockedServer], which then can be configured:
/// ```dart
///   TheInternet internet = TheInternet();
///   MockedServer backend = internet.mockServer("https://backend.com/api");
///   backend.get("/task/{id}", code: 404, body: {"error: "Unknown Task"});
/// ```
///
/// [TheInternet] supports mocking the real internet for [http] as well as
/// for [dio]
///   * Use [createHttpClient] for [http] to create a [BaseClient] that only
///   communicates with [TheInternet].
///   * Use [createDioAdapter] for [dio] to create a [HttpClientAdapter] that
///   only communicates with [TheInternet]
///
/// ```dart
/// BaseClient client = internet.createHttpClient();
/// Response response = await client.get("/task/14");
///
/// expect(response.statusCode, 404);
/// ```
class TheInternet {
  final Map<String, MockedServer> _servers;

  /// Creates an instance of [TheInternet]
  ///
  /// Usually only one instance is needed, but it is possible to have multiple
  /// [TheInternet]s at the same time. Note that dio/http clients created in one
  /// won't be able to access [MockedServer]s of other [TheInternet]
  /// instances.
  TheInternet() : _servers = {};

  /// Creates a mocked version of the [BaseClient] that only
  /// communicates with [TheInternet].
  http.BaseClient createHttpClient() => MockClient(_handleHttpRequest);

  /// Creates a mocked version of the [HttpClientAdapter] that only
  /// communicates with [TheInternet].
  ///
  /// This adapter needs to be assigned to the [HttpClientAdapter] Property of
  /// the [Dio] instance.
  dio.HttpClientAdapter createDioAdapter() => _MockDioAdapter(this);

  /// Returns a [MockedServer] for a given baseUrl.
  ///
  /// If there already exists a server fo the given baseUrl, the
  /// existing [MockedServer] is returned.
  MockedServer mockServer(String baseUrl) {
    if (!_servers.containsKey(baseUrl)) {
      _servers[baseUrl] = MockedServer._(baseUrl);
    }
    return _servers[baseUrl]!;
  }

  /// Get a human readable summary about all the [MockedServer]s and the
  /// installed handlers.
  String get humanReadableMatchers {
    String message = "";
    for (var server in _servers.values) {
      message += "${server._host}\n";
      for (var methodAndPath in server._handlers.keys) {
        message += "\t${methodAndPath}\n";
      }
    }
    return message;
  }

  /// Resets [TheInternet].
  ///
  /// It will also reset all the registered [MockedServer]s before dropping
  /// them afterwards.
  void reset() {
    for (var server in _servers.values) {
      server.reset();
    }
    _servers.clear();
  }

  Future<http.Response> _handleHttpRequest(http.Request request) async {
    final CapturedRequest req = CapturedRequest._fromHttp(request);
    final MockedResponse response = await _handleCapturedRequest(req);
    return response._toHttp();
  }

  Future<dio.ResponseBody> _handleDioRequest(dio.RequestOptions request) async {
    final CapturedRequest req = CapturedRequest._fromDio(request);
    final MockedResponse response = await _handleCapturedRequest(req);
    return response._toDio();
  }

  Future<MockedResponse> _handleCapturedRequest(CapturedRequest request) async {
    for (var server in _servers.values) {
      final MockedResponse? response = await server._tryHandle(request);
      if (response != null) {
        return response;
      }
    }

    throw EndOfTheInternetError(this, request);
  }
}

/// This Error is thrown whenever a request is received which cannot be
/// handled by [TheInternet].
///
/// The [CapturedRequest] and [TheInternet] are provided with this error
/// for further investigation.
class EndOfTheInternetError implements Exception {
  final TheInternet internet;
  final CapturedRequest request;

  EndOfTheInternetError(this.internet, this.request);

  String get message => """
Could not find a handler for: ${request.method} ${request.uri}

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
      Stream<Uint8List>? requestStream, Future? cancelFuture) {
    return _internet._handleDioRequest(options);
  }

  @override
  void close({bool force = false}) {}
}
