part of "../the_internet.dart";

class MockedServer {
  final String _baseUrl;
  final Map<String, _CallHandler> _handlers;
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
  }) {
    ResponseBuilder builder = _chooseBuilder(response, body, code, headers);

    _handlers["GET $pathRegex"] =
        _CallHandler("GET", _baseUrl, pathRegex, builder);
  }

  void post(
    String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
  }) {
    ResponseBuilder builder = _chooseBuilder(response, body, code, headers);

    _handlers["POST $pathRegex"] =
        _CallHandler("POST", _baseUrl, pathRegex, builder);
  }

  void put(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
  }) {
    ResponseBuilder builder = _chooseBuilder(response, body, code, headers);

    _handlers["PUT $pathRegex"] =
        _CallHandler("PUT", _baseUrl, pathRegex, builder);
  }

  void patch(
    String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
  }) {
    ResponseBuilder builder = _chooseBuilder(response, body, code, headers);

    _handlers["PATCH $pathRegex"] =
        _CallHandler("PATCH", _baseUrl, pathRegex, builder);
  }

  ResponseBuilder _chooseBuilder(
      ResponseBuilder response, body, int code, Map<String, String> headers) {
    ResponseBuilder builder;
    if (response != null) {
      builder = response;
    } else {
      if (body is String) {
        builder = (request, args) => MockedResponse(
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
        builder = (request, args) => MockedResponse(code);
      }
    }
    return builder;
  }

  MockedResponse _tryHandle(CapturedRequest request) {
    for (var handler in _handlers.values) {
      final MockedResponse response = handler._tryHandle(request);
      if (response != null) {
        _callQueue.add(CapturedCall(request, response));
        return response;
      }
    }

    return null;
  }

  CapturedCall nextCapturedCall() {
    return _callQueue.removeLast();
  }
}
