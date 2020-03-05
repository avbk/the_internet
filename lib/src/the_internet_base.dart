import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';

const _kDefaultCode = 200;
const _kDefaultBody = "";
const _kDefaultHeaders = <String, String>{};

class TheInternet {
  final Map<String, MockedServer> _servers;

  TheInternet() : _servers = {};

  BaseClient createHttpClient() => MockClient(_handleRequest);

  MockedServer mockServer(String baseUrl) {
    _servers[baseUrl] = MockedServer._(baseUrl);
    return _servers[baseUrl];
  }

  Future<Response> _handleRequest(Request request) async {
    final InternetRequest req = InternetRequest.fromHttp(request);
    for (var server in _servers.values) {
      final InternetResponse response = server._tryHandle(req);
      if (response != null) {
        return response.toHttp();
      }
    }

    return null;
  }
}

typedef ResponseBuilder = InternetResponse Function(
  InternetRequest request,
  List<String> args,
);
typedef SimpleJsonResponseBuilder = dynamic Function(List<String> args);
typedef ComplexJsonResponseBuilder = dynamic Function(
  InternetRequest request,
  List<String> args,
);

class MockedServer {
  final String _baseUrl;
  final Map<String, _CallHandler> _handlers;

  MockedServer._(this._baseUrl) : _handlers = {};

  void get(
    String pathRegex, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
    dynamic body,
    ResponseBuilder response,
  }) {
    ResponseBuilder builder;
    if (response != null) {
      builder = response;
    } else {
      if (body is String) {
        builder = (request, args) => InternetResponse(
              code,
              body: body,
              headers: headers,
            );
      } else if (body is SimpleJsonResponseBuilder) {
        builder = (request, args) => InternetResponse.fromJson(
              body(args),
              code: code,
              headers: headers,
            );
      } else if (body is ComplexJsonResponseBuilder) {
        builder = (request, args) => InternetResponse.fromJson(
              body(request, args),
              code: code,
              headers: headers,
            );
      } else if (body != null) {
        builder = (request, args) => InternetResponse.fromJson(
              body,
              code: code,
              headers: headers,
            );
      } else {
        builder = (request, args) => InternetResponse(code);
      }
    }

    _handlers[pathRegex] = _CallHandler("GET", _baseUrl, pathRegex, builder);
  }

  InternetResponse _tryHandle(InternetRequest request) {
    for (var handler in _handlers.values) {
      final InternetResponse response = handler._tryHandle(request);
      if (response != null) {
        return response;
      }
    }

    return null;
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

  InternetResponse _tryHandle(InternetRequest request) {
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

class InternetRequest {
  final Map<String, String> headers;
  final String method;
  final String url;

  InternetRequest.fromHttp(Request request)
      : this.headers = request.headers,
        this.method = request.method,
        this.url = request.url.toString();
}

class InternetResponse {
  final int code;
  final String body;
  final Map<String, String> headers;

  InternetResponse(this.code, {
    this.body = _kDefaultBody,
    this.headers = _kDefaultHeaders,
  });

  InternetResponse.fromJson(dynamic json, {
    int code: _kDefaultCode,
    Map<String, String> headers: _kDefaultHeaders,
  }) : this(
    code,
    body: jsonEncode(json),
    headers: Map.of(headers)
      ..addAll({"Content-Type": "application/json"}),
  );

  Response toHttp() => Response(body, code, headers: headers);
}
