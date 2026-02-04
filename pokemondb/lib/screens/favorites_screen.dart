import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/app_state.dart';
import '../services/pokeapi_service.dart';
import '../widgets/app_header.dart';
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
    final appState = AppState();
    final favIds = appState.favorites.toList()..sort();
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 8 : screenWidth > 900 ? 6 : screenWidth > 600 ? 4 : 3;

    return Scaffold(
      appBar: const AppHeader(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Favorites', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${favIds.length} Pokémon', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (favIds.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text('No favorites yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Tap the heart icon on any Pokémon to add it here.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
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
