import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Filter state — all synced from URL
  int _selectedGen = 0;
  Set<String> _filterTypes = {};
  String _sortBy = 'number'; // number, name, bst
  String _searchQuery = '';

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
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type'];
    final typesParam = typeParam != null
        ? typeParam.split(',').where((t) => t.isNotEmpty).toSet()
        : <String>{};
    final genRaw = int.tryParse(uri.queryParameters['gen'] ?? '') ?? 0;
    final genParam = _genRanges.containsKey(genRaw) ? genRaw : 0;
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
    if (!_setEquals(typesParam, _filterTypes)) {
      _filterTypes = typesParam;
      needsReload = true;
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void _navigate({int? gen, Set<String>? types, String? sort, bool clearTypes = false}) {
    final g = gen ?? _selectedGen;
    final t = clearTypes ? <String>{} : (types ?? _filterTypes);
    final s = sort ?? _sortBy;
    final params = <String>[];
    if (g != 0) params.add('gen=$g');
    if (t.isNotEmpty) params.add('type=${t.join(',')}');
    if (s != 'number') params.add('sort=$s');
    context.go(params.isEmpty ? '/' : '/?${params.join('&')}');
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedGen != 0) count++;
    count += _filterTypes.length;
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

      // Always load first batch immediately
      await _loadBatch(range);
      _sortEntries();

      if (mounted) setState(() => _loading = false);

      // Stream in the rest in the background
      if (_offset < _total) {
        _loadRemainingInBackground(range);
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadRemainingInBackground(List<int> range) async {
    while (_offset < _total && mounted) {
      try {
        await _loadBatch(range);
        _sortEntries();
        if (mounted) setState(() {}); // Update UI with new entries
      } catch (e) {
        // Silently fail background loads, don't disrupt UX
        break;
      }
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

      if (_filterTypes.isNotEmpty && types != null && !_filterTypes.every((ft) => types.contains(ft))) {
        continue;
      }

      final bst = d?.stats.values.fold<int>(0, (sum, v) => sum + v) ?? 0;
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

  List<_PokemonEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    return _entries.where((entry) {
      final name = entry.basic.name.toLowerCase();
      final id = entry.basic.id.toString();
      return name.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final baseColumns = screenWidth > 1200
        ? 7
        : screenWidth > 900
            ? 5
            : screenWidth > 600
                ? 4
                : 3;
    // Continuous zoom: dynamic columns and aspect ratio based on scale
    final scale = AppState().cardScale;

    // Column count: 20 at tiny, 2-3 at huge
    final crossAxisCount = scale < 0.2
        ? (baseColumns / 0.15).round().clamp(15, 25)  // Tiny: 15-20+ columns
        : scale < 0.4
            ? (baseColumns / 0.3).round().clamp(10, 15)  // Small: 10-12 columns
            : scale < 0.6
                ? (baseColumns / 0.5).round().clamp(6, 10)  // Medium: 6-8 columns
                : scale < 0.8
                    ? (baseColumns / 0.7).round().clamp(4, 6)  // Large: 4-5 columns
                    : (baseColumns / 1.0).round().clamp(2, 4);  // Huge: 2-3 columns

    // Aspect ratio: smooth progression from square to tall showcase
    final aspectRatio = scale < 0.2
        ? 1.0  // Square icons
        : scale < 0.4
            ? 0.95  // Nearly square
            : scale < 0.6
                ? 0.90  // Slight rectangle
                : scale < 0.8
                    ? 0.85  // Standard card
                    : 0.75;  // Tall showcase

    // Spacing: tighter at small sizes, generous at large
    final spacing = scale < 0.2 ? 6.0 : scale < 0.4 ? 10.0 : scale < 0.6 ? 14.0 : scale < 0.8 ? 16.0 : 20.0;

    return Scaffold(
      body: _loading
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
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Auto-hiding header with title and filters
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      expandedHeight: _filtersExpanded ? null : 240,
                      collapsedHeight: 240,
                      toolbarHeight: 240,
                      backgroundColor: isDark ? const Color(0xFF121218) : const Color(0xFFF8F9FA),
                      surfaceTintColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                  if (_filteredEntries.isNotEmpty && !_loading)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${_filteredEntries.length}',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Search bar
                              TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search by name or number...',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: colorScheme.onSurface.withOpacity(0.4),
                                    size: 22,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              // Continuous zoom slider - smooth scale from tiny icons to huge showcase
                              ListenableBuilder(
                                listenable: AppState(),
                                builder: (context, _) {
                                  final scale = AppState().cardScale;
                                  // Descriptive labels for zoom level
                                  String viewMode = scale < 0.15
                                      ? 'Tiny'
                                      : scale < 0.35
                                          ? 'Small'
                                          : scale < 0.55
                                              ? 'Medium'
                                              : scale < 0.75
                                                  ? 'Large'
                                                  : 'Huge';
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.view_list_rounded,
                                            size: 16,
                                            color: colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            viewMode,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface.withOpacity(0.6),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Expanded(
                                            child: Slider(
                                              value: scale,
                                              min: 0.0,
                                              max: 1.0,
                                              onChanged: (value) => AppState().setCardScale(value),
                                            ),
                                          ),
                                          Icon(
                                            Icons.fullscreen_rounded,
                                            size: 16,
                                            color: colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
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
                    for (final type in _filterTypes)
                      _ActiveFilter(
                        label: type[0].toUpperCase() + type.substring(1),
                        color: TypeColors.getColor(type),
                        textColor: TypeColors.getTextColor(type),
                        onRemove: () {
                          final updated = Set<String>.from(_filterTypes)..remove(type);
                          _navigate(types: updated);
                        },
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
                    filterTypes: _filterTypes,
                    sortBy: _sortBy,
                    onGenSelected: (gen) => _navigate(gen: gen),
                    onTypeToggled: (type) {
                      final updated = Set<String>.from(_filterTypes);
                      if (updated.contains(type)) {
                        updated.remove(type);
                      } else {
                        updated.add(type);
                      }
                      _navigate(types: updated);
                    },
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
                      ),
                    ),
                    // Empty state or grid
                    if (_filteredEntries.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No Pokemon match "$_searchQuery"'
                                    : 'No Pokemon match these filters',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_searchQuery.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => _searchController.clear(),
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  label: const Text('Clear search'),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () => context.go('/'),
                                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                                  label: const Text('Clear filters'),
                                ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Continuous zoom: always cards, scale dynamically
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: aspectRatio,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                          ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = _filteredEntries[index];
                                return PokemonCard(
                                  pokemon: entry.basic,
                                  types: entry.types,
                                  onTap: () => context.go('/pokemon/${entry.basic.id}'),
                                );
                              },
                              childCount: _filteredEntries.length,
                            ),
                          ),
                        ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: _offset >= _total && _filteredEntries.isNotEmpty
                                      ? Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _searchQuery.isNotEmpty
                                                  ? '${_filteredEntries.length} results'
                                                  : 'All ${_filteredEntries.length} Pokemon loaded',
                                              style: TextStyle(
                                                color: colorScheme.onSurface.withOpacity(0.4),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                      : _offset < _total
                                          ? Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 16, height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: colorScheme.primary.withOpacity(0.5),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'Loading ${_entries.length}/$_total...',
                                                    style: TextStyle(
                                                      color: colorScheme.onSurface.withOpacity(0.3),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                ),
                              ),
                            ],
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
                    Flexible(
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
                    const SizedBox(width: 8),
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
  final Set<String> filterTypes;
  final String sortBy;
  final ValueChanged<int> onGenSelected;
  final ValueChanged<String> onTypeToggled;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onClearAll;

  const _FilterPanel({
    required this.selectedGen,
    required this.filterTypes,
    required this.sortBy,
    required this.onGenSelected,
    required this.onTypeToggled,
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
              if (selectedGen != 0 || filterTypes.isNotEmpty)
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
                  selected: filterTypes.contains(type),
                  onTap: () => onTypeToggled(type),
                ),
            ],
          ),
        ],
      ),
    );
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

// --- View mode toggle button ---

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- List tile for compact list view ---

// Removed _PokemonListTile - now using continuous zoom with PokemonCard at all scales
