library global_variables;

import 'package:flutter/foundation.dart' show kIsWeb;
// El import de dart:io crashea la versión web ('flutter run -d chrome')
// import 'dart:io' show Platform;

/// URL DEL BACKEND (Producción: Máquina Virtual)
// Configuración del Servidor
// Para desarrollo local: 'http://localhost:8081' o 'http://10.0.2.2:8081' (Android Emulator)
// Para producción: La URL de tu servidor en Render/Railway
const String _prodBaseUrl = 'http://nattech.fib.upc.edu:40431';
const String _devBaseUrl = 'http://localhost:8081';

String baseUrl = _prodBaseUrl; // Cambiar a _devBaseUrl para pruebas locales


/// --- OTRAS URLs DE DESARROLLO (descomentar según necesidad) ---
// String baseUrl = 'http://localhost:3000'; // PC Local Web
// String baseUrl = 'http://192.168.0.22:3000'; // Móvil Real (IP local)
// String baseUrl = kIsWeb ? 'http://localhost:3000' : Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
