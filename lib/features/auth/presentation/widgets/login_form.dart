import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/loading_button.dart';
import '../login_controller.dart';
import 'login_fields.dart';
import 'shake_animation.dart';

/// Formulario de login: validación en tiempo real, botón con estado de carga y
/// sacudida cuando el backend rechaza las credenciales. Solo lee/escribe el
/// [LoginController]; no conoce el backend.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _enviar(LoginController controller) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    if (await controller.login()) {
      widget.onLoginSuccess();
    } else {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    final textos = Theme.of(context).textTheme;

    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Iniciar sesión', style: textos.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Acceso para Inspectores Técnicos',
              style: textos.bodyMedium?.copyWith(color: AppColors.grisTecnico),
            ),
            const SizedBox(height: 24),
            ShakeAnimation(
              controller: _shake,
              child: LoginFields(
                controller: controller,
                onSubmit: () => _enviar(controller),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Ingresar',
              loading: controller.isLoading,
              onPressed: () => _enviar(controller),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: controller.errorMessage == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ErrorBanner(text: controller.errorMessage!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
