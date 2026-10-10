import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../login_controller.dart';

/// Campos de email y contraseña del login. Solo leen/escriben el [LoginController].
class LoginFields extends StatelessWidget {
  const LoginFields({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final LoginController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          validator: controller.validarEmail,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: controller.passwordController,
          obscureText: controller.obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: controller.validarPassword,
          onFieldSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              tooltip: controller.obscurePassword
                  ? 'Mostrar contraseña'
                  : 'Ocultar contraseña',
              icon: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: controller.obscurePassword
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: const Icon(Icons.visibility_outlined),
                secondChild: const Icon(Icons.visibility_off_outlined),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.toggleObscurePassword();
              },
            ),
          ),
        ),
      ],
    );
  }
}
