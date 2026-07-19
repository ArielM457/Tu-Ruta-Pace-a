import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../profile/domain/favorite.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/providers/favorites_providers.dart';
import '../../../profile/presentation/widgets/preference_options.dart';
import '../../domain/place_suggestion.dart';
import '../providers/routing_providers.dart';

const double _tabBarClearance = 112;
const Duration _autocompleteDebounce = Duration(milliseconds: 350);
const String _myLocationLabel = 'Mi ubicación';

enum _ActiveField { origin, destination }

class RoutesPlannerScreen extends ConsumerStatefulWidget {
  const RoutesPlannerScreen({super.key});

  @override
  ConsumerState<RoutesPlannerScreen> createState() =>
      _RoutesPlannerScreenState();
}

class _RoutesPlannerScreenState extends ConsumerState<RoutesPlannerScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  Timer? _debounceTimer;
  String _debouncedQuery = '';
  _ActiveField? _activeField;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final position = await ref.read(currentPositionProvider.future);
    if (position == null || !mounted) return;
    ref.read(routeRequestProvider.notifier).setOrigin(position);
    setState(() => _originController.text = _myLocationLabel);
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_autocompleteDebounce, () {
      if (!mounted) return;
      setState(() => _debouncedQuery = query);
    });
  }

  void _selectSuggestion(PlaceSuggestion suggestion) {
    final field = _activeField;
    if (field == null) return;
    if (field == _ActiveField.origin) {
      _originController.text = suggestion.description;
      ref.read(routeRequestProvider.notifier).setOrigin(suggestion.coordinate);
    } else {
      _destinationController.text = suggestion.description;
      ref
          .read(routeRequestProvider.notifier)
          .setDestination(suggestion.coordinate);
    }
    setState(() {
      _activeField = null;
      _debouncedQuery = '';
    });
  }

  void _selectFavorite(Favorite favorite) {
    _destinationController.text = favorite.name;
    ref.read(routeRequestProvider.notifier).setDestination(favorite.coordinate);
    setState(() {
      _activeField = null;
      _debouncedQuery = '';
    });
  }

  void _swapFields() {
    final request = ref.read(routeRequestProvider);
    final originText = _originController.text;
    setState(() {
      _originController.text = _destinationController.text;
      _destinationController.text = originText;
    });
    if (request.origin != null && request.destination != null) {
      ref.read(routeRequestProvider.notifier)
        ..setOrigin(request.destination!)
        ..setDestination(request.origin!);
    }
  }

  void _search() {
    final request = ref.read(routeRequestProvider);
    if (!request.isComplete) return;
    context.push(AppRoutes.routeOptions);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = ref.watch(routeRequestProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, _tabBarClearance),
        children: [
          Text('Planifica tu viaje', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Escribe tu destino o fija un punto en el mapa',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ChasquiColors.neutral500,
            ),
          ),
          const SizedBox(height: 20),
          ChasquiCard(
            child: Column(
              children: [
                _AddressField(
                  controller: _originController,
                  dotColor: ChasquiColors.success,
                  hintText: 'Origen',
                  semanticsLabel: 'Campo de origen',
                  onFocused: () => setState(() {
                    _activeField = _ActiveField.origin;
                    _debouncedQuery = _originController.text;
                  }),
                  onChanged: _onQueryChanged,
                ),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 3),
                      width: 1,
                      height: 20,
                      color: ChasquiColors.neutral200,
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Intercambiar origen y destino',
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _swapFields,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ChasquiColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            size: 16,
                            color: ChasquiColors.neutral500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _AddressField(
                  controller: _destinationController,
                  dotColor: ChasquiColors.orange600,
                  hintText: 'Destino',
                  semanticsLabel: 'Campo de destino',
                  onFocused: () => setState(() {
                    _activeField = _ActiveField.destination;
                    _debouncedQuery = _destinationController.text;
                  }),
                  onChanged: _onQueryChanged,
                ),
              ],
            ),
          ),
          if (_activeField != null) _SuggestionsList(query: _debouncedQuery, onSelect: _selectSuggestion),
          const SizedBox(height: 16),
          _FavoritesQuickAccess(onSelect: _selectFavorite),
          Text('¿QUÉ PRIORIZAS HOY?', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final priority in TravelPriority.values)
                ChoiceChip(
                  avatar: Icon(priority.icon, size: 16),
                  label: Text(priority.label),
                  selected: priority == request.priority,
                  onSelected: (_) => ref
                      .read(routeRequestProvider.notifier)
                      .setPriority(priority),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: request.isComplete ? _search : null,
            child: const Text('Buscar rutas'),
          ),
          const SizedBox(height: 20),
          ChasquiCard(
            onTap: () => context.push(AppRoutes.map),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ChasquiColors.yellow200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: ChasquiColors.yellow800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fijar destino en el mapa',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'Mantén presionado el punto al que quieres ir',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ChasquiColors.neutral400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.dotColor,
    required this.hintText,
    required this.semanticsLabel,
    required this.onFocused,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Color dotColor;
  final String hintText;
  final String semanticsLabel;
  final VoidCallback onFocused;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: semanticsLabel,
              textField: true,
              child: TextField(
                controller: controller,
                onTap: onFocused,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: false,
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: ChasquiColors.neutral950,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsList extends ConsumerWidget {
  const _SuggestionsList({required this.query, required this.onSelect});

  final String query;
  final ValueChanged<PlaceSuggestion> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().length < 2) return const SizedBox.shrink();
    final suggestionsState = ref.watch(placeAutocompleteProvider(query));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ChasquiCard(
        padding: EdgeInsets.zero,
        child: suggestionsState.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (suggestions) {
            if (suggestions.isEmpty) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final suggestion in suggestions)
                  Semantics(
                    label: suggestion.description,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelect(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: ChasquiColors.neutral400,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FavoritesQuickAccess extends ConsumerWidget {
  const _FavoritesQuickAccess({required this.onSelect});

  final ValueChanged<Favorite> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final favorites = favoritesState.value ?? [];
    if (favorites.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FAVORITAS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return Semantics(
                  label: 'Usar ${favorite.name} como destino',
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onSelect(favorite),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ChasquiColors.yellow100,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: ChasquiColors.yellow400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: ChasquiColors.yellow800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            favorite.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ChasquiColors.yellow800,
                            ),
                          ),
                        ],
                      ),
                    ),
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
