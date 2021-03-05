part of "../the_internet.dart";

/// Callback to mock a response body.
///
/// The body returned by this function can either be:
/// * a String, which will directly used as the response body
/// * anything else, which will be converted to a JSON response
///
/// The provided [CapturedRequest] can be used to access path and
/// query arguments as well as headers.
typedef BodyBuilder = FutureOr<dynamic> Function(
  CapturedRequest request,
);

/// Callback to mock an arbitrary response.
///
/// The provided [CapturedRequest] can be used to access path and
/// query arguments as well as headers.
typedef ResponseBuilder = FutureOr<MockedResponse> Function(
  CapturedRequest request,
);

/// A [MockedServer] is a set of handlers that are used to mock a real
/// server.
///
/// Every [MockedServer] is created with a base url and can be configured
/// so that it responds to different http requests with reproducible
/// [MockedResponse]s.
class MockedServer {
  final String _host;
  final String _basePath;
  final Map<String, List<_CallHandler>> _handlers;
  final List<CapturedCall> _callQueue;

  MockedServer._(String baseUrl)
      : _handlers = {},
        _callQueue = [],
        _host = _hostFromBaseUrl(baseUrl),
        _basePath = _basePathFromBaseUrl(baseUrl);

  static _hostFromBaseUrl(String baseUrl) => baseUrl.startsWith("http")
      ? Uri.parse(baseUrl).origin
      : Uri.parse("http://$baseUrl").origin;

  static _basePathFromBaseUrl(String baseUrl) => Uri.parse(baseUrl).path;

  /// Registers a new handler for a GET request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [BodyBuilder] or the
  /// [ResponseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [BodyBuilder], [ResponseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  ///
  /// The response can be delayed either by delaying within the [BodyBuilder],
  /// [ResponseBuilder] or by setting a [delay].
  void get(
    String pathTemplate, {
    int? code,
    Map<String, String>? headers,
    dynamic body,
    BodyBuilder? bodyBuilder,
    ResponseBuilder? responseBuilder,
    int? times,
    Duration? delay,
  }) =>
      _addHandler(
        "GET",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
        delay,
      );

  /// Registers a new handler for a POST request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [BodyBuilder] or the
  /// [ResponseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [BodyBuilder], [ResponseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  ///
  /// The response can be delayed either by delaying within the [BodyBuilder],
  /// [ResponseBuilder] or by setting a [delay].
  void post(
    String pathTemplate, {
    int? code,
    Map<String, String>? headers,
    dynamic body,
    BodyBuilder? bodyBuilder,
    ResponseBuilder? responseBuilder,
    int? times,
    Duration? delay,
  }) =>
      _addHandler(
        "POST",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
        delay,
      );

  /// Registers a new handler for a PUT request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [BodyBuilder] or the
  /// [ResponseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [BodyBuilder], [ResponseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  ///
  /// The response can be delayed either by delaying within the [BodyBuilder],
  /// [ResponseBuilder] or by setting a [delay].
  void put(
    String pathTemplate, {
    int? code,
    Map<String, String>? headers,
    dynamic body,
    BodyBuilder? bodyBuilder,
    ResponseBuilder? responseBuilder,
    int? times,
    Duration? delay,
  }) =>
      _addHandler(
        "PUT",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
        delay,
      );

  /// Registers a new handler for a PATCH request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [BodyBuilder] or the
  /// [ResponseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [BodyBuilder], [ResponseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  ///
  /// The response can be delayed either by delaying within the [BodyBuilder],
  /// [ResponseBuilder] or by setting a [delay].
  void patch(
    String pathTemplate, {
    int? code,
    Map<String, String>? headers,
    dynamic body,
    BodyBuilder? bodyBuilder,
    ResponseBuilder? responseBuilder,
    int? times,
    Duration? delay,
  }) =>
      _addHandler(
        "PATCH",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
        delay,
      );

  /// Registers a new handler for a DELETE request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [BodyBuilder] or the
  /// [ResponseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [BodyBuilder], [ResponseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  ///
  /// The response can be delayed either by delaying within the [BodyBuilder],
  /// [ResponseBuilder] or by setting a [delay].
  void delete(
    String pathTemplate, {
    int? code,
    Map<String, String>? headers,
    dynamic body,
    BodyBuilder? bodyBuilder,
    ResponseBuilder? responseBuilder,
    int? times,
    Duration? delay,
  }) =>
      _addHandler(
        "DELETE",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
        delay,
      );

