import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../models/move.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type'];
    final moveParam = uri.queryParameters['move'];
    if (typeParam != _filterType || moveParam != _filterMove) {
      _filterType = typeParam;
      if (moveParam != _filterMove) {
        _filterMove = moveParam;
        if (moveParam != null) {
          _loadMoveFilter(moveParam);
          return;
        } else {
          _moveFilterIds = null;
          _filterMoveDisplay = null;
        }
      }
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
      // Apply move filter
      if (_moveFilterIds != null && !_moveFilterIds!.contains(id)) {
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
    final params = <String>[];
    if (_filterMove != null) params.add('move=$_filterMove');
    context.go(params.isEmpty ? '/' : '/?${params.join('&')}');
    _loadInitial();
  }

  void _setTypeFilter(String type) {
    final params = <String>['type=$type'];
    if (_filterMove != null) params.add('move=$_filterMove');
    context.go('/?${params.join('&')}');
  }

  Future<void> _loadMoveFilter(String moveName) async {
    setState(() => _loadingMoveFilter = true);
    try {
      final moveDetail = await PokeApiService.getMoveDetail(moveName);
      _filterMoveDisplay = moveDetail.displayName;
      _moveFilterIds = moveDetail.learnedByPokemon.map((p) => p.id).toSet();
    } catch (_) {
      _moveFilterIds = {};
      _filterMoveDisplay = moveName.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
    }
    if (mounted) {
      setState(() => _loadingMoveFilter = false);
      _loadInitial();
    }
  }

  void _clearMoveFilter() {
    _filterMove = null;
    _filterMoveDisplay = null;
    _moveFilterIds = null;
    final params = <String>[];
    if (_filterType != null) params.add('type=$_filterType');
    context.go(params.isEmpty ? '/' : '/?${params.join('&')}');
    _loadInitial();
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
                // Active filter chips
                if (_filterType != null || _filterMove != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.filter_list_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      Text('Filters:', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      if (_filterType != null)
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
                      if (_filterMove != null)
                        Chip(
                          avatar: Icon(Icons.flash_on_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                          label: Text(
                            _filterMoveDisplay ?? _filterMove!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          deleteIcon: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.primary),
                          onDeleted: _clearMoveFilter,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      if (_loadingMoveFilter)
                        SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
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
                // Move filter search
                _MoveFilterSearch(
                  currentMove: _filterMove,
                  onMoveSelected: (moveName) {
                    final params = <String>[];
                    if (_filterType != null) params.add('type=$_filterType');
                    params.add('move=$moveName');
                    context.go('/?${params.join('&')}');
                  },
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

class _MoveFilterSearch extends StatefulWidget {
  final String? currentMove;
  final ValueChanged<String> onMoveSelected;

  const _MoveFilterSearch({this.currentMove, required this.onMoveSelected});

  @override
  State<_MoveFilterSearch> createState() => _MoveFilterSearchState();
}

class _MoveFilterSearchState extends State<_MoveFilterSearch> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<MoveDetail>? _suggestions;
  bool _searching = false;
  bool _showDropdown = false;

  // Cache of loaded moves for searching
  static List<MoveDetail>? _allMoves;
  static bool _loadingAllMoves = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      }
    });
    _ensureMovesLoaded();
  }

  Future<void> _ensureMovesLoaded() async {
    if (_allMoves != null || _loadingAllMoves) return;
    _loadingAllMoves = true;
    try {
      final futures = <Future<MoveDetail>>[];
      for (int i = 1; i <= 165; i++) {
        futures.add(PokeApiService.getMoveDetail(i.toString()));
      }
      final results = await Future.wait(futures.map((f) => f.catchError((_) => MoveDetail(id: 0, name: ''))));
      _allMoves = results.where((m) => m.id > 0).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      _allMoves = [];
    }
    _loadingAllMoves = false;
  }

  void _onSearch(String query) {
    if (query.length < 2 || _allMoves == null) {
      setState(() { _suggestions = null; _showDropdown = false; });
      return;
    }
    final q = query.toLowerCase();
    final matches = _allMoves!.where((m) =>
      m.name.contains(q) || m.displayName.toLowerCase().contains(q)
    ).take(8).toList();
    setState(() { _suggestions = matches; _showDropdown = matches.isNotEmpty; });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Icon(Icons.flash_on_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 6),
          Text('Move:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search moves...',
                      hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                    ),
                    onChanged: _onSearch,
                  ),
                ),
                if (_showDropdown && _suggestions != null && _suggestions!.isNotEmpty)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _suggestions!.length,
                          itemBuilder: (_, i) {
                            final move = _suggestions![i];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: move.type != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: TypeColors.getColor(move.type!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      move.type!.substring(0, 3).toUpperCase(),
                                      style: TextStyle(color: TypeColors.getTextColor(move.type!), fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  )
                                : null,
                              title: Text(move.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                [
                                  if (move.power != null) 'Pow: ${move.power}',
                                  if (move.damageClass != null) move.damageClass!,
                                ].join(' · '),
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                              ),
                              onTap: () {
                                _controller.clear();
                                setState(() { _suggestions = null; _showDropdown = false; });
                                _focusNode.unfocus();
                                widget.onMoveSelected(move.name);
                              },
                            );
                          },
                        ),
                      ),
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
