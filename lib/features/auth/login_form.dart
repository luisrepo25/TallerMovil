import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'login_controller.dart';

/// Formulario de login: inputs con validacion en tiempo real, toggle de
/// contrasena animado, boton con estado de carga integrado y sacudida
/// (shake) cuando el backend rechaza las credenciales. Solo lee/escribe el
/// [LoginController] provisto por el widget padre; no conoce el backend.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _shakeController;
  String? _ultimoError;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(LoginController controller) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    final exito = await controller.login();

    if (exito) {
      widget.onLoginSuccess();
    } else {
      HapticFeedback.mediumImpact();
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

    // Dispara la sacudida tambien si el error cambia por otra via (defensivo).
    if (controller.errorMessage != null && controller.errorMessage != _ultimoError) {
      _ultimoError = controller.errorMessage;
    }

    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Iniciar sesion', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Acceso para Inspectores Tecnicos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grisTecnico,
                  ),
            ),
            const SizedBox(height: 24),
            _AnimacionSacudida(
              controller: _shakeController,
              child: Column(
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
                    onFieldSubmitted: (_) => _handleSubmit(controller),
                    decoration: InputDecoration(
                      labelText: 'Contrasena',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
              ),
            ),
            const SizedBox(height: 24),
            _BotonConCarga(
              cargando: controller.isLoading,
              onPressed: () => _handleSubmit(controller),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: controller.errorMessage == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _MensajeError(texto: controller.errorMessage!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boton de ancho completo cuyo contenido cambia entre texto y un indicador
/// de carga sin saltos abruptos de layout (altura fija, AnimatedSwitcher solo
/// en el contenido interno).
class _BotonConCarga extends StatelessWidget {
  const _BotonConCarga({required this.cargando, required this.onPressed});

  final bool cargando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: cargando ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: cargando
            ? const SizedBox(
                key: ValueKey('cargando'),
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : const Text('Ingresar', key: ValueKey('texto')),
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rojoSeguridad.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rojoSeguridad.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.rojoSeguridad, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: const TextStyle(color: AppColors.rojoSeguridad)),
          ),
        ],
      ),
    );
  }
}

/// Envuelve [child] y lo desplaza horizontalmente en una curva senoidal
/// amortiguada cuando [controller] corre, simulando una sacudida ligera.
class _AnimacionSacudida extends StatelessWidget {
  const _AnimacionSacudida({required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, hijo) {
        final progreso = controller.value;
        final amortiguacion = 1 - progreso;
        final desplazamiento = 8 * amortiguacion * (progreso == 0 ? 0 : _seno(progreso));
        return Transform.translate(offset: Offset(desplazamiento, 0), child: hijo);
      },
      child: child,
    );
  }

  double _seno(double t) {
    const vueltas = 4;
    return math.sin(t * vueltas * 2 * math.pi);
  }
}
