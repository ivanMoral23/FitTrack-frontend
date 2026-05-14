import 'dart:convert';
import 'package:fittrack_flutter/services/auth_service.dart';
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';

class RoutineService {
  final AuthService _authService = AuthService();
  final HttpOperations _http = HttpOperations();

  Future<bool> createRoutine(Map<String, dynamic> routineData) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return false;
      
      final response = await _http.postRequest('routines/create', routineData, token: token);
      if (response.statusCode == 201) return true;
      return false;
    } catch (e) {
       print("Error creating routine: $e");
       return false;
    }
  }

  Future<List<dynamic>> getMyRoutines() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return [];
      
      final response = await _http.getRequest('routines/my-routines', token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(HttpOperations.decodeBody(response));
        return data['routines'] as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching routines: $e");
      return [];
    }
  }

  Future<List<dynamic>> getRecommendations() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return [];
      
      final response = await _http.getRequest('routines/recommendations', token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(HttpOperations.decodeBody(response));
        return data['routines'] as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
      return [];
    }
  }

  Future<bool> deleteRoutine(String routineId) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return false;
      final response = await _http.deleteRequest('routines/$routineId', token: token);
      if (response.statusCode != 200) {
        print("Error deleteRoutine [${response.statusCode}]: ${HttpOperations.decodeBody(response)}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting routine: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> generateAiRoutine(String difficulty) async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return null;
      final response = await _http.postRequest(
        'routines/generate-ai',
        {'difficulty': difficulty},
        token: token,
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(HttpOperations.decodeBody(response));
        return data['routine'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error generating AI routine: $e");
      return null;
    }
  }
}
