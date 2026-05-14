import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:fittrack_flutter/globals/global_variables.dart';

class HttpOperations {
  // Decodifica el cuerpo de la respuesta siempre en UTF-8.
  // El paquete http de Dart usa latin-1 por defecto cuando el servidor no
  // incluye charset=utf-8 en el Content-Type, lo que corrompe acentos y ñ.
  static String decodeBody(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  static Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> getRequest(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.get(url, headers: _headers(token: token));
  }

  Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.post(
      url,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> deleteRequest(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.delete(url, headers: _headers(token: token));
  }

  Future<http.Response> putRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    return await http.put(
      url,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
  }
}
