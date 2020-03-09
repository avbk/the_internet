part of "../the_internet.dart";

typedef ResponseBuilder = MockedResponse Function(
  CapturedRequest request,
  List<String> args,
);
typedef SimpleJsonResponseBuilder = dynamic Function(List<String> args);
typedef ComplexJsonResponseBuilder = dynamic Function(
  CapturedRequest request,
  List<String> args,
);

class _CallHandler {
  final String method;
  final RegExp _regex;
  final ResponseBuilder _buildResponse;
  int times;

  _CallHandler(
    this.method,
    String baseUrl,
    String pathRegex,
    this._buildResponse,
    this.times,
  ) : this._regex = RegExp("$baseUrl$pathRegex");

  MockedResponse _tryHandle(CapturedRequest request) {
    if (times == null || times > 0) {
      if (request.method.toUpperCase() == method.toUpperCase()) {
        final match = _regex.firstMatch(request.url);
        if (match != null) {
          final args = List.generate(
            match.groupCount,
            // +1, because 0 is the complete pattern
            (index) => match.group(index + 1),
          );
          if (times != null) {
            times--;
          }
          return _buildResponse(request, args);
        }
      }
    }

    return null;
  }
}
