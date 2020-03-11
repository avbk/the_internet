part of "../the_internet.dart";

typedef BodyBuilder = dynamic Function(
  CapturedRequest request,
);

typedef ResponseBuilder = MockedResponse Function(
  CapturedRequest request,
);

typedef SimpleJsonResponseBuilder = dynamic Function(List<String> args);
typedef ComplexJsonResponseBuilder = dynamic Function(
  CapturedRequest request,
  List<String> args,
);

class _CallHandler {
  final String method;
  final UriParser _pathParser;
  final ResponseBuilder _buildResponse;
  int times;

  _CallHandler(this.method,
      String pathTemplate,
      this._buildResponse,
      this.times,) :this._pathParser = UriParser(UriTemplate("$pathTemplate"));

  MockedResponse _tryHandle(CapturedRequest request) {
    if (times == null || times > 0) {
      if (request.method.toUpperCase() == method.toUpperCase()) {
        if (_pathParser.matches(request.uri)) {
          try {
            request.args = _pathParser.parse(request.uri);

            if (times != null) {
              times--;
            }
            return _buildResponse(request);
          } on ParseException catch (_) {}
        }
      }
    }

    return null;
  }
}
