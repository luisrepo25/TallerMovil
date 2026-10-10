import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../domain/auth_failure.dart';
import 'sesion_controller.dart';

/// Lógica del formulario de login, separada de la UI (las pantallas solo leen este
/// estado y disparan [login]). La autenticación real vive en [AuthRepository].
class LoginController extends ChangeNotifier {
  LoginController({
    required AuthRepository repositorio,
    required SesionController sesion,
  }) : _repositorio = repositorio,
       _sesion = sesion;

  final AuthRepository _repositorio;
  final SesionController _sesion;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  String? validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu email';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }

  // Al iniciar sesión solo se exige que no esté vacía: las reglas de longitud
  // las aplica el backend al crear la cuenta, no al entrar.
  String? validarPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  /// Intenta autenticar. Devuelve `true` si fue exitoso, para que la UI decida cómo
  /// navegar (este controlador no navega).
  Future<bool> login() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final usuario = await _repositorio.iniciarSesion(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      _sesion.iniciar(usuario);
      return true;
    } on AuthFailure catch (falla) {
      errorMessage = falla.mensaje;
      return false;
    } catch (_) {
      errorMessage = 'No se pudo iniciar sesión. Intenta de nuevo.';
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
