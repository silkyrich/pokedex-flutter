import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../widgets/app_header.dart';
import '../widgets/pokemon_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<PokemonBasic>? _results;
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() => _searching = true);

    try {
      final results = await PokeApiService.searchPokemon(query);
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 8
        : screenWidth > 900
            ? 6
            : screenWidth > 600
                ? 4
                : 3;

    return Scaffold(
      appBar: const AppHeader(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Pokémon',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or number...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF999999)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                if (_searching)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF3B5BA7)))
                else if (_results != null && _results!.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No Pokémon found.',
                        style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                      ),
                    ),
                  )
                else if (_results != null)
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _results!.length.clamp(0, 50),
                      itemBuilder: (context, index) {
                        final p = _results![index];
                        return PokemonCard(
                          pokemon: p,
                          onTap: () => context.go('/pokemon/${p.id}'),
                        );
                      },
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.catching_pokemon, size: 80, color: Color(0xFFDDDDDD)),
                          SizedBox(height: 16),
                          Text(
                            'Type a Pokémon name or number to search',
                            style: TextStyle(color: Color(0xFF999999), fontSize: 15),
                          ),
                        ],
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
