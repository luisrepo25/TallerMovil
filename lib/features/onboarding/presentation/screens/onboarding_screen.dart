import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/transitions/page_transitions.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../domain/onboarding_data.dart';
import '../widgets/onboarding_background.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/onboarding_header.dart';

/// Pantalla de bienvenida: carrusel de tarjetas informativas + CTA hacia el login.
/// Es lo primero que ve el Inspector Técnico si todavía no tiene sesión.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _duracion = Duration(milliseconds: 380);

  final _pageController = PageController(viewportFraction: 0.9);
  int _paginaActual = 0;

  bool get _esUltimaPagina => _paginaActual == onboardingItems.length - 1;

  void _irALogin() {
    Navigator.of(
      context,
    ).pushReplacement(OnboardingToLoginRoute(child: const LoginScreen()));
  }

  void _continuar() {
    HapticFeedback.lightImpact();
    if (_esUltimaPagina) {
      _irALogin();
    } else {
      _pageController.nextPage(
        duration: _duracion,
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _atras() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: _duracion,
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
          OnboardingBackground(pageController: _pageController),
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  mostrarAtras: _paginaActual > 0,
                  onAtras: _atras,
                  onSaltar: _irALogin,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingItems.length,
                    onPageChanged: (index) {
                      HapticFeedback.lightImpact();
                      setState(() => _paginaActual = index);
                    },
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: OnboardingCard(item: onboardingItems[index]),
                    ),
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
                OnboardingFooter(
                  esUltimaPagina: _esUltimaPagina,
                  onContinuar: _continuar,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
