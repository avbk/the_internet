part of "../the_internet.dart";

class _CallHandler {
  final String method;
  final UriParser _pathParser;
  final ResponseBuilder _buildResponse;
  final Duration delay;
  int times;

  _CallHandler(
    this.method,
    String pathTemplate,
    this._buildResponse,
    this.times,
    this.delay,
  ) : this._pathParser = UriParser(UriTemplate("$pathTemplate"));

  Future<MockedResponse> _tryHandle(CapturedRequest request) async {
    if (times == null || times > 0) {
      if (request.method.toUpperCase() == method.toUpperCase()) {
        if (_pathParser.matches(request.uri)) {
          try {
            request.args = _pathParser.parse(request.uri);

            if (times != null) {
              times--;
            }

            if (delay != null) {
              await Future.delayed(delay);
            }

            return _buildResponse(request);
          } on ParseException catch (_) {}
        }
      }
    }

    return null;
  }
}
