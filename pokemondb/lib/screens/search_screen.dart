import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../models/move.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_card.dart';
import '../utils/type_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<PokemonBasic>? _results;
  bool _searching = false;
  Timer? _debounce;

  // Filter state
  int _selectedGen = 0;
  Set<String> _filterTypes = {};
  String? _filterMove;
  String? _filterMoveDisplay;
  Set<int>? _moveFilterIds;
  bool _loadingMoveFilter = false;

  static const Map<int, List<int>> _genRanges = {
    0: [1, 1025],
    1: [1, 151],
    2: [152, 251],
    3: [252, 386],
    4: [387, 493],
    5: [494, 649],
    6: [650, 721],
    7: [722, 809],
    8: [810, 905],
    9: [906, 1025],
  };

  static const List<String> _allTypes = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice',
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search());
  }

  Future<void> _search() async {
    setState(() => _searching = true);

    try {
      // Start with all Pokemon or text search results
      List<PokemonBasic> results;
      final query = _controller.text.trim();

      if (query.isNotEmpty) {
        results = await PokeApiService.searchPokemon(query);
      } else {
        results = await PokeApiService.getAllPokemonBasic();
      }

      // Apply generation filter
      if (_selectedGen != 0) {
        final range = _genRanges[_selectedGen]!;
        results = results.where((p) => p.id >= range[0] && p.id <= range[1]).toList();
      }

      // Apply type filter
      if (_filterTypes.isNotEmpty) {
        final filteredResults = <PokemonBasic>[];
        for (final pokemon in results) {
          final details = await PokeApiService.getPokemonDetail(pokemon.id);
          final types = details.types.map((t) => t.name.toLowerCase()).toSet();
          if (_filterTypes.any((ft) => types.contains(ft))) {
            filteredResults.add(pokemon);
          }
        }
        results = filteredResults;
      }

      // Apply move filter
      if (_moveFilterIds != null) {
        results = results.where((p) => _moveFilterIds!.contains(p.id)).toList();
      }

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

  Future<void> _loadMoveFilter(String moveName) async {
    setState(() => _loadingMoveFilter = true);
    try {
      final move = await PokeApiService.getMoveDetail(moveName);
      final ids = move.learnedByPokemon.map((p) => p.id).toSet();
      if (mounted) {
        setState(() {
          _moveFilterIds = ids;
          _filterMoveDisplay = move.displayName;
          _loadingMoveFilter = false;
        });
        _search();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _moveFilterIds = null;
          _filterMoveDisplay = null;
          _loadingMoveFilter = false;
        });
      }
    }
  }

  void _toggleType(String type) {
    setState(() {
      if (_filterTypes.contains(type)) {
        _filterTypes.remove(type);
      } else {
        _filterTypes.add(type);
      }
    });
    _search();
  }

  void _setGeneration(int gen) {
    setState(() => _selectedGen = gen);
    _search();
  }

  void _clearFilters() {
    setState(() {
      _controller.clear();
      _selectedGen = 0;
      _filterTypes.clear();
      _filterMove = null;
      _filterMoveDisplay = null;
      _moveFilterIds = null;
      _results = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 7
        : screenWidth > 900
            ? 5
            : screenWidth > 600
                ? 4
                : 3;

    final hasActiveFilters = _controller.text.isNotEmpty ||
        _selectedGen != 0 ||
        _filterTypes.isNotEmpty ||
        _moveFilterIds != null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
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
                            'Universal Search',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search and filter by name, type, generation, moves, and more.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasActiveFilters)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Text search field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or number...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            onPressed: () {
                              _controller.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                // Generation filter
                _buildSectionLabel(theme, 'Generation'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int gen = 0; gen <= 9; gen++)
                      ChoiceChip(
                        label: Text(gen == 0 ? 'All' : 'Gen $gen'),
                        selected: _selectedGen == gen,
                        onSelected: (_) => _setGeneration(gen),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Type filter
                _buildSectionLabel(theme, 'Types'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allTypes.map((type) {
                    final isSelected = _filterTypes.contains(type);
                    final color = TypeColors.getColor(type);
                    return FilterChip(
                      label: Text(
                        type[0].toUpperCase() + type.substring(1),
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _toggleType(type),
                      backgroundColor: color.withOpacity(0.15),
                      selectedColor: color,
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                if (_searching)
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                else if (_results != null && _results!.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Pokemon found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search term.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_results != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_results!.length > 50 ? "50+" : _results!.length} results',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.78,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
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
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.catching_pokemon,
                            size: 80,
                            color: theme.colorScheme.onSurface.withOpacity(0.08),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Type a name or number to search',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.35),
                              fontSize: 15,
                            ),
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

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }
}
