import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/transitions/page_transitions.dart';
import '../../../home/presentation/screens/inspector_home_screen.dart';
import '../../data/auth_repository.dart';
import '../login_controller.dart';
import '../sesion_controller.dart';
import '../widgets/login_background.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

/// Pantalla de login (uso exclusivo del Inspector Técnico en campo, ver CLAUDE.md).
/// La estructura vive aquí; los campos y la lógica están en `features/auth`.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginController(
        repositorio: context.read<AuthRepository>(),
        sesion: context.read<SesionController>(),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const LoginBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(child: _Contenido()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LoginHeader(),
        const SizedBox(height: 28),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LoginForm(
              onLoginSuccess: () => Navigator.of(context).pushReplacement(
                FadeSlidePageRoute(child: const InspectorHomeScreen()),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bomberos Voluntarios UUBR',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.grisTecnico),
        ),
      ],
    );
  }
}
