import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Cliente minimo para probar el backend Django desde la app movil mientras
/// se van implementando las fases del PLANBACKEND. Login JWT es lo unico que
/// existe hoy en el backend (Fase 1); se ira ampliando por fase.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  final String baseUrl;

  // El emulador de Android no ve "localhost" del host, usa el alias 10.0.2.2.
  // En Chrome/Windows desktop, localhost funciona directo.
  static String get _defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, data);
    }
    return data;
  }

  // Los endpoints de administracion (roles/permisos/usuarios) son del
  // cliente WEB (Administrador/Oficial de Mando), no del movil (ver
  // CLAUDE.md: "Alcance" - Inspector -> movil). No agregar aqui.
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}
