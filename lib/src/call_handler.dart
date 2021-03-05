part of "../the_internet.dart";

class _CallHandler {
  final String method;
  final UriParser _pathParser;
  final ResponseBuilder _buildResponse;
  final Duration? delay;
  int? times;

  _CallHandler(
    this.method,
    String pathTemplate,
    this._buildResponse,
    this.times,
    this.delay,
  ) : this._pathParser = UriParser(UriTemplate("$pathTemplate"));

  Future<MockedResponse?> _tryHandle(CapturedRequest request) async {
    if (_canTick) {
      if (request.method.toUpperCase() == method.toUpperCase()) {
        if (_pathParser.matches(request.uri)) {
          try {
            request.args = _pathParser.parse(request.uri);

            _tick();
            await _throttle();

            return _buildResponse(request);
          } on ParseException catch (_) {}
        }
      }
    }

    return null;
  }

  bool get _canTick => (times ?? 1) > 0;

  void _tick() {
    final times = this.times;
    if (times != null) {
      this.times = times - 1;
    }
  }

  Future<void> _throttle() async {
    final delay = this.delay;
    if (delay != null) {
      await Future.delayed(delay);
    }
  }
}
