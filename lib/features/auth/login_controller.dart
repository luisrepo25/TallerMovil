import 'package:flutter/material.dart';

import '../../api_client.dart';

/// Logica de negocio del login, separada de la UI (login_screen/login_form
/// solo leen este estado y disparan [login]). Vive como ChangeNotifier para
/// integrarse con Provider sin el boilerplate de un BLoC completo.
class LoginController extends ChangeNotifier {
  LoginController({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;
  String? accessToken;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  String? validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu email';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Email invalido';
    return null;
  }

  String? validarPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contrasena';
    if (value.length < 6) return 'Minimo 6 caracteres';
    return null;
  }

  /// Intenta autenticar contra el backend. Retorna true si el login fue
  /// exitoso, para que la UI decida como navegar (no lo hace este controller).
  Future<bool> login() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      accessToken = data['access'] as String;
      return true;
    } catch (e) {
      errorMessage = 'Credenciales invalidas. Verifica tu email y contrasena.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
