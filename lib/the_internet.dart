/// A library to easily create and configure a MockHttpClient
///
/// Use [TheInternet] to create and configure a MockHttpClient.
library the_internet;

import "dart:convert";

import "package:dio/dio.dart" as dio;
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:uri/uri.dart";

part "src/call_handler.dart";
part "src/captured_call.dart";
part "src/mocked_server.dart";
part "src/the_internet.dart";
