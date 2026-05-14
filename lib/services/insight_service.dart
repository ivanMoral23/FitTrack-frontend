import 'dart:convert';
import 'package:fittrack_flutter/HTTP_operations/http_operations.dart';
import 'package:fittrack_flutter/services/auth_service.dart';

class InsightService {
  final AuthService _authService = AuthService();
  final HttpOperations _http = HttpOperations();

  Future<List<dynamic>> getInsights() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await _http.getRequest('insights', token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['insights'] ?? [];
      } else {
        throw Exception('Error fetching insights: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load insight data: $e');
    }
  }

  Future<bool> triggerManualAgent() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return false;

      final response = await _http.postRequest('insights/trigger', {}, token: token);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getMuscleRecommendation() async {
    try {
      String? token = await _authService.getToken();
      if (token == null) return null;

      final response = await _http.postRequest('insights/recommendation', {}, token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['recommendation'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
