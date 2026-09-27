import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/page_transitions.dart';
import '../../screens/login_screen.dart';
import '../../theme/app_theme.dart';
import 'onboarding_card.dart';
import 'onboarding_data.dart';

/// Pantalla de bienvenida: carrusel de tarjetas informativas + CTA hacia
/// el login. Es lo primero que ve el Inspector Tecnico al abrir la app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController(viewportFraction: 0.9);
  int _paginaActual = 0;

  bool get _esUltimaPagina => _paginaActual == onboardingItems.length - 1;

  void _irALogin() {
    Navigator.of(context).pushReplacement(
      OnboardingToLoginRoute(child: const LoginScreen()),
    );
  }

  void _presionarCta() {
    HapticFeedback.lightImpact();
    if (_esUltimaPagina) {
      _irALogin();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _paginaAnterior() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      body: Stack(
        children: [
          _FondoDinamico(pageController: _pageController),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: _paginaActual > 0
                            ? IconButton(
                                key: const ValueKey('atras'),
                                onPressed: _paginaAnterior,
                                icon: const Icon(Icons.arrow_back, color: AppColors.grisTecnico),
                                tooltip: 'Atras',
                              )
                            : const SizedBox(width: 48, height: 48, key: ValueKey('sin-atras')),
                      ),
                      TextButton(
                        onPressed: _irALogin,
                        child: const Text(
                          'Saltar',
                          style: TextStyle(color: AppColors.grisTecnico),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingItems.length,
                    onPageChanged: (index) {
                      HapticFeedback.lightImpact();
                      setState(() => _paginaActual = index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: OnboardingCard(item: onboardingItems[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: onboardingItems.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: onboardingItems[_paginaActual].colorAcento,
                    dotColor: AppColors.grisTecnico.withValues(alpha: 0.25),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: FilledButton(
                          key: ValueKey(_esUltimaPagina),
                          style: _esUltimaPagina
                              ? FilledButton.styleFrom(backgroundColor: AppColors.rojoSeguridad)
                              : null,
                          onPressed: _presionarCta,
                          child: Text(_esUltimaPagina ? 'Ingresar al Sistema' : 'Continuar'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _mostrarAyuda(context),
                        child: const Text(
                          'Modo Consulta / Ayuda',
                          style: TextStyle(color: AppColors.grisTecnico),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAyuda(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modo Consulta'),
        content: const Text(
          'Contacta a tu Oficial de Mando o Administrador si necesitas ayuda '
          'para acceder al sistema con tus credenciales de Inspector Tecnico.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }
}

/// Fondo con dos halos de color que se funden entre el color de acento de la
/// pagina actual y la siguiente mientras el usuario desliza, para que el
/// fondo neutro no se sienta plano ni desconectado de cada tarjeta.
class _FondoDinamico extends StatelessWidget {
  const _FondoDinamico({required this.pageController});

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, _) {
        double pagina = 0;
        if (pageController.positions.isNotEmpty && pageController.position.haveDimensions) {
          pagina = pageController.page ?? 0;
        }
        final indiceActual = pagina.floor().clamp(0, onboardingItems.length - 1);
        final indiceSiguiente = (indiceActual + 1).clamp(0, onboardingItems.length - 1);
        final progreso = pagina - indiceActual;
        final color = Color.lerp(
          onboardingItems[indiceActual].colorAcento,
          onboardingItems[indiceSiguiente].colorAcento,
          progreso,
        )!;

        return Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _Halo(diametro: 260, color: color.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: -110,
              left: -90,
              child: _Halo(diametro: 300, color: color.withValues(alpha: 0.07)),
            ),
          ],
        );
      },
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.diametro, required this.color});

  final double diametro;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
