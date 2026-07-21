import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';

const double _tabBarBottomMargin = 16;
const double _chaskiButtonSize = 56;

class ChasquiShell extends StatelessWidget {
  const ChasquiShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const _ChasquiWordmarkStrip(),
              Expanded(child: navigationShell),
            ],
          ),
          Positioned(
            left: _tabBarBottomMargin,
            right: _tabBarBottomMargin,
            bottom: _tabBarBottomMargin +
                MediaQuery.paddingOf(context).bottom,
            child: _ChasquiTabBar(navigationShell: navigationShell),
          ),
        ],
      ),
    );
  }
}

class _ChasquiWordmarkStrip extends StatelessWidget {
  const _ChasquiWordmarkStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChasquiColors.yellow600,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ChasquiColors.yellow500)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.navigation,
                size: 13,
                color: ChasquiColors.neutral950,
              ),
              SizedBox(width: 6),
              Text(
                'CHASQUI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: ChasquiColors.neutral950,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDefinition {
  const _TabDefinition({
    required this.label,
    required this.icon,
    required this.isSos,
  });

  final String label;
  final IconData icon;
  final bool isSos;
}

const List<_TabDefinition> _tabs = [
  _TabDefinition(label: 'Inicio', icon: Icons.home_rounded, isSos: false),
  _TabDefinition(label: 'Rutas', icon: Icons.map_rounded, isSos: false),
  _TabDefinition(label: 'SOS', icon: Icons.bolt_rounded, isSos: true),
  _TabDefinition(
    label: 'Denuncias',
    icon: Icons.description_rounded,
    isSos: false,
  ),
  _TabDefinition(label: 'Perfil', icon: Icons.person_rounded, isSos: false),
];

class _ChasquiTabBar extends StatelessWidget {
  const _ChasquiTabBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: ChasquiColors.neutral100),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 4),
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: Color(0x0F000000),
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                for (final (index, tab) in _tabs.indexed)
                  _ChasquiTabButton(
                    definition: tab,
                    isActive: navigationShell.currentIndex == index,
                    onTap: () => _goToBranch(index),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ChaskiButton(
          onTap: () => context.push(AppRoutes.assistant),
        ),
      ],
    );
  }
}

class _ChasquiTabButton extends StatelessWidget {
  const _ChasquiTabButton({
    required this.definition,
    required this.isActive,
    required this.onTap,
  });

  final _TabDefinition definition;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeBackground =
        definition.isSos ? ChasquiColors.orange600 : ChasquiColors.yellow600;
    final Color activeForeground =
        definition.isSos ? Colors.white : ChasquiColors.neutral950;
    final Color foreground =
        isActive ? activeForeground : ChasquiColors.neutral400;

    return Expanded(
      child: Semantics(
        label: definition.label,
        button: true,
        selected: isActive,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? activeBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(definition.icon, size: 16, color: foreground),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    definition.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChaskiButton extends StatelessWidget {
  const _ChaskiButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Abrir chat con Chaski',
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: _chaskiButtonSize,
          height: _chaskiButtonSize,
          decoration: BoxDecoration(
            color: ChasquiColors.yellow600,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55FFD516),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
              BoxShadow(
                color: Color(0x26000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 19,
                color: ChasquiColors.neutral950,
              ),
              SizedBox(height: 2),
              Text(
                'Chaski',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: ChasquiColors.neutral950,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
