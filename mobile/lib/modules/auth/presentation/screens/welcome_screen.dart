import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';

class _WelcomeSlide {
  const _WelcomeSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const List<_WelcomeSlide> _slides = [
  _WelcomeSlide(
    icon: Icons.route,
    title: 'Toda La Paz en una ruta',
    description:
        'Teleférico, PumaKatari, minibuses y taxis combinados en una sola recomendación de viaje, con tiempo y costo en Bs.',
  ),
  _WelcomeSlide(
    icon: Icons.handshake,
    title: 'Colabora: dar y recibir',
    description:
        'Comparte tu ubicación mientras viajas y responde preguntas de otros para ganar Puntos Chass; úsalos para preguntar dónde viene tu transporte.',
  ),
  _WelcomeSlide(
    icon: Icons.alt_route,
    title: 'Esquiva los bloqueos',
    description:
        'Rutas que evitan bloqueos y movilizaciones en tiempo real, priorizando el teleférico que pasa por encima del conflicto.',
  ),
];

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentSlideIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              const _ChasquiWordmark(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentSlideIndex = index),
                  itemBuilder: (context, index) =>
                      _SlideView(slide: _slides[index]),
                ),
              ),
              const SizedBox(height: 16),
              _SlideIndicator(
                slideCount: _slides.length,
                currentIndex: _currentSlideIndex,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Crear cuenta'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Ya tengo cuenta'),
              ),
              const SizedBox(height: 8),
              Text(
                'Movilidad colaborativa para La Paz',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChasquiWordmark extends StatelessWidget {
  const _ChasquiWordmark();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ChasquiColors.yellow600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.navigation,
              size: 16,
              color: ChasquiColors.neutral950,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'CHASQUI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: ChasquiColors.neutral950,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _WelcomeSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: ChasquiColors.yellow100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  slide.icon,
                  size: 56,
                  color: ChasquiColors.yellow800,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                slide.title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                slide.description,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideIndicator extends StatelessWidget {
  const _SlideIndicator({
    required this.slideCount,
    required this.currentIndex,
  });

  final int slideCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int index = 0; index < slideCount; index++)
          Container(
            width: index == currentIndex ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == currentIndex
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
