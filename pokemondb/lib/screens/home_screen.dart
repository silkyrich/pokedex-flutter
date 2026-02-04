import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_card.dart';
import '../utils/type_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_PokemonEntry> _entries = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _offset = 0;
  int _total = 0;
  static const int _pageSize = 50;
  final ScrollController _scrollController = ScrollController();
  int _selectedGen = 0;
  String? _filterType;

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
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for type filter from URL query params
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type'];
    if (typeParam != _filterType) {
      _filterType = typeParam;
      _loadInitial();
    } else if (_entries.isEmpty && _loading) {
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_loadingMore &&
        _offset < _total &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500) {
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
      final types = d?.types.map((t) => t.name).toList();

      // Apply type filter
      if (_filterType != null && types != null && !types.contains(_filterType)) {
        continue;
      }

      _entries.add(_PokemonEntry(
        basic: PokemonBasic(id: id, name: d?.name ?? 'pokemon-$id', url: ''),
        types: types,
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

  void _clearTypeFilter() {
    _filterType = null;
    context.go('/');
    _loadInitial();
  }

  void _setTypeFilter(String type) {
    context.go('/?type=$type');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 7
        : screenWidth > 900
            ? 5
            : screenWidth > 600
                ? 4
                : 3;

    return Scaffold(
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                            'Pokedex',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Browse Pokemon by National Pokedex number.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_entries.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_entries.length} Pokemon',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                // Active type filter chip
                if (_filterType != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.filter_list_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text('Filtered by type:', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          _filterType![0].toUpperCase() + _filterType!.substring(1),
                          style: TextStyle(
                            color: TypeColors.getTextColor(_filterType!),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: TypeColors.getColor(_filterType!),
                        deleteIcon: Icon(Icons.close, size: 16, color: TypeColors.getTextColor(_filterType!)),
                        onDeleted: _clearTypeFilter,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Gen filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _GenChip(label: 'All Gens', selected: _selectedGen == 0, onTap: () => _selectGen(0)),
                      for (int i = 1; i <= 9; i++)
                        _GenChip(
                          label: 'Gen $i',
                          selected: _selectedGen == i,
                          onTap: () => _selectGen(i),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final type in TypeChart.types)
                        _TypeFilterChip(
                          type: type,
                          selected: _filterType == type,
                          onTap: () {
                            if (_filterType == type) {
                              _clearTypeFilter();
                            } else {
                              _setTypeFilter(type);
                            }
                          },
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
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading Pokemon...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 15,
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
                              child: const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _loadInitial,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.78,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final entry = _entries[index];
                                  return PokemonCard(
                                    pokemon: entry.basic,
                                    types: entry.types,
                                    onTap: () => context.go('/pokemon/${entry.basic.id}'),
                                  );
                                },
                                childCount: _entries.length,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: _loadingMore
                                  ? Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Loading more...',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _offset >= _total && _entries.isNotEmpty
                                      ? Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'All ${_entries.length} Pokemon loaded',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                            ),
                          ),
                        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary
                  : isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade300,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withOpacity(0.7),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = TypeColors.getColor(type);
    final textColor = TypeColors.getTextColor(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? typeColor
                  : isDark
                      ? typeColor.withOpacity(0.1)
                      : typeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? typeColor
                    : typeColor.withOpacity(isDark ? 0.25 : 0.2),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_rounded, size: 14, color: textColor),
                  ),
                Text(
                  type[0].toUpperCase() + type.substring(1),
                  style: TextStyle(
                    color: selected
                        ? textColor
                        : isDark
                            ? typeColor
                            : typeColor.withOpacity(0.9),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11,
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
