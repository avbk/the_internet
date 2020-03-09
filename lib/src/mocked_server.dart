part of "../the_internet.dart";

class MockedServer {
  final String _baseUrl;
  final Map<String, List<_CallHandler>> _handlers;
  final List<CapturedCall> _callQueue;

  MockedServer._(this._baseUrl)
      : _handlers = {},
        _callQueue = [];

  void get(
    String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "GET",
        pathRegex,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void post(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "POST",
        pathRegex,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void put(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "PUT",
        pathRegex,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void patch(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "PATCH",
        pathRegex,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void delete(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "DELETE",
        pathRegex,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void head(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
    int times,
  }) =>
      _addHandler(
        "HEAD",
        pathRegex,
        times,
        _chooseBuilder(response, body, code, headers),
      );

  void _addHandler(String method, String pathRegex, int times,
      ResponseBuilder builder) {
    var key = "$method $pathRegex";
    if (!_handlers.containsKey(key)) {
      _handlers[key] = [];
    }

    _handlers[key].add(
      _CallHandler(method, _baseUrl, pathRegex, builder, times),
    );
  }

  ResponseBuilder _chooseBuilder(ResponseBuilder response, body, int code,
      Map<String, String> headers) {
    ResponseBuilder builder;
    if (response != null) {
      builder = response;
    } else {
      if (body is String) {
        builder = (request, args) =>
            MockedResponse(
              code,
              body: body,
              headers: headers,
            );
      } else if (body is SimpleJsonResponseBuilder) {
        builder = (request, args) => MockedResponse.fromJson(
              body(args),
              code: code,
              headers: headers,
            );
      } else if (body is ComplexJsonResponseBuilder) {
        builder = (request, args) => MockedResponse.fromJson(
              body(request, args),
              code: code,
              headers: headers,
            );
      } else if (body != null) {
        builder = (request, args) => MockedResponse.fromJson(
              body,
              code: code,
              headers: headers,
            );
      } else {
        builder = (request, args) => MockedResponse(code, headers: headers);
      }
    }
    return builder;
  }

  MockedResponse _tryHandle(CapturedRequest request) {
    for (var handlers in _handlers.values) {
      for (var handler in handlers) {
        final MockedResponse response = handler._tryHandle(request);
        if (response != null) {
          _callQueue.add(CapturedCall(request, response));
          return response;
        }
      }
    }

    return null;
  }

  CapturedCall nextCapturedCall() {
    return _callQueue.removeLast();
  }
}
