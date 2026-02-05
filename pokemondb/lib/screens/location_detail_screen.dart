import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/location.dart';
import '../services/pokeapi_service.dart';

class LocationDetailScreen extends StatefulWidget {
  final String locationName;

  const LocationDetailScreen({super.key, required this.locationName});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  LocationDetail? _location;
  Map<String, LocationArea> _areas = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void didUpdateWidget(LocationDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.locationName != widget.locationName) _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final location = await PokeApiService.getLocationDetail(widget.locationName);

      // Load area details
      final areaFutures = location.areas.map((areaRef) async {
        try {
          return await PokeApiService.getLocationArea(areaRef.name);
        } catch (_) {
          return null;
        }
      });

      final areas = await Future.wait(areaFutures);
      final areasMap = <String, LocationArea>{};
      for (final area in areas) {
        if (area != null) {
          areasMap[area.name] = area;
        }
      }

      if (mounted) {
        setState(() {
          _location = location;
          _areas = areasMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading location...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load location',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loadLocation,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final location = _location!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/locations'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.displayName,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (location.region != null)
                            Text(
                              '${location.region![0].toUpperCase()}${location.region!.substring(1)} Region',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Areas
                if (location.areas.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No area data available for this location.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                else
                  ...location.areas.map((areaRef) {
                    final area = _areas[areaRef.name];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildAreaCard(areaRef, area, theme),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaCard(LocationAreaRef areaRef, LocationArea? area, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              areaRef.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (area == null)
              Text(
                'Loading encounters...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              )
            else if (area.pokemonEncounters.isEmpty)
              Text(
                'No Pokemon encounters in this area.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: area.pokemonEncounters.map((encounter) {
                  return _PokemonEncounterChip(encounter: encounter, theme: theme);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PokemonEncounterChip extends StatefulWidget {
  final PokemonEncounter encounter;
  final ThemeData theme;

  const _PokemonEncounterChip({
    required this.encounter,
    required this.theme,
  });

  @override
  State<_PokemonEncounterChip> createState() => _PokemonEncounterChipState();
}

class _PokemonEncounterChipState extends State<_PokemonEncounterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/pokemon/${widget.encounter.pokemonId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.theme.colorScheme.primary.withOpacity(0.1)
                : widget.theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? widget.theme.colorScheme.primary
                  : widget.theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${widget.encounter.pokemonId}.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.catching_pokemon,
                  size: 20,
                  color: widget.theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.encounter.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
