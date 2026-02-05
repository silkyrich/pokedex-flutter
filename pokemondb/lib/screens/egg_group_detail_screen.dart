import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/breeding.dart';
import '../services/pokeapi_service.dart';

class EggGroupDetailScreen extends StatefulWidget {
  final String eggGroupName;

  const EggGroupDetailScreen({super.key, required this.eggGroupName});

  @override
  State<EggGroupDetailScreen> createState() => _EggGroupDetailScreenState();
}

class _EggGroupDetailScreenState extends State<EggGroupDetailScreen> {
  EggGroupDetail? _eggGroup;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEggGroup();
  }

  @override
  void didUpdateWidget(EggGroupDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.eggGroupName != widget.eggGroupName) _loadEggGroup();
  }

  Future<void> _loadEggGroup() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final eggGroup = await PokeApiService.getEggGroup(widget.eggGroupName);
      if (mounted) {
        setState(() {
          _eggGroup = eggGroup;
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
    final screenWidth = MediaQuery.of(context).size.width;

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
                    'Loading egg group...',
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
                        'Failed to load egg group',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loadEggGroup,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_eggGroup!.displayName),
                          Text(
                            '${_eggGroup!.pokemonSpecies.length} Pokémon Species',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth > 1000
                              ? 6
                              : screenWidth > 700
                                  ? 4
                                  : 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final species = _eggGroup!.pokemonSpecies[index];
                            return _PokemonSpeciesCard(species: species);
                          },
                          childCount: _eggGroup!.pokemonSpecies.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PokemonSpeciesCard extends StatefulWidget {
  final PokemonSpeciesRef species;

  const _PokemonSpeciesCard({required this.species});

  @override
  State<_PokemonSpeciesCard> createState() => _PokemonSpeciesCardState();
}

class _PokemonSpeciesCardState extends State<_PokemonSpeciesCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/pokemon/${widget.species.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pokemon sprite
                Expanded(
                  child: Image.network(
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${widget.species.id}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.catching_pokemon,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Pokemon name
                Text(
                  widget.species.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
