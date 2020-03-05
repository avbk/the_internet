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

class MockedServer {
  final String _baseUrl;
  final Map<String, _CallHandler> _handlers;

  MockedServer._(this._baseUrl) : _handlers = {};

  void get(String pathRegex, {int code: _kDefaultCode, dynamic json}) {
    _handlers[pathRegex] = _CallHandler(
      "GET",
      _baseUrl,
      pathRegex,
      (request, args) => json == null
          ? InternetResponse(code)
          : InternetResponse.fromJson(json, code: code),
    );
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

typedef _ResponseBuilder = InternetResponse Function(
    InternetRequest request,
    List<String> args,
    );

class _CallHandler {
  final String method;
  final RegExp _regex;
  final _ResponseBuilder _handler;

  _CallHandler(this.method, String baseUrl, String pathRegex, this._handler)
      : this._regex = RegExp("$baseUrl$pathRegex");

  InternetResponse _tryHandle(InternetRequest request) {
    final isSameMethod = request.method.toUpperCase() == method.toUpperCase();

    if (isSameMethod && _regex.hasMatch(request.url)) {
      return _handler(request, []);
    } else {
      return null;
    }
  }
}

class InternetRequest {
  final String method;
  final String url;

  InternetRequest.fromHttp(Request request)
      : this.method = request.method,
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

  InternetResponse.fromJson(dynamic json, {int code: _kDefaultCode})
      : this(
    code,
    body: jsonEncode(json),
    headers: {"Content-Type": "application/json"},
  );

  Response toHttp() => Response(body, code, headers: headers);
}
