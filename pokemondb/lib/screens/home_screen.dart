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
  // Each entry holds basic info + pre-fetched types
  final List<_PokemonEntry> _entries = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _offset = 0;
  int _total = 0;
  static const int _pageSize = 50;
  final ScrollController _scrollController = ScrollController();
  int _selectedGen = 0;

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
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _entries.clear();
      _offset = 0;
    });

    try {
      final range = _genRanges[_selectedGen]!;
      _total = range[1] - range[0] + 1;
      await _loadBatch(range);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _offset >= _total) return;
    setState(() => _loadingMore = true);

    try {
      final range = _genRanges[_selectedGen]!;
      await _loadBatch(range);
      if (mounted) setState(() => _loadingMore = false);
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Load one batch: fetch details in parallel batches of 10 to get types.
  Future<void> _loadBatch(List<int> range) async {
    final startId = range[0] + _offset;
    final remaining = _total - _offset;
    final count = _pageSize.clamp(0, remaining);
    if (count <= 0) return;

    final ids = List.generate(count, (i) => startId + i);

    final details = await PokeApiService.getPokemonDetailsBatch(ids);

    for (int i = 0; i < ids.length; i++) {
      final d = details[i];
      final id = ids[i];
      _entries.add(_PokemonEntry(
        basic: PokemonBasic(id: id, name: d?.name ?? 'pokemon-$id', url: ''),
        types: d?.types.map((t) => t.name).toList(),
      ));
    }

    _offset += count;
  }

  void _selectGen(int gen) {
    if (gen == _selectedGen) return;
    _selectedGen = gen;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadInitial();
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
      body: Column(
        children: [
          // Header bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pokédex',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse Pokémon by National Pokédex number.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
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
          // Grid
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading Pokémon...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _loadInitial, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _entries.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _entries.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final entry = _entries[index];
                          return PokemonCard(
                            pokemon: entry.basic,
                            types: entry.types,
                            onTap: () => context.go('/pokemon/${entry.basic.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PokemonEntry {
  final PokemonBasic basic;
  final List<String>? types;

  _PokemonEntry({required this.basic, this.types});
}

class _GenChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        checkmarkColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
