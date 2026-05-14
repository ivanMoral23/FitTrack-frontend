import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fittrack_flutter/globals/global_variables.dart'; // Importa la variable global baseUrl
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart'; // Importa tu clase de operaciones HTTP

class AuthService {
  // Ajusta la IP si usas un emulador de Android (10.0.2.2 en lugar de localhost)
  // Para emulador de Android: 'http://10.0.2.2:3000'
  // Para Web o iOS o Desktop: 'http://localhost:3000'
  // Backend VM UPC link
  // final String baseUrl = 'http://127.0.0.1:3000'; // Web/iOS/Desktop
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Clave usada para guardar el token
  final String _tokenKey = 'jwt_token';

  // Iniciar Sesión
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await HttpOperations().postRequest('login', {
        'username': username,
        'password': password,
      });
      final data = jsonDecode(HttpOperations.decodeBody(response));

      if (response.statusCode == 200) {
        // Guardar el token en almacenamiento seguro
        await _storage.write(key: _tokenKey, value: data['token']);
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error de autenticación',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor: $e',
      };
    }
  }

  // Registrar Usuario
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    int age,
    double height,
    double weight,
  ) async {
    try {
      final response = await HttpOperations().postRequest('register', {
        'username': username,
        'email': email,
        'password': password,
        'age': age,
        'height': height,
        'weight': weight,
      });

      final data = jsonDecode(HttpOperations.decodeBody(response));

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al registrar',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor: $e',
      };
    }
  }

  // Solicitar recuperación de contraseña
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {    try {
      final response = await HttpOperations().postRequest('auth/forgot-password', {
        'email': email,
      });

      final data = jsonDecode(HttpOperations.decodeBody(response));

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al solicitar recuperación'};
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor: $e'};
    }
  }

  // Comprobar si existe el token guardado
  Future<bool> hasToken() async {
    String? token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  // Obtener el token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Cerrar Sesión (Borrar token)
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  // Cambiar contraseña (usuario autenticado)
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No autenticado'};

      final response = await HttpOperations().putRequest(
        'auth/change-password',
        {'currentPassword': currentPassword, 'newPassword': newPassword},
        token: token,
      );

      final data = jsonDecode(HttpOperations.decodeBody(response));

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al cambiar la contraseña'};
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor: $e'};
    }
  }
}
