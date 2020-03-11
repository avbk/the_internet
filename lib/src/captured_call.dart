part of "../the_internet.dart";

class CapturedCall {
  final CapturedRequest request;
  final MockedResponse response;

  CapturedCall(this.request, this.response);
}

class CapturedRequest {
  final Map<String, String> headers;
  final CapturedBody body;
  final String method;
  final Uri uri;

  Map<String, String> args;

  CapturedRequest.fromHttp(http.Request request)
      : this.headers = request.headers,
        this.method = request.method,
        this.uri = request.url,
        this.body = CapturedBody.fromHttp(request);

  CapturedRequest.fromDio(dio.RequestOptions request)
      : this.headers = _convertHeaders(request.headers),
        this.method = request.method,
        this.uri = request.uri,
        this.body = CapturedBody.fromDio(request);

  static Map<String, String> _convertHeaders(Map<String, dynamic> headers) =>
      headers == null
          ? {}
          : Map.fromEntries(
              headers.entries.map((entry) => MapEntry<String, String>(
                    entry.key,
                    entry.value.toString(),
                  )),
            );
}

class CapturedBody {
  final dynamic asString;
  final Map<String, String> asFormData;
  final dynamic asJson;

  CapturedBody._(this.asString, this.asFormData, this.asJson);

  factory CapturedBody.fromHttp(http.Request request) {
    if (request.contentLength == 0) {
      return null;
    } else {
      String body = request.body;

      Map<String, String> formData;
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

  factory CapturedBody.fromDio(dio.RequestOptions request) {
    if (request.data is String) {
      return CapturedBody._(request.data, null, null);
    } else if (request.data is dio.FormData) {
      final formData = request.data as dio.FormData;

      return CapturedBody._(
          formData.fields.map((e) => "${e.key}=${e.value}").join("&"),
          Map.fromEntries(formData.fields),
          null);
    } else if (request.data != null) {
      return CapturedBody._(jsonEncode(request.data), null, request.data);
    } else
      return null;
  }
}

class MockedResponse {
  final int code;
  final String body;
  final Map<String, String> headers;

  MockedResponse(
    int code, {
    String body = _kDefaultBody,
    Map<String, String> headers = _kDefaultHeaders,
  })  : this.code = code ?? _kDefaultCode,
        this.headers = headers ?? _kDefaultHeaders,
        this.body = body ?? _kDefaultBody;

  MockedResponse.fromJson(
    dynamic json, {
    int code,
    Map<String, String> headers,
  }) : this(
          code,
          body: jsonEncode(json),
    headers: Map.of(headers ?? _kDefaultHeaders)
      ..addAll({"Content-Type": "application/json"}),
        );

  http.Response toHttp() => http.Response(body, code, headers: headers);

  dio.ResponseBody toDio() =>
      dio.ResponseBody.fromString(body, code, headers: _toDio(headers));

  Map<String, List<String>> _toDio(Map<String, String> headers) =>
      headers == null
          ? null
          : headers.map((key, value) => MapEntry(key.toLowerCase(), [value]));
}
