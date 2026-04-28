import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin HTTP wrapper: JSON headers, UTF-8, and consistent error handling.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.baseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query), headers: _jsonHeaders());
    return _decodeObject(res);
  }

  /// Use when the backend may return a JSON array at the root (e.g. `[{...}]`).
  Future<dynamic> getDynamic(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query), headers: _jsonHeaders());
    final status = res.statusCode;
    if (status >= 200 && status < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    }
    final err = json['error']?.toString() ??
        json['message']?.toString() ??
        'Request failed ($status)';
    throw ApiException(err, statusCode: status);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.post(
      _uri(path),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    return _decodeObject(res);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.put(
      _uri(path),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    return _decodeObject(res);
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decodeObject(http.Response res) {
    final status = res.statusCode;
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is List<dynamic>) {
        // Some backends wrap list at root — surface as synthetic key.
        json = {'_root_list': decoded};
      }
    }

    if (status >= 200 && status < 300) {
      return json;
    }

    final err = json['error']?.toString() ??
        json['message']?.toString() ??
        json['detail']?.toString() ??
        'Request failed ($status)';
    throw ApiException(err, statusCode: status);
  }
}
