import 'dart:convert';
import 'package:fittrack_flutter/services/auth_service.dart';
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';

class WorkoutService {
  final AuthService _authService = AuthService();
  final HttpOperations _http = HttpOperations();

  Future<List<dynamic>> getMySessions() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return [];
      
      final response = await _http.getRequest('user-workouts/my-sessions', token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(HttpOperations.decodeBody(response));
        return data['sessions'] as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching workouts: $e");
      return [];
    }
  }

  Future<bool> createSession(Map<String, dynamic> sessionData) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return false;
      
      final response = await _http.postRequest('user-workouts/create', sessionData, token: token);
      if (response.statusCode == 201) return true;
      return false;
    } catch (e) {
       print("Error creating session: $e");
       return false;
    }
  }
}
