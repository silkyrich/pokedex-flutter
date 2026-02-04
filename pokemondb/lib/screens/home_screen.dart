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

  // Filter state — all synced from URL
  int _selectedGen = 0;
  String? _filterType;
  String? _filterMove;
  String? _filterMoveDisplay;
  Set<int>? _moveFilterIds;
  bool _loadingMoveFilter = false;
  String _sortBy = 'number'; // number, name, bst

  // UI state
  bool _filtersExpanded = false;

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
    final genParam = int.tryParse(uri.queryParameters['gen'] ?? '') ?? 0;
    final sortParam = uri.queryParameters['sort'] ?? 'number';

    bool needsReload = false;

    if (genParam != _selectedGen) {
      _selectedGen = genParam;
      needsReload = true;
    }
    if (sortParam != _sortBy) {
      _sortBy = sortParam;
      if (!needsReload && _entries.isNotEmpty) {
        // If all entries are already loaded, just re-sort in place
        if (_offset >= _total) {
          _sortEntries();
          setState(() {});
          return;
        }
        // Switching to name/bst from partial number load needs full reload
        needsReload = true;
      }
    }
    if (typeParam != _filterType) {
      _filterType = typeParam;
      needsReload = true;
    }
    if (moveParam != _filterMove) {
      _filterMove = moveParam;
      if (moveParam != null) {
        _loadMoveFilter(moveParam);
        return;
      } else {
        _moveFilterIds = null;
        _filterMoveDisplay = null;
        needsReload = true;
      }
    }

    if (needsReload) {
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

  void _navigate({int? gen, String? type, String? move, String? sort, bool clearType = false, bool clearMove = false}) {
    final g = gen ?? _selectedGen;
    final t = clearType ? null : (type ?? _filterType);
    final m = clearMove ? null : (move ?? _filterMove);
    final s = sort ?? _sortBy;
    final params = <String>[];
    if (g != 0) params.add('gen=$g');
    if (t != null) params.add('type=$t');
    if (m != null) params.add('move=$m');
    if (s != 'number') params.add('sort=$s');
    context.go(params.isEmpty ? '/' : '/?${params.join('&')}');
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedGen != 0) count++;
    if (_filterType != null) count++;
    if (_filterMove != null) count++;
    return count;
  }

  void _onScroll() {
    if (!_loadingMore &&
        _offset < _total &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  bool get _needsFullLoad => _sortBy != 'number';

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

      if (_needsFullLoad) {
        // Load everything before sorting so the order is correct
        while (_offset < _total) {
          await _loadBatch(range);
          // Show progress for large loads
          if (mounted && _entries.length % 100 == 0) setState(() {});
        }
      } else {
        await _loadBatch(range);
      }

      _sortEntries();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _offset >= _total || _needsFullLoad) return;
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

      if (_filterType != null && types != null && !types.contains(_filterType)) {
        continue;
      }
      if (_moveFilterIds != null && !_moveFilterIds!.contains(id)) {
        continue;
      }

      final bst = d?.stats.fold<int>(0, (sum, s) => sum + s.baseStat) ?? 0;
      _entries.add(_PokemonEntry(
        basic: PokemonBasic(id: id, name: d?.name ?? 'pokemon-$id', url: ''),
        types: types,
        bst: bst,
      ));
    }

    _offset += count;
  }

  void _sortEntries() {
    switch (_sortBy) {
      case 'name':
        _entries.sort((a, b) => a.basic.name.compareTo(b.basic.name));
        break;
      case 'bst':
        _entries.sort((a, b) => b.bst.compareTo(a.bst));
        break;
      case 'number':
      default:
        _entries.sort((a, b) => a.basic.id.compareTo(b.basic.id));
        break;
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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
          // Compact header + filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pokédex',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (_entries.isNotEmpty && !_loading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_entries.length}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter bar
                _FilterBar(
                  activeFilterCount: _activeFilterCount,
                  sortBy: _sortBy,
                  expanded: _filtersExpanded,
                  onToggle: () => setState(() => _filtersExpanded = !_filtersExpanded),
                  activeFilters: [
                    if (_selectedGen != 0)
                      _ActiveFilter(
                        label: 'Gen $_selectedGen',
                        color: colorScheme.primary,
                        onRemove: () => _navigate(gen: 0),
                      ),
                    if (_filterType != null)
                      _ActiveFilter(
                        label: _filterType![0].toUpperCase() + _filterType!.substring(1),
                        color: TypeColors.getColor(_filterType!),
                        textColor: TypeColors.getTextColor(_filterType!),
                        onRemove: () => _navigate(clearType: true),
                      ),
                    if (_filterMove != null)
                      _ActiveFilter(
                        label: _filterMoveDisplay ?? _filterMove!,
                        color: colorScheme.tertiary,
                        icon: Icons.flash_on_rounded,
                        onRemove: () => _navigate(clearMove: true),
                      ),
                  ],
                ),
                // Expandable filter panel
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _filtersExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: _FilterPanel(
                    selectedGen: _selectedGen,
                    filterType: _filterType,
                    filterMove: _filterMove,
                    sortBy: _sortBy,
                    loadingMoveFilter: _loadingMoveFilter,
                    onGenSelected: (gen) => _navigate(gen: gen),
                    onTypeSelected: (type) {
                      if (_filterType == type) {
                        _navigate(clearType: true);
                      } else {
                        _navigate(type: type);
                      }
                    },
                    onMoveSelected: (move) => _navigate(move: move),
                    onMoveClear: () => _navigate(clearMove: true),
                    onSortChanged: (sort) => _navigate(sort: sort),
                    onClearAll: () {
                      context.go('/');
                    },
                  ),
                ),
                const SizedBox(height: 12),
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
                          width: 48, height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _needsFullLoad && _entries.isNotEmpty
                              ? 'Loading all Pokemon for sorting... ${_entries.length}/$_total'
                              : 'Loading Pokemon...',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
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
                            Text('Something went wrong', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
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
                    : _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onSurface.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  'No Pokemon match these filters',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () => context.go('/'),
                                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                                  label: const Text('Clear filters'),
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
                                                width: 20, height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Loading more...',
                                                style: TextStyle(
                                                  color: colorScheme.onSurface.withOpacity(0.4),
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
                                                  color: colorScheme.primary.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'All ${_entries.length} Pokemon loaded',
                                                  style: TextStyle(
                                                    color: colorScheme.onSurface.withOpacity(0.4),
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

// --- Data ---

class _PokemonEntry {
  final PokemonBasic basic;
  final List<String>? types;
  final int bst;

  _PokemonEntry({required this.basic, this.types, this.bst = 0});
}

class _ActiveFilter {
  final String label;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback onRemove;

  const _ActiveFilter({
    required this.label,
    required this.color,
    this.textColor,
    this.icon,
    required this.onRemove,
  });
}

// --- Filter Bar (always visible, compact) ---

class _FilterBar extends StatelessWidget {
  final int activeFilterCount;
  final String sortBy;
  final bool expanded;
  final VoidCallback onToggle;
  final List<_ActiveFilter> activeFilters;

  const _FilterBar({
    required this.activeFilterCount,
    required this.sortBy,
    required this.expanded,
    required this.onToggle,
    required this.activeFilters,
  });

  String get _sortLabel {
    switch (sortBy) {
      case 'name': return 'A-Z';
      case 'bst': return 'BST';
      default: return '#';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Main filter toggle row
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(expanded ? 0.08 : 0.04)
                    : Colors.grey.withOpacity(expanded ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(expanded ? 0.15 : 0.06)
                      : Colors.grey.withOpacity(expanded ? 0.25 : 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                    size: 18,
                    color: activeFilterCount > 0
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  // Active filter chips inline
                  if (activeFilters.isNotEmpty && !expanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: activeFilters.map((f) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: f.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (f.icon != null) ...[
                                    Icon(f.icon, size: 12, color: f.textColor ?? f.color),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    f.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: f.textColor ?? f.color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: f.onRemove,
                                    child: Icon(Icons.close, size: 12, color: f.textColor ?? f.color),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  // Sort indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Expandable Filter Panel ---

class _FilterPanel extends StatelessWidget {
  final int selectedGen;
  final String? filterType;
  final String? filterMove;
  final String sortBy;
  final bool loadingMoveFilter;
  final ValueChanged<int> onGenSelected;
  final ValueChanged<String> onTypeSelected;
  final ValueChanged<String> onMoveSelected;
  final VoidCallback onMoveClear;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onClearAll;

  const _FilterPanel({
    required this.selectedGen,
    required this.filterType,
    required this.filterMove,
    required this.sortBy,
    required this.loadingMoveFilter,
    required this.onGenSelected,
    required this.onTypeSelected,
    required this.onMoveSelected,
    required this.onMoveClear,
    required this.onSortChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort row
          Row(
            children: [
              _SectionLabel(label: 'Sort by'),
              const SizedBox(width: 12),
              _SortChip(label: '#  Number', value: 'number', current: sortBy, onTap: () => onSortChanged('number')),
              const SizedBox(width: 6),
              _SortChip(label: 'A-Z  Name', value: 'name', current: sortBy, onTap: () => onSortChanged('name')),
              const SizedBox(width: 6),
              _SortChip(label: 'BST', value: 'bst', current: sortBy, onTap: () => onSortChanged('bst')),
              const Spacer(),
              if (selectedGen != 0 || filterType != null || filterMove != null)
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: Icon(Icons.clear_all_rounded, size: 16, color: colorScheme.error),
                  label: Text('Clear all', style: TextStyle(fontSize: 12, color: colorScheme.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Generation
          _SectionLabel(label: 'Generation'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FilterChip(
                label: 'All',
                selected: selectedGen == 0,
                onTap: () => onGenSelected(0),
              ),
              for (int i = 1; i <= 9; i++)
                _FilterChip(
                  label: '$i',
                  selected: selectedGen == i,
                  onTap: () => onGenSelected(i),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Type
          _SectionLabel(label: 'Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in TypeChart.types)
                _TypeChip(
                  type: type,
                  selected: filterType == type,
                  onTap: () => onTypeSelected(type),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Move filter
          Row(
            children: [
              _SectionLabel(label: 'Learns move'),
              if (loadingMoveFilter) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ],
              if (filterMove != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on_rounded, size: 12, color: colorScheme.tertiary),
                      const SizedBox(width: 3),
                      Text(
                        _filterMoveDisplayName ?? filterMove!,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.tertiary),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onMoveClear,
                        child: Icon(Icons.close, size: 12, color: colorScheme.tertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _MoveFilterSearch(
            currentMove: filterMove,
            onMoveSelected: onMoveSelected,
          ),
        ],
      ),
    );
  }

  String? get _filterMoveDisplayName {
    if (filterMove == null) return null;
    return filterMove!.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}

// --- Small widgets ---

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withOpacity(0.15)
                : isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
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
              color: selected ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = TypeColors.getColor(type);
    final textColor = TypeColors.getTextColor(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? typeColor
                : isDark
                    ? typeColor.withOpacity(0.12)
                    : typeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? typeColor : typeColor.withOpacity(isDark ? 0.3 : 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(Icons.check_rounded, size: 12, color: textColor),
                ),
              Text(
                type[0].toUpperCase() + type.substring(1),
                style: TextStyle(
                  color: selected ? textColor : isDark ? typeColor : typeColor.withOpacity(0.9),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Move search (reused from before, cleaned up) ---

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
  bool _showDropdown = false;

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
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search moves...',
              hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              prefixIcon: const Icon(Icons.search, size: 18),
              prefixIconConstraints: const BoxConstraints(minWidth: 36),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            ),
            onChanged: _onSearch,
          ),
          if (_showDropdown && _suggestions != null && _suggestions!.isNotEmpty)
            Positioned(
              top: 42,
              left: 0,
              right: 0,
              child: Material(
                elevation: 8,
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
    );
  }
}
