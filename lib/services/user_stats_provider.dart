import 'package:flutter/material.dart';
import 'package:fittrack_flutter/models/user_stats.dart';
import 'package:fittrack_flutter/services/user_stats_service.dart';

enum UserStatsStatus { initial, loading, loaded, error }

/// Provider que gestiona el ciclo de vida de [UserStats] y expone el estado
/// a la UI. Sigue el mismo patrón ChangeNotifier que el resto de la app.
class UserStatsProvider extends ChangeNotifier {
  final UserStatsService _service = UserStatsService();

  UserStatsStatus _status = UserStatsStatus.initial;
  UserStats _stats = UserStats.zero();
  String _errorMessage = '';
  bool _backendUnavailable = false;

  /// true mientras se cargan los datos de Health Connect en segundo plano.
  bool _healthLoading = false;

  UserStatsStatus get status => _status;
  UserStats get stats => _stats;
  String get errorMessage => _errorMessage;
  bool get backendUnavailable => _backendUnavailable;
  bool get healthLoading => _healthLoading;

  bool get isLoading => _status == UserStatsStatus.loading;
  bool get hasData => _status == UserStatsStatus.loaded;

  /// Muestra la pantalla inmediatamente con valores vacíos y luego carga
  /// los datos de salud en segundo plano sin bloquear la UI.
  Future<void> load() async {
    _errorMessage = '';
    _backendUnavailable = false;

    // 1. Mostrar la pantalla de inmediato con ceros.
    _status = UserStatsStatus.loaded;
    _stats = UserStats.zero();
    _healthLoading = true;
    notifyListeners();

    // 2. Cargar Health Connect en segundo plano.
    try {
      final raw = await _service.fetchStats();
      UserStats enriched;
      try {
        enriched = await _service.syncWithBackend(raw);
      } catch (_) {
        _backendUnavailable = true;
        enriched = raw;
      }
      _stats = enriched;
    } catch (e) {
      _errorMessage = e.toString();
      // La pantalla sigue mostrando ceros; no cambiamos a estado error.
    } finally {
      _healthLoading = false;
      notifyListeners();
    }
  }

  /// Recarga forzando una nueva petición.
  Future<void> refresh() => load();
}