  /// Registers a new handler for a HEAD request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [BodyBuilder] or the
  /// [ResponseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [BodyBuilder], [ResponseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  ///
  /// The response can be delayed either by delaying within the [BodyBuilder],
  /// [ResponseBuilder] or by setting a [delay].
  void head(
    String pathTemplate, {
    int? code,
    Map<String, String>? headers,
    dynamic body,
    BodyBuilder? bodyBuilder,
    ResponseBuilder? responseBuilder,
    int? times,
    Duration? delay,
  }) =>
      _addHandler(
        "HEAD",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
        delay,
      );

  /// Returns the next captured call.
  ///
  /// Every [CapturedRequest] handled by this server will be stored  with its
  /// corresponding [MockedResponse] as a [CapturedCall] in a FIFO-Queue.
  ///
  /// This mthod pops the next element from the queue or throws a
  /// [StateError] if there are no [CapturedCall]s.
  CapturedCall nextCapturedCall() {
    if (_callQueue.isEmpty) {
      throw StateError("There are no captured calls");
    }
    return _callQueue.removeAt(0);
  }

  /// Omits the next [CapturedCall] or calls.
  ///
  /// As many capturedCalls as given by the argument count are omitted.
  void omitCapturedCall({int count: 1}) {
    if (count <= 0) {
      throw ArgumentError("count must be a positive number");
    }
    for (var i = 0; i < count; i++) {
      nextCapturedCall();
    }
  }

  /// Resets the server.
  ///
  /// This method drops any previously registered handlers and clears the queue
  /// of handled requests.
  void reset() {
    _handlers.clear();
    _callQueue.clear();
  }

  /// Removes handlers for a specific url.
  ///
  /// If only [pathTemplate] is provided all handlers for every supported
  /// http method are removed. Otherwise only handlers for the given method
  /// are removed.
  void remove(String pathTemplate, {String? method}) {
    final methods = (method == null)
        ? ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]
        : [method.toUpperCase()];

    for (var m in methods) {
      var key = "$m $pathTemplate";
      _handlers.remove(key);
    }
  }

  void _addHandler(
    String method,
    String pathTemplate,
    int? times,
    ResponseBuilder builder,
    Duration? delay,
  ) {
    final key = "$method $pathTemplate";

    final List<_CallHandler> handlers = _handlers[key] ?? [];
    if (!_handlers.containsKey(key)) {
      _handlers[key] = handlers;
    } else {
      for (var handler in handlers) {
        if (handler.times == null)
          throw StateError(
              "There can only be one infinite handler. Did you forget to specify the times argument before?");
      }
    }

    handlers.add(
      _CallHandler(method, _basePath + pathTemplate, builder, times, delay),
    );
  }

  ResponseBuilder _chooseBuilder(
    ResponseBuilder? responseBuilder,
    BodyBuilder? bodyBuilder,
    dynamic body,
    int? code,
    Map<String, String>? headers,
  ) {
    final hasBodyBuilder = bodyBuilder != null;
    final hasResponseBuilder = responseBuilder != null;
    final hasStatics = body != null || code != null || headers != null;

    final hasBadArguments = [hasBodyBuilder, hasResponseBuilder, hasStatics]
            .fold(0, (dynamic sum, x) => sum + (x ? 1 : 0)) >
        1;

    if (hasBadArguments)
      throw ArgumentError(
          "You must specify only one of [responseBuilder], [bodyBuilder] or a combination of [body, code, headers]");

    if (responseBuilder != null) {
      return responseBuilder;
    } else if (bodyBuilder != null) {
      return (request) async =>
          _buildResponse(code, await bodyBuilder(request), headers);
    } else {
      return (request) => _buildResponse(code, body, headers);
    }
  }

  MockedResponse _buildResponse(
      int? code, dynamic body, Map<String, String>? headers) {
    if (body == null || body is String) {
      return MockedResponse(code, headers: headers, body: body);
    } else {
      return MockedResponse.fromJson(
        body,
        code: code,
        headers: headers,
      );
    }
  }

  Future<MockedResponse?> _tryHandle(CapturedRequest request) async {
    if (request.uri.toString().startsWith(_host)) {
      for (var handlers in _handlers.values) {
        for (var handler in handlers) {
          final MockedResponse? response = await handler._tryHandle(request);
          if (response != null) {
            _callQueue.add(CapturedCall._(request, response));
            return response;
          }
        }
      }
    }

    return null;
  }
}
