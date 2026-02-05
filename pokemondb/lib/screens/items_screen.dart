import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/item.dart';
import '../services/pokeapi_service.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<ItemBasic> _allItems = [];
  List<ItemBasic> _filteredItems = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await PokeApiService.getAllItemsBasic();
      if (mounted) {
        setState(() {
          _allItems = items;
          _filteredItems = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        // Search filter
        if (_searchQuery.isNotEmpty &&
            !item.name.contains(_searchQuery.toLowerCase()) &&
            !item.displayName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        // Category filter (simplified - would need ItemDetail for accurate filtering)
        // For now, we filter by name patterns
        if (_selectedCategory != null) {
          if (_selectedCategory == ItemCategory.evolutionStones &&
              !item.name.contains('stone')) {
            return false;
          }
          if (_selectedCategory == ItemCategory.berries &&
              !item.name.contains('berry')) {
            return false;
          }
          if (_selectedCategory == ItemCategory.machines &&
              !item.name.startsWith('tm') && !item.name.startsWith('hm')) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Items'),
            centerTitle: false,
          ),
          // Search and filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterItems();
                    },
                  ),
                  const SizedBox(height: 16),
                  // Category filter chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = null);
                          _filterItems();
                        },
                      ),
                      FilterChip(
                        label: const Text('Evolution Stones'),
                        selected: _selectedCategory == ItemCategory.evolutionStones,
                        onSelected: (selected) {
                          setState(() =>
                              _selectedCategory = selected ? ItemCategory.evolutionStones : null);
                          _filterItems();
                        },
                      ),
                      FilterChip(
                        label: const Text('Berries'),
                        selected: _selectedCategory == ItemCategory.berries,
                        onSelected: (selected) {
                          setState(() =>
                              _selectedCategory = selected ? ItemCategory.berries : null);
                          _filterItems();
                        },
                      ),
                      FilterChip(
                        label: const Text('TMs & HMs'),
                        selected: _selectedCategory == ItemCategory.machines,
                        onSelected: (selected) {
                          setState(() =>
                              _selectedCategory = selected ? ItemCategory.machines : null);
                          _filterItems();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Results count
                  Text(
                    '${_filteredItems.length} items',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Items grid
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else if (_filteredItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No items found',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 1000
                      ? 6
                      : screenWidth > 700
                          ? 4
                          : 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _filteredItems[index];
                    return _ItemCard(item: item);
                  },
                  childCount: _filteredItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final ItemBasic item;

  const _ItemCard({required this.item});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/items/${widget.item.name}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Item sprite
                Expanded(
                  child: Image.network(
                    widget.item.spriteUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Item name
                Text(
                  widget.item.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
