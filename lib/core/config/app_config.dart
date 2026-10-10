import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración de entorno. La URL del backend se fija al compilar:
///
///   flutter run --dart-define=API_URL=http://192.168.1.50:8000   (celular real en la misma red)
///   flutter build apk --dart-define=API_URL=https://api.uubr.org.bo   (producción, HTTPS)
///
/// Sin `API_URL`, se usa el valor por defecto del emulador / escritorio.
class AppConfig {
  AppConfig._();

  static const String _apiUrlDefinida = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_apiUrlDefinida.isNotEmpty) return _apiUrlDefinida;
    // El emulador de Android no ve "localhost" del host: usa el alias 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
}
