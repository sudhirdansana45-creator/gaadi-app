import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() {
    if (errors is Map) {
      final messages = <String>[];
      for (final val in (errors as Map).values) {
        if (val is List && val.isNotEmpty) {
          messages.add(val.first.toString());
        } else if (val != null) {
          messages.add(val.toString());
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }
    return message;
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const String _tokenKey = 'auth_bearer_token';
  String? _cachedToken;

  static const String _userKey = 'auth_cached_user';
  Map<String, dynamic>? _cachedUser;

  /// Reactive notifier for authentication state changes (used by router)
  static final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

  /// Reactive notifier for user profile data changes
  static final ValueNotifier<Map<String, dynamic>?> userNotifier = ValueNotifier<Map<String, dynamic>?>(null);

  /// Get current cached user profile
  Map<String, dynamic>? get currentUser => _cachedUser;

  /// Load cached token and user from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      try {
        _cachedUser = jsonDecode(userStr) as Map<String, dynamic>;
        userNotifier.value = _cachedUser;
      } catch (_) {}
    }
    authStateNotifier.value = isAuthenticated;
  }

  /// Get current auth token
  String? get token => _cachedToken;

  /// Save auth token
  Future<void> setToken(String? token) async {
    _cachedToken = token;
    authStateNotifier.value = isAuthenticated;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  /// Save current user profile
  Future<void> setUser(Map<String, dynamic>? user) async {
    _cachedUser = user;
    userNotifier.value = user;
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user));
    } else {
      await prefs.remove(_userKey);
    }
  }

  /// Remove auth token upon logout
  Future<void> clearSession() async {
    await setToken(null);
    await setUser(null);
  }

  /// Check if user is logged in
  bool get isAuthenticated => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Generic GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    final response = await http.get(uri, headers: ApiConfig.headers(token: _cachedToken));
    return _processResponse(response);
  }

  /// Generic POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(endpoint);
    final response = await http.post(
      uri,
      headers: ApiConfig.headers(token: _cachedToken),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  /// Generic PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(endpoint);
    final response = await http.put(
      uri,
      headers: ApiConfig.headers(token: _cachedToken),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  /// Generic PATCH request
  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(endpoint);
    final response = await http.patch(
      uri,
      headers: ApiConfig.headers(token: _cachedToken),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  /// Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    final uri = _buildUri(endpoint);
    final response = await http.delete(uri, headers: ApiConfig.headers(token: _cachedToken));
    return _processResponse(response);
  }

  /// Multipart POST request for document/photo uploads
  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (_cachedToken != null) 'Authorization': 'Bearer $_cachedToken',
    });

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final fullUrl = '${ApiConfig.baseUrl}$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }
    return Uri.parse(fullUrl);
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Return full response map so callers can access res['data'], res['message'] etc.
      return jsonBody;
    }

    // Error handling
    final message = (jsonBody is Map<String, dynamic>)
        ? (jsonBody['message'] ?? 'Request failed with status: ${response.statusCode}')
        : 'Request failed with status: ${response.statusCode}';

    final errors = (jsonBody is Map<String, dynamic>) ? jsonBody['errors'] : null;

    if (response.statusCode == 401) {
      clearSession();
      final errorMsg = (jsonBody is Map<String, dynamic> && jsonBody['message'] != null)
          ? jsonBody['message'].toString()
          : 'Session expired. Please login again.';
      throw ApiException(errorMsg, statusCode: 401, errors: errors);
    }

    throw ApiException(message.toString(), statusCode: response.statusCode, errors: errors);
  }
}
