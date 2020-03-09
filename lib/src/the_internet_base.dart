import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _kDefaultCode = 200;
const _kDefaultBody = "";
const _kDefaultHeaders = <String, String>{};

class TheInternet {
  final Map<String, MockedServer> _servers;

  TheInternet() : _servers = {};

  http.BaseClient createHttpClient() => MockClient(_handleHttpRequest);

  dio.HttpClientAdapter createDioAdapter() => _MockDioAdapter(this);

  MockedServer mockServer(String baseUrl) {
    _servers[baseUrl] = MockedServer._(baseUrl);
    return _servers[baseUrl];
  }

  Future<http.Response> _handleHttpRequest(http.Request request) async {
    final CapturedRequest req = CapturedRequest.fromHttp(request);
    final MockedResponse response = await _handleCapturedRequest(req);
    return response?.toHttp();
  }

  Future<dio.ResponseBody> _handleDioRequest(dio.RequestOptions request) async {
    final CapturedRequest req = CapturedRequest.fromDio(request);
    final MockedResponse response = await _handleCapturedRequest(req);
    return response?.toDio();
  }

  Future<MockedResponse> _handleCapturedRequest(CapturedRequest request) async {
    for (var server in _servers.values) {
      final MockedResponse response = server._tryHandle(request);
      if (response != null) {
        return response;
      }
    }

    return null;
  }
}

class _MockDioAdapter extends dio.HttpClientAdapter {
  final TheInternet _internet;

  _MockDioAdapter(this._internet);

  @override
  Future<dio.ResponseBody> fetch(dio.RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) {
    return _internet._handleDioRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

typedef ResponseBuilder = MockedResponse Function(
  CapturedRequest request,
  List<String> args,
);
typedef SimpleJsonResponseBuilder = dynamic Function(List<String> args);
typedef ComplexJsonResponseBuilder = dynamic Function(
  CapturedRequest request,
  List<String> args,
);

class MockedServer {
  final String _baseUrl;
  final Map<String, _CallHandler> _handlers;
  final List<CapturedCall> _callQueue;

  MockedServer._(this._baseUrl)
      : _handlers = {},
        _callQueue = [];

  void post(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
  }) {
    ResponseBuilder builder = _chooseBuilder(response, body, code, headers);

    _handlers["POST $pathRegex"] =
        _CallHandler("POST", _baseUrl, pathRegex, builder);
  }

  void get(String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
  }) {
    ResponseBuilder builder = _chooseBuilder(response, body, code, headers);

    _handlers["GET $pathRegex"] =
        _CallHandler("GET", _baseUrl, pathRegex, builder);
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
        builder = (request, args) =>
            MockedResponse.fromJson(
              body(args),
              code: code,
              headers: headers,
            );
      } else if (body is ComplexJsonResponseBuilder) {
        builder = (request, args) =>
            MockedResponse.fromJson(
              body(request, args),
              code: code,
              headers: headers,
            );
      } else if (body != null) {
        builder = (request, args) =>
            MockedResponse.fromJson(
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

class _CallHandler {
  final String method;
  final RegExp _regex;
  final ResponseBuilder _buildResponse;

  _CallHandler(this.method,
      String baseUrl,
      String pathRegex,
      this._buildResponse,) : this._regex = RegExp("$baseUrl$pathRegex");

  MockedResponse _tryHandle(CapturedRequest request) {
    if (request.method.toUpperCase() == method.toUpperCase()) {
      final match = _regex.firstMatch(request.url);
      if (match != null) {
        final args = List.generate(
          match.groupCount,
          // +1, because 0 is the complete pattern
              (index) => match.group(index + 1),
        );
        return _buildResponse(request, args);
      }
    }

    return null;
  }
}

class CapturedCall {
  final CapturedRequest request;
  final MockedResponse response;

  CapturedCall(this.request, this.response);
}

class CapturedRequest {
  final Map<String, String> headers;
  final CapturedBody body;
  final String method;
  final String url;

  CapturedRequest.fromHttp(http.Request request)
      : this.headers = request.headers,
        this.method = request.method,
        this.url = request.url.toString(),
        this.body = CapturedBody.fromHttp(request);

  CapturedRequest.fromDio(dio.RequestOptions request)
      : this.headers = _convertHeaders(request.headers),
        this.method = request.method,
        this.url = request.uri.toString(),
        this.body = null;

  static Map<String, String> _convertHeaders(Map<String, dynamic> headers) {
    if (headers == null) {
      return {};
    } else {
      return Map.fromEntries(
        headers.entries.map((entry) =>
            MapEntry<String, String>(
              entry.key,
              entry.value.toString(),
            )),
      );
    }
  }
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
}

class MockedResponse {
  final int code;
  final String body;
  final Map<String, String> headers;

  MockedResponse(this.code, {
    this.body = _kDefaultBody,
    this.headers = _kDefaultHeaders,
  });

  MockedResponse.fromJson(dynamic json, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
  }) : this(
    code,
    body: jsonEncode(json),
    headers: Map.of(headers)
      ..addAll({"Content-Type": "application/json"}),
  );

  http.Response toHttp() => http.Response(body, code, headers: headers);

  dio.ResponseBody toDio() =>
      dio.ResponseBody.fromString(
        body,
        code,
      );
}
