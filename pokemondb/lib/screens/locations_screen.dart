import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/location.dart';
import '../services/pokeapi_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<LocationBasic> _allLocations = [];
  List<LocationBasic> _filteredLocations = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await PokeApiService.getAllLocationsBasic();
      if (mounted) {
        setState(() {
          _allLocations = locations;
          _filteredLocations = locations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterLocations() {
    setState(() {
      _filteredLocations = _allLocations.where((location) {
        if (_searchQuery.isNotEmpty &&
            !location.name.contains(_searchQuery.toLowerCase()) &&
            !location.displayName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Locations'),
            centerTitle: false,
          ),
          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterLocations();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_filteredLocations.length} locations',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Locations list
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else if (_filteredLocations.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No locations found',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final location = _filteredLocations[index];
                    return _LocationListItem(location: location);
                  },
                  childCount: _filteredLocations.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationListItem extends StatefulWidget {
  final LocationBasic location;

  const _LocationListItem({required this.location});

  @override
  State<_LocationListItem> createState() => _LocationListItemState();
}

class _LocationListItemState extends State<_LocationListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/locations/${widget.location.name}'),
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
            ),
            child: ListTile(
              leading: Icon(
                Icons.location_on_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                widget.location.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
