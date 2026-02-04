import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/app_state.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Map<int, PokemonDetail> _details = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AppState().addListener(_onStateChanged);
    _loadDetails();
  }

  @override
  void dispose() {
    AppState().removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final ids = AppState().favorites.toList()..sort();
    final missing = ids.where((id) => !_details.containsKey(id)).toList();
    if (missing.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    setState(() => _loading = true);
    final results = await PokeApiService.getPokemonDetailsBatch(missing);
    for (int i = 0; i < missing.length; i++) {
      if (results[i] != null) _details[missing[i]] = results[i]!;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState();
    final favIds = appState.favorites.toList()..sort();
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 7 : screenWidth > 900 ? 5 : screenWidth > 600 ? 4 : 3;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorites',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your favorited Pokemon collection.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite, size: 16, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            '${favIds.length}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (favIds.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 56,
                              color: theme.colorScheme.onSurface.withOpacity(0.15),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No favorites yet',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the heart icon on any Pokemon to add it here.',
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.catching_pokemon, size: 18),
                            label: const Text('Browse Pokedex'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: favIds.length,
                      itemBuilder: (context, index) {
                        final id = favIds[index];
                        final detail = _details[id];
                        return PokemonCard(
                          pokemon: PokemonBasic(id: id, name: detail?.name ?? 'pokemon-$id', url: ''),
                          types: detail?.types.map((t) => t.name).toList(),
                          onTap: () => context.go('/pokemon/$id'),
                        );
                      },
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
