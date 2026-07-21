import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../domain/emergency_entities.dart';
import '../providers/emergency_providers.dart';
import '../widgets/emergency_contact_card.dart';
import '../widgets/emergency_route_sheet.dart';
import '../widgets/nearby_facility_tile.dart';

enum _SosCategory { rescue, retention, accident }

extension _SosCategoryUi on _SosCategory {
  String get label => switch (this) {
        _SosCategory.rescue => 'Rescate',
        _SosCategory.retention => 'Retención',
        _SosCategory.accident => 'Accidente',
      };

  IconData get icon => switch (this) {
        _SosCategory.rescue => Icons.favorite_rounded,
        _SosCategory.retention => Icons.shield_rounded,
        _SosCategory.accident => Icons.warning_rounded,
      };

  /// null means "both kinds" (backend returns everything).
  String? get facilityKindFilter => switch (this) {
        _SosCategory.rescue => 'hospital',
        _SosCategory.retention => 'police',
        _SosCategory.accident => null,
      };
}

enum _EmergencyTab { nearby, numbers }

const List<EmergencyContact> _fallbackContacts = [
  EmergencyContact(name: 'Policía Nacional', number: '110'),
  EmergencyContact(name: 'Bomberos', number: '119'),
  EmergencyContact(name: 'Ambulancia SAMU', number: '165'),
  EmergencyContact(name: 'Defensa Civil', number: '800-10-1900'),
];

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _sosActive = false;
  _SosCategory? _category;
  _EmergencyTab _tab = _EmergencyTab.nearby;

  Future<void> _openRouteSheet(HealthFacility facility) async {
    final origin = ref.read(currentPositionProvider).value;
    if (origin == null) return;
    await ref.read(emergencyRouteProvider.notifier).buildRoute(origin);
    if (!mounted) return;
    await EmergencyRouteSheet.show(context, origin: origin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final origin = ref.watch(currentPositionProvider).value;
    final facilitiesState = ref.watch(
      nearbyFacilitiesProvider(_category?.facilityKindFilter),
    );

    return Scaffold(
      appBar: const ChasquiTopBar(
        title: 'Emergencias',
        subtitle: 'Servicios de ayuda cercanos',
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SosButtonSection(
            active: _sosActive,
            onToggle: () => setState(() {
              _sosActive = !_sosActive;
              if (!_sosActive) _category = null;
            }),
          ),
          if (_sosActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final category in _SosCategory.values) ...[
                    Expanded(
                      child: _CategoryButton(
                        category: category,
                        isSelected: category == _category,
                        onTap: () => setState(
                          () => _category =
                              _category == category ? null : category,
                        ),
                      ),
                    ),
                    if (category != _SosCategory.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Cercanos',
                    isSelected: _tab == _EmergencyTab.nearby,
                    onTap: () =>
                        setState(() => _tab = _EmergencyTab.nearby),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: 'Números de ayuda',
                    isSelected: _tab == _EmergencyTab.numbers,
                    onTap: () =>
                        setState(() => _tab = _EmergencyTab.numbers),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _tab == _EmergencyTab.nearby
                ? facilitiesState.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Text(
                      'No pudimos cargar los servicios cercanos.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    data: (facilities) {
                      if (facilities.isEmpty) {
                        return Text(
                          'No encontramos servicios cercanos. Activa tu ubicación e intenta de nuevo.',
                          style: theme.textTheme.bodyMedium,
                        );
                      }
                      return Column(
                        children: [
                          for (final (i, facility) in facilities.indexed) ...[
                            NearbyFacilityTile(
                              facility: facility,
                              origin: origin,
                              index: i,
                              onTap: () => _openRouteSheet(facility),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      );
                    },
                  )
                : Consumer(
                    builder: (context, ref, _) {
                      final contactsState =
                          ref.watch(emergencyContactsProvider);
                      return contactsState.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, _) => Column(
                          children: [
                            for (final (i, contact)
                                in _fallbackContacts.indexed) ...[
                              EmergencyContactCard(
                                contact: contact,
                                index: i,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                        data: (contacts) => Column(
                          children: [
                            for (final (i, contact) in contacts.indexed) ...[
                              EmergencyContactCard(
                                contact: contact,
                                index: i,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SosButtonSection extends StatelessWidget {
  const _SosButtonSection({required this.active, required this.onToggle});

  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        children: [
          Semantics(
            label: active
                ? 'Modo emergencia activo. Toca para desactivar.'
                : 'Toca para activar el modo emergencia',
            button: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: active ? ChasquiColors.orange600 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? ChasquiColors.orange600
                        : ChasquiColors.neutral200,
                    width: 3,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: ChasquiColors.orange600.withValues(
                              alpha: 0.13,
                            ),
                            blurRadius: 0,
                            spreadRadius: 10,
                          ),
                          const BoxShadow(
                            color: Color(0x4DF15E1F),
                            offset: Offset(0, 8),
                            blurRadius: 32,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x14000000),
                            offset: Offset(0, 2),
                            blurRadius: 12,
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 32,
                      color: active ? Colors.white : ChasquiColors.neutral300,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      active ? 'ACTIVO' : 'SOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: active
                            ? Colors.white
                            : ChasquiColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            active
                ? 'Compartiendo ubicación con servicios de emergencia'
                : 'Toca para activar modo emergencia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? ChasquiColors.orange600 : ChasquiColors.neutral500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta app ayuda a navegar; no despacha ambulancias.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: ChasquiColors.neutral400),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final _SosCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: category.label,
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ChasquiColors.orange600
                  : ChasquiColors.neutral200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(category.icon, size: 17, color: ChasquiColors.orange600),
              const SizedBox(height: 4),
              Text(
                category.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ChasquiColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ChasquiColors.neutral950 : ChasquiColors.neutral50,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: ChasquiColors.neutral200),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : ChasquiColors.neutral500,
            ),
          ),
        ),
      ),
    );
  }
}
