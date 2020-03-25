part of "../the_internet.dart";

/// Callback to mock a response body.
///
/// The body returned by this function can either be:
/// * a String, which will directly used as the response body
/// * anything else will be converted to a JSON response
///
/// The provided [CapturedRequest] can be used to access path and
/// query arguments as well as headers.
typedef BodyBuilder = dynamic Function(
  CapturedRequest request,
);

/// Callback to mock an arbitrary response.
///
/// The provided [CapturedRequest] can be used to access path and
/// query arguments as well as headers.
typedef ResponseBuilder = MockedResponse Function(
  CapturedRequest request,
);

/// A [MockedServer] is a set of handlers that are used to mock a real
/// server.
///
/// Every [MockedServer] is created with a base url and can be configured
/// so that it responds to different http requests with reproducible
/// [MockedResponse]s.
class MockedServer {
  final String _baseUrl;
  final Map<String, List<_CallHandler>> _handlers;
  final List<CapturedCall> _callQueue;

  MockedServer._(this._baseUrl)
      : _handlers = {},
        _callQueue = [];

  /// Registers a new handler for a GET request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [bodyBuilder] or the
  /// [responseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [bodyBuilder], [responseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  void get(
    String pathTemplate, {
    int code,
    Map<String, String> headers,
    dynamic body,
    BodyBuilder bodyBuilder,
    ResponseBuilder responseBuilder,
    int times,
  }) =>
      _addHandler(
        "GET",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
      );

  /// Registers a new handler for a POST request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [bodyBuilder] or the
  /// [responseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [bodyBuilder], [responseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  void post(String pathTemplate, {
    int code,
    Map<String, String> headers,
    dynamic body,
    BodyBuilder bodyBuilder,
    ResponseBuilder responseBuilder,
    int times,
  }) =>
      _addHandler(
        "POST",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
      );

  /// Registers a new handler for a PUT request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [bodyBuilder] or the
  /// [responseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [bodyBuilder], [responseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  void put(String pathTemplate, {
    int code,
    Map<String, String> headers,
    dynamic body,
    BodyBuilder bodyBuilder,
    ResponseBuilder responseBuilder,
    int times,
  }) =>
      _addHandler(
        "PUT",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
      );

  /// Registers a new handler for a PATCH request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [bodyBuilder] or the
  /// [responseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [bodyBuilder], [responseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  void patch(String pathTemplate, {
    int code,
    Map<String, String> headers,
    dynamic body,
    BodyBuilder bodyBuilder,
    ResponseBuilder responseBuilder,
    int times,
  }) =>
      _addHandler(
        "PATCH",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
      );

  /// Registers a new handler for a DELETE request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [bodyBuilder] or the
  /// [responseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [bodyBuilder], [responseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  void delete(String pathTemplate, {
    int code,
    Map<String, String> headers,
    dynamic body,
    BodyBuilder bodyBuilder,
    ResponseBuilder responseBuilder,
    int times,
  }) =>
      _addHandler(
        "DELETE",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
      );

  /// Registers a new handler for a HEAD request.
  ///
  /// The [pathTemplate] supports [RFC 6570 URI Templates][http://tools.ietf.org/html/rfc6570]
  /// and any path and query arguments can be used in the [bodyBuilder] or the
  /// [responseBuilder].
  ///
  /// For simple responses it is usually enough to specify a [body], which will
  /// be used as a JSON response. Also a [code] (defaults is `200`)
  /// or [headers] (defaults to `{}`) can be specified.
  ///
  /// Only one of [bodyBuilder], [responseBuilder] or any of the static values
  /// such as [body] must be given or otherwise an [ArgumentError] will be
  /// thrown.
  ///
  /// By default this handler will respond infinitely often. But it can be
  /// restricted to respond only [times] times. After being triggered [times]
  /// times, the next handler for the same url will be executed for the
  /// following request. If there are no more handlers a [EndOfTheInternetError]
  /// will be thrown.
  void head(String pathTemplate, {
    int code,
    Map<String, String> headers,
    dynamic body,
    BodyBuilder bodyBuilder,
    ResponseBuilder responseBuilder,
    int times,
  }) =>
      _addHandler(
        "HEAD",
        pathTemplate,
        times,
        _chooseBuilder(responseBuilder, bodyBuilder, body, code, headers),
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
    if (count == null || count <= 0) {
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

  void _addHandler(
      String method, String pathTemplate, int times, ResponseBuilder builder) {
    var key = "$method $pathTemplate";
    if (!_handlers.containsKey(key)) {
      _handlers[key] = [];
    } else {
      for (var handler in _handlers[key]) {
        if (handler.times == null)
          throw StateError(
              "There can only be one infinite handler. Did you forget to specify the times argument before?");
      }
    }

    _handlers[key].add(
      _CallHandler(method, pathTemplate, builder, times),
    );
  }

  ResponseBuilder _chooseBuilder(
    ResponseBuilder responseBuilder,
    BodyBuilder bodyBuilder,
    dynamic body,
    int code,
    Map<String, String> headers,
  ) {
    final hasBodyBuilder = bodyBuilder != null;
    final hasResponseBuilder = responseBuilder != null;
    final hasStatics = body != null || code != null || headers != null;

    final hasBadArguments = [hasBodyBuilder, hasResponseBuilder, hasStatics]
            .fold(0, (sum, x) => sum + (x ? 1 : 0)) >
        1;

    if (hasBadArguments)
      throw ArgumentError(
          "You must specify only one of [responseBuilder], [bodyBuilder] or a combination of [body, code, headers]");

    if (responseBuilder != null) {
      return responseBuilder;
    } else if (bodyBuilder != null) {
      return (request) => _buildResponse(code, bodyBuilder(request), headers);
    } else {
      return (request) => _buildResponse(code, body, headers);
    }
  }

  MockedResponse _buildResponse(int code, dynamic body,
      Map<String, String> headers) {
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

  MockedResponse _tryHandle(CapturedRequest request) {
    if (request.uri.toString().startsWith(_baseUrl)) {
      for (var handlers in _handlers.values) {
        for (var handler in handlers) {
          final MockedResponse response = handler._tryHandle(request);
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
