part of "../the_internet.dart";

/// A call captured by [TheInternet].
///
/// Every request is logged with its corresponding mocked response for later
/// verification.
class CapturedCall {
  /// The request, which has been received by [TheInternet] and was handled by
  /// an installed handler.
  final CapturedRequest request;

  /// The response, which has been created by an installed handler.
  final MockedResponse response;

  CapturedCall._(this.request, this.response);
}

/// A captured request.
///
/// The request, which has been captured by [TheInternet].
class CapturedRequest {
  /// The captured headers, may be empty.
  ///
  /// _Note: the fact that Dio supports  multiple values per header
  /// has not been targeted._
  final Map<String, String> headers;

  /// The captured body or null if no body was provided (e.g. a GET request)
  final CapturedBody? body;

  /// The http verb of the captured request, always uppercase
  final String method;

  /// The full uri of the captured request
  final Uri uri;

  /// All uri arguments captured while parsing the uri.
  ///
  /// The framework uses [UriParser] to match uris. If an uri matches the
  /// template of a handler, any argument in the uri is added to this map.
  ///
  /// See
  /// [pub.dev/packages/uri#uriparser](https://pub.dev/packages/uri#uriparser)
  /// for more info.
  Map<String, String> args;

  CapturedRequest._fromHttp(http.Request request)
      : this.headers = request.headers,
        this.method = request.method.toUpperCase(),
        this.uri = request.url,
        this.body = CapturedBody._fromHttp(request),
        this.args = {};

  CapturedRequest._fromDio(dio.RequestOptions request)
      : this.headers = _convertHeaders(request.headers),
        this.method = request.method.toUpperCase(),
        this.uri = request.uri,
        this.body = CapturedBody._fromDio(request),
        this.args = {};

  static Map<String, String> _convertHeaders(Map<String, dynamic> headers) =>
      headers.map((key, value) => MapEntry(
            key,
            value.toString(),
          ));
}

/// A captured body.
///
/// The body, which has been captured by [TheInternet].
class CapturedBody {
  /// The raw body as [String]
  final String asString;

  /// The data in FormData format, if the client sent form-data, otherwise null
  final Map<String, String>? asFormData;

  /// The data decoded from JSON, if the client sent JSON, otherwise null
  final dynamic asJson;

  CapturedBody._(this.asString, this.asFormData, this.asJson);

  static CapturedBody? _fromHttp(http.Request request) {
    if (request.contentLength == 0) {
      return null;
    } else {
      String body = request.body;

      Map<String, String>? formData;
      try {
        formData = request.bodyFields;
      } catch (ignored) {}

      dynamic json;
      try {
        json = jsonDecode(body);
      } catch (ignored) {}

      return CapturedBody._(body, formData, json);
    }
  }

  static CapturedBody? _fromDio(dio.RequestOptions request) {
    if (request.data is String) {
      return CapturedBody._(request.data, null, null);
    } else if (request.data is dio.FormData) {
      final formData = request.data as dio.FormData;

      return CapturedBody._(
          dio.Transformer.urlEncodeMap(Map.fromEntries(formData.fields)),
          Map.fromEntries(formData.fields),
          null);
    } else if (request.data != null) {
      return CapturedBody._(jsonEncode(request.data), null, request.data);
    } else {
      return null;
    }
  }
}

/// A captured request.
///
/// The request, which has been captured by [TheInternet].
class MockedResponse {
  /// The status code to be delivered to the client, defaults to `200`
  final int code;

  /// The body to be delivered to the client, defaults to `""`
  final String body;

  /// The headers to be delivered to the client, defaults to `{}`
  final Map<String, String> headers;

  /// Constructs an arbitrary mocked response.
  MockedResponse(
    int code, {
    String body = _kDefaultBody,
    Map<String, String> headers = _kDefaultHeaders,
  })  : this.code = code,
        this.headers = headers,
        this.body = body;

  /// Constructs a mocked JSON response.
  ///
  /// This means that the body is encoded as json and the headers are
  /// extended by `Content-Type: application/json`
  MockedResponse.fromJson(
    dynamic json, {
    int code = _kDefaultCode,
    Map<String, String> headers = _kDefaultHeaders,
  }) : this(
          code,
          body: jsonEncode(json),
          headers: Map.of(headers)
            ..addAll({"Content-Type": "application/json"}),
        );

  http.Response _toHttp() => http.Response(body, code, headers: headers);

  dio.ResponseBody _toDio() =>
      dio.ResponseBody.fromString(body, code, headers: _toDioHeaders(headers));

  Map<String, List<String>> _toDioHeaders(Map<String, String> headers) =>
      headers.map((key, value) => MapEntry(
            key.toLowerCase(),
            [value],
          ));
}
