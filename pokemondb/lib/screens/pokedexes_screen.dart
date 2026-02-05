import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game.dart';
import '../services/pokeapi_service.dart';

class PokedexesScreen extends StatefulWidget {
  const PokedexesScreen({super.key});

  @override
  State<PokedexesScreen> createState() => _PokedexesScreenState();
}

class _PokedexesScreenState extends State<PokedexesScreen> {
  List<PokedexBasic> _pokedexes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPokedexes();
  }

  Future<void> _loadPokedexes() async {
    try {
      final pokedexes = await PokeApiService.getPokedexList();
      // Filter to main series Pokedexes (the important ones)
      final mainPokedexes = pokedexes.where((p) {
        return p.name == 'national' ||
            p.name.contains('kanto') ||
            p.name.contains('johto') ||
            p.name.contains('hoenn') ||
            p.name.contains('sinnoh') ||
            p.name.contains('unova') ||
            p.name.contains('kalos') ||
            p.name.contains('alola') ||
            p.name.contains('galar') ||
            p.name.contains('hisui') ||
            p.name.contains('paldea') ||
            p.name.contains('kitakami') ||
            p.name.contains('blueberry');
      }).toList();

      if (mounted) {
        setState(() {
          _pokedexes = mainPokedexes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Pokédexes'),
            centerTitle: false,
          ),
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else if (_pokedexes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No Pokédexes found',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 1000
                      ? 3
                      : screenWidth > 700
                          ? 2
                          : 1,
                  childAspectRatio: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pokedex = _pokedexes[index];
                    return _PokedexCard(pokedex: pokedex);
                  },
                  childCount: _pokedexes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PokedexCard extends StatefulWidget {
  final PokedexBasic pokedex;

  const _PokedexCard({required this.pokedex});

  @override
  State<_PokedexCard> createState() => _PokedexCardState();
}

class _PokedexCardState extends State<_PokedexCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/pokedexes/${widget.pokedex.name}'),
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
              Icons.menu_book_outlined,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            title: Text(
              widget.pokedex.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
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
    );
  }
}
