import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../widgets/app_header.dart';
import '../widgets/pokemon_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PokemonBasic> _pokemon = [];
  final Map<int, List<String>> _types = {};
  bool _loading = true;
  bool _loadingMore = false;
  int _offset = 0;
  int _total = 0;
  static const int _pageSize = 50;
  final ScrollController _scrollController = ScrollController();
  int _selectedGen = 0; // 0 = all

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

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _pokemon.clear();
      _types.clear();
      _offset = 0;
    });

    try {
      final range = _genRanges[_selectedGen]!;
      _total = range[1] - range[0] + 1;
      final limit = _pageSize.clamp(0, _total);
      final list = await PokeApiService.getPokemonList(
        offset: range[0] - 1,
        limit: limit,
      );
      _offset = limit;

      // Fetch types for visible pokemon
      await _fetchTypes(list);

      if (mounted) {
        setState(() {
          _pokemon.addAll(list);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _offset >= _total) return;
    setState(() => _loadingMore = true);

    try {
      final range = _genRanges[_selectedGen]!;
      final remaining = _total - _offset;
      final limit = _pageSize.clamp(0, remaining);
      final list = await PokeApiService.getPokemonList(
        offset: range[0] - 1 + _offset,
        limit: limit,
      );
      _offset += limit;

      await _fetchTypes(list);

      if (mounted) {
        setState(() {
          _pokemon.addAll(list);
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _fetchTypes(List<PokemonBasic> list) async {
    // Fetch types in batches to avoid hammering the API
    for (final p in list) {
      if (_types.containsKey(p.id)) continue;
      try {
        final detail = await PokeApiService.getPokemonDetail(p.id);
        _types[p.id] = detail.types.map((t) => t.name).toList();
      } catch (_) {}
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
      body: Column(
        children: [
          // Generation filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pokédex',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse Pokémon by National Pokédex number. Click a Pokémon to see detailed stats.',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _GenChip(label: 'All', selected: _selectedGen == 0, onTap: () => _selectGen(0)),
                      for (int i = 1; i <= 9; i++)
                        _GenChip(
                          label: 'Gen $i',
                          selected: _selectedGen == i,
                          onTap: () => _selectGen(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Pokemon grid
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF3B5BA7)),
                        SizedBox(height: 16),
                        Text('Loading Pokémon...', style: TextStyle(color: Color(0xFF666666))),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _pokemon.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _pokemon.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: Color(0xFF3B5BA7)),
                          ),
                        );
                      }
                      final p = _pokemon[index];
                      return PokemonCard(
                        pokemon: p,
                        types: _types[p.id],
                        onTap: () => context.go('/pokemon/${p.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _selectGen(int gen) {
    if (gen == _selectedGen) return;
    _selectedGen = gen;
    _loadInitial();
  }
}

class _GenChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenChip({required this.label, required this.selected, required this.onTap});

  @override
  State<_GenChip> createState() => _GenChipState();
}

class _GenChipState extends State<_GenChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF3B5BA7)
                : _hovered
                    ? const Color(0xFFE8EDF5)
                    : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? Colors.white : const Color(0xFF555555),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
