part of "../the_internet.dart";

typedef BodyBuilder = dynamic Function(
  CapturedRequest request,
);

typedef ResponseBuilder = MockedResponse Function(
  CapturedRequest request,
);

class MockedServer {
  final String _baseUrl;
  final Map<String, List<_CallHandler>> _handlers;
  final List<CapturedCall> _callQueue;

  MockedServer._(this._baseUrl)
      : _handlers = {},
        _callQueue = [];

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

  void _addHandler(String method, String pathTemplate, int times,
      ResponseBuilder builder) {
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

  ResponseBuilder _chooseBuilder(ResponseBuilder responseBuilder,
      BodyBuilder bodyBuilder,
      dynamic body,
      int code,
      Map<String, String> headers,) {
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

  CapturedCall nextCapturedCall() {
    if (_callQueue.isEmpty) {
      throw StateError("There are no captured calls");
    }
    return _callQueue.removeLast();
  }

  void reset() {
    _handlers.clear();
    _callQueue.clear();
  }
}
