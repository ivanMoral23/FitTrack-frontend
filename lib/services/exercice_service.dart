import 'dart:convert';
import 'package:fittrack_flutter/services/auth_service.dart';
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';
import 'package:fittrack_flutter/components/training/new_workout/add_exercice/exercice_model.dart';

class ExerciceService {
  final AuthService _authService = AuthService();
  final HttpOperations _http = HttpOperations();

  /// Crea un ejercicio personalizado para el usuario autenticado.
  /// Devuelve el [Exercice] creado, o lanza una [Exception] con el mensaje de error del servidor.
  Future<Exercice?> createCustomExercice({
    required String name,
    required String muscleGroup,
    required String difficulty,
    required String mechanics,
    required String recordType,
    String? instructions,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No hay sesión activa. Inicia sesión de nuevo.');

    final body = <String, dynamic>{
      'name': name,
      'muscle_group': muscleGroup,
      'difficulty': difficulty,
      'mechanics': mechanics,
      'recordType': recordType,
      if (instructions != null && instructions.trim().isNotEmpty)
        'instructions': [instructions.trim()],
    };

    final response = await _http.postRequest(
      'exercices/create-custom',
      body,
      token: token,
    );

    final rawBody = HttpOperations.decodeBody(response);

    if (response.statusCode == 201) {
      final data = jsonDecode(rawBody);
      return Exercice.fromJson(data['exercice']);
    }

    // Intentamos extraer el mensaje de error del servidor
    String errorMsg = 'Error al crear el ejercicio (${response.statusCode})';
    try {
      final data = jsonDecode(rawBody);
      if (data['message'] != null) errorMsg = data['message'];
    } catch (_) {}
    throw Exception(errorMsg);
  }
}
