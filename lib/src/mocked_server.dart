part of "../the_internet.dart";

class MockedServer {
  final String _baseUrl;
  final Map<String, List<_CallHandler>> _handlers;
  final List<CapturedCall> _callQueue;

  MockedServer._(this._baseUrl)
      : _handlers = {},
        _callQueue = [];

  void get(
    String pathTemplate, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "GET",
        pathTemplate,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void post(String pathTemplate, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "POST",
        pathTemplate,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void put(String pathTemplate, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "PUT",
        pathTemplate,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void patch(String pathTemplate, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "PATCH",
        pathTemplate,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void delete(String pathTemplate, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "DELETE",
        pathTemplate,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void head(String pathTemplate, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "HEAD",
        pathTemplate,
        times,
        _chooseBuilder(response, body, code, headers),
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
              "There can only be one infinite handler. Did you forget to specify the times before argument?");
      }
    }

    _handlers[key].add(
      _CallHandler(method, pathTemplate, builder, times),
    );
  }

  ResponseBuilder _chooseBuilder(ResponseBuilder response, body, int code,
      Map<String, String> headers) {
    ResponseBuilder builder;
    if (response != null) {
      builder = response;
    } else {
      if (body is BodyBuilder) {
        builder = (request) => _buildResponse(code, body(request), headers);
      } else if (body != null) {
        builder = (request) => _buildResponse(code, body, headers);
      } else {
        builder = (request) => MockedResponse(code, headers: headers);
      }
    }
    return builder;
  }

  MockedResponse _buildResponse(int code, dynamic body,
      Map<String, String> headers) {
    if (body is String) {
      return MockedResponse(
        code,
        body: body,
        headers: headers,
      );
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
            _callQueue.add(CapturedCall(request, response));
            return response;
          }
        }
      }
    }

    return null;
  }

  CapturedCall nextCapturedCall() {
    if (_callQueue.isEmpty) throw StateError("Ther are no captured calls");
    return _callQueue.removeLast();
  }

  void reset() {
    _handlers.clear();
    _callQueue.clear();
  }
}
