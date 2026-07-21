import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/utils/polyline_decoder.dart';
import '../../../../core/widgets/chasqui_tag.dart';
import '../../../incidents/domain/incident_entities.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../routing/presentation/providers/routing_providers.dart';
import '../../../trips/domain/trip.dart';
import '../../../trips/presentation/providers/trips_providers.dart';

const double _tabBarClearance = 112;

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      profileControllerProvider.select((state) => state.value?.displayName),
    );
    final activeIncidents =
        ref.watch(citywideActiveIncidentsProvider).value ?? [];
    final hasActiveTrip = ref.watch(activeTripProvider) != null;
    final unseenNotifications = ref.watch(unseenNotificationsCountProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(citywideActiveIncidentsProvider.future),
            ref.refresh(recentTripsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: _tabBarClearance),
          children: [
            _HomeHeader(
              displayName: displayName,
              unseenNotifications: unseenNotifications,
            ),
            _MapBanner(
              activeIncidentCount: activeIncidents.length,
              hasActiveTrip: hasActiveTrip,
            ),
            if (activeIncidents.isNotEmpty)
              _NearestIncidentAlert(incidents: activeIncidents),
            const _QuickActionsGrid(),
            const _RecentTripsSection(),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.displayName,
    required this.unseenNotifications,
  });

  final String? displayName;
  final int unseenNotifications;

  String get _greetingForCurrentHour {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _initials {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return '·';
    final words = name.split(RegExp(r'\s+'));
    final first = words.first.characters.first;
    final second = words.length > 1 ? words[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ChasquiColors.neutral100)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingForCurrentHour,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ChasquiColors.warm600,
                      ),
                    ),
                    Text(
                      'Hola, ${displayName ?? 'viajero'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _NotificationBell(showBadge: unseenNotifications > 0),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ChasquiColors.yellow600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ChasquiColors.neutral950,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Buscar una ruta',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go(AppRoutes.routes),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ChasquiColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ChasquiColors.neutral200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 16,
                      color: ChasquiColors.neutral400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¿A dónde vas?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ChasquiColors.neutral400,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ChasquiColors.yellow600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Buscar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ChasquiColors.neutral950,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.showBadge});

  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Notificaciones',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.notifications),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ChasquiColors.neutral50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 18,
                color: ChasquiColors.neutral700,
              ),
              if (showBadge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ChasquiColors.orange600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapBanner extends StatelessWidget {
  const _MapBanner({
    required this.activeIncidentCount,
    required this.hasActiveTrip,
  });

  final int activeIncidentCount;
  final bool hasActiveTrip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Semantics(
        label: 'Abrir el mapa de La Paz',
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutes.map),
          child: Container(
            height: 148,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ChasquiColors.neutral700,
                  ChasquiColors.neutral900,
                ],
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.map_rounded,
                    size: 56,
                    color: ChasquiColors.neutral500,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: ChasquiColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasActiveTrip ? 'Viaje en curso' : 'Ver mapa en vivo',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ChasquiColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (activeIncidentCount > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ChasquiTag(
                      label: activeIncidentCount == 1
                          ? '1 alerta'
                          : '$activeIncidentCount alertas',
                      background: ChasquiColors.orange600,
                      foreground: Colors.white,
                      icon: Icons.error_outline,
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

class _NearestIncidentAlert extends ConsumerWidget {
  const _NearestIncidentAlert({required this.incidents});

  final List<Incident> incidents;

  Incident _mostRelevantFor(WidgetRef ref) {
    final position = ref.watch(currentPositionProvider).value;
    if (position == null || incidents.length == 1) return incidents.first;
    return incidents.reduce((closest, candidate) {
      double squaredDistanceTo(Incident incident) =>
          pow(incident.lat - position.lat, 2).toDouble() +
          pow(incident.lng - position.lng, 2).toDouble();
      return squaredDistanceTo(candidate) < squaredDistanceTo(closest)
          ? candidate
          : closest;
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = _mostRelevantFor(ref);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.map),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ChasquiColors.warm200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChasquiColors.warm400),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: ChasquiColors.orange700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${incident.kind.label} activo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ChasquiColors.orange700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChasquiColors.warm800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTripsSection extends ConsumerWidget {
  const _RecentTripsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(recentTripsProvider);
    final trips = tripsState.value ?? [];
    if (trips.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VIAJES RECIENTES', style: theme.textTheme.labelSmall),
          const SizedBox(height: 12),
          for (final trip in trips) ...[
            _RecentTripTile(trip: trip),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RecentTripTile extends ConsumerWidget {
  const _RecentTripTile({required this.trip});

  final Trip trip;

  static const List<String> _shortMonths = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String get _formattedStart {
    final started = trip.startedAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startedDay = DateTime(started.year, started.month, started.day);
    final time =
        '${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')}';
    if (startedDay == today) return 'Hoy, $time';
    if (startedDay == today.subtract(const Duration(days: 1))) {
      return 'Ayer, $time';
    }
    return '${started.day} ${_shortMonths[started.month - 1]}, $time';
  }

  void _planAgain(BuildContext context, WidgetRef ref) {
    final polyline = trip.lastLegPolyline;
    if (polyline == null || polyline.isEmpty) {
      context.go(AppRoutes.routes);
      return;
    }
    final points = decodePolyline(polyline);
    if (points.isEmpty) {
      context.go(AppRoutes.routes);
      return;
    }
    ref.read(routeRequestProvider.notifier).setDestination(points.last);
    context.push(AppRoutes.map);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final originLabel = trip.originName ?? 'Origen';
    final destinationLabel = trip.destinationName ?? 'Destino';
    return Semantics(
      label: 'Viaje de $originLabel a $destinationLabel, volver a planificar',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _planAgain(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChasquiColors.neutral100),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ChasquiColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 12,
                    color: ChasquiColors.neutral200,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ChasquiColors.orange600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$originLabel → $destinationLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ChasquiColors.neutral950,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedStart,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ChasquiColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trip.totalCostBs != null)
                Text(
                  'Bs. ${trip.totalCostBs!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ChasquiColors.yellow700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final void Function(BuildContext context) onTap;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static final List<_QuickAction> _actions = [
    _QuickAction(
      label: 'Planificar',
      icon: Icons.navigation_rounded,
      background: ChasquiColors.yellow200,
      foreground: ChasquiColors.yellow800,
      onTap: (context) => context.go(AppRoutes.routes),
    ),
    _QuickAction(
      label: 'Denunciar',
      icon: Icons.description_rounded,
      background: ChasquiColors.warm200,
      foreground: ChasquiColors.orange700,
      onTap: (context) => context.go(AppRoutes.complaints),
    ),
    _QuickAction(
      label: 'Comunidad',
      icon: Icons.groups_rounded,
      background: ChasquiColors.neutral100,
      foreground: ChasquiColors.neutral700,
      onTap: (context) => context.push(AppRoutes.community),
    ),
    _QuickAction(
      label: 'Familia',
      icon: Icons.favorite_rounded,
      background: ChasquiColors.yellow100,
      foreground: ChasquiColors.yellow700,
      onTap: (context) => context.push(AppRoutes.family),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACCIONES RÁPIDAS', style: theme.textTheme.labelSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final action in _actions)
                Expanded(
                  child: Semantics(
                    label: action.label,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => action.onTap(context),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: action.background,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              action.icon,
                              size: 20,
                              color: action.foreground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: ChasquiColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
