import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../widgets/type_badge.dart';
import '../widgets/stat_bar.dart';
import '../utils/type_colors.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailScreen({super.key, required this.pokemonId});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  PokemonDetail? _pokemon;
  PokemonSpecies? _species;
  EvolutionInfo? _evoRoot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(PokemonDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.pokemonId != widget.pokemonId) _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });

    try {
      final results = await Future.wait([
        PokeApiService.getPokemonDetail(widget.pokemonId),
        PokeApiService.getPokemonSpecies(widget.pokemonId),
      ]);

      final detail = results[0] as PokemonDetail;
      final species = results[1] as PokemonSpecies;

      EvolutionInfo? evoRoot;
      if (species.evolutionChainId != null) {
        try {
          evoRoot = await PokeApiService.getEvolutionChain(species.evolutionChainId!);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _pokemon = detail;
          _species = species;
          _evoRoot = evoRoot;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading Pokemon #${widget.pokemonId}...',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
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
                      Text('Failed to load Pokemon #${widget.pokemonId}', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = _pokemon!;
    final isWide = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final appState = AppState();
    final primaryType = p.types.first.name;
    final typeColor = TypeColors.getColor(primaryType);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header with gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  typeColor.withOpacity(isDark ? 0.2 : 0.12),
                  typeColor.withOpacity(isDark ? 0.05 : 0.02),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nav row
                      Row(
                        children: [
                          if (widget.pokemonId > 1)
                            _NavChip(
                              label: '#${widget.pokemonId - 1}',
                              icon: Icons.chevron_left_rounded,
                              iconFirst: true,
                              onTap: () => context.go('/pokemon/${widget.pokemonId - 1}'),
                            ),
                          const Spacer(),
                          // Favorite
                          ListenableBuilder(
                            listenable: appState,
                            builder: (context, _) => _ActionChip(
                              icon: appState.isFavorite(widget.pokemonId) ? Icons.favorite : Icons.favorite_border,
                              color: appState.isFavorite(widget.pokemonId) ? Colors.red : null,
                              tooltip: appState.isFavorite(widget.pokemonId) ? 'Remove from favorites' : 'Add to favorites',
                              onTap: () => appState.toggleFavorite(widget.pokemonId),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Team
                          ListenableBuilder(
                            listenable: appState,
                            builder: (context, _) => _ActionChip(
                              icon: appState.isOnTeam(widget.pokemonId) ? Icons.groups : Icons.group_add_outlined,
                              color: appState.isOnTeam(widget.pokemonId) ? colorScheme.primary : null,
                              tooltip: appState.isOnTeam(widget.pokemonId) ? 'Remove from team' : 'Add to team',
                              onTap: () {
                                if (!appState.isOnTeam(widget.pokemonId) && appState.teamFull) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Team is full (max 6)'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                  return;
                                }
                                appState.toggleTeamMember(widget.pokemonId);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          _NavChip(
                            label: '#${widget.pokemonId + 1}',
                            icon: Icons.chevron_right_rounded,
                            iconFirst: false,
                            onTap: () => context.go('/pokemon/${widget.pokemonId + 1}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title area
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Expanded(flex: 2, child: _buildHeroImage(p, typeColor, isDark)),
                            const SizedBox(width: 32),
                            // Info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTitleBlock(p, theme),
                                  const SizedBox(height: 20),
                                  _buildInfoCard(p, theme, isDark),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleBlock(p, theme),
                            const SizedBox(height: 16),
                            _buildHeroImage(p, typeColor, isDark),
                            const SizedBox(height: 16),
                            _buildInfoCard(p, theme, isDark),
                          ],
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Remaining sections
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsSection(p, theme, isDark),
                    const SizedBox(height: 20),
                    if (_evoRoot != null && _evoRoot!.flatten().length > 1) ...[
                      _buildEvolutionSection(theme, isDark),
                      const SizedBox(height: 20),
                    ],
                    _buildTypeDefensesSection(p, theme, isDark),
                    const SizedBox(height: 20),
                    _buildMovesSection(p, theme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBlock(PokemonDetail p, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.idString,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.35),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          p.displayName,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.types.map((t) => TypeBadge(
            type: t.name,
            large: true,
            fontSize: 14,
            navigable: true,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildHeroImage(PokemonDetail p, Color typeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: typeColor.withOpacity(isDark ? 0.15 : 0.1)),
      ),
      child: Center(
        child: Hero(
          tag: 'pokemon-sprite-${p.id}',
          child: Image.network(
            p.imageUrl,
            width: 220,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.catching_pokemon,
              size: 100,
              color: typeColor.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(PokemonDetail p, ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_species?.flavorText != null) ...[
              Text(
                _species!.flavorText!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _infoRow('Species', _species?.genus ?? '—', theme),
            _infoRow('Height', '${p.heightInMeters} m (${(p.heightInMeters * 3.281).toStringAsFixed(1)} ft)', theme),
            _infoRow('Weight', '${p.weightInKg} kg (${(p.weightInKg * 2.205).toStringAsFixed(1)} lbs)', theme),
            _infoRow(
              'Abilities',
              p.abilities.map((a) => '${a.displayName}${a.isHidden ? ' (hidden)' : ''}').join(', '),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(PokemonDetail p, ThemeData theme, bool isDark) {
    final statOrder = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    final total = p.stats.values.fold<int>(0, (a, b) => a + b);

    return _sectionCard('Base Stats', theme, Column(children: [
      ...statOrder.map((s) => StatBar(label: s, value: p.stats[s] ?? 0)),
      Divider(height: 24, color: theme.dividerColor),
      Row(children: [
        SizedBox(
          width: 72,
          child: Text(
            'Total',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '$total',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ]),
    ]));
  }

  Widget _buildEvolutionSection(ThemeData theme, bool isDark) {
    return _sectionCard('Evolution Chain', theme, _buildEvoTree(_evoRoot!, theme, isDark, isRoot: true));
  }

  Widget _buildEvoTree(EvolutionInfo node, ThemeData theme, bool isDark, {bool isRoot = false}) {
    final tile = _EvolutionTile(
      evo: node,
      isCurrentPokemon: node.id == widget.pokemonId,
      onTap: () => context.go('/pokemon/${node.id}'),
    );

    if (node.evolvesTo.isEmpty) return tile;

    final arrow = Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
    ]);

    // Linear chain (single evolution path)
    if (node.evolvesTo.length == 1) {
      final child = node.evolvesTo.first;
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          tile,
          Column(mainAxisSize: MainAxisSize.min, children: [
            arrow,
            if (child.displayTrigger.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  child.displayTrigger,
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
          ]),
          _buildEvoTree(child, theme, isDark),
        ],
      );
    }

    // Branching chain (e.g. Eevee)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        const SizedBox(height: 8),
        Icon(Icons.call_split_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: node.evolvesTo.map((child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (child.displayTrigger.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        child.displayTrigger,
                        style: TextStyle(fontSize: 9, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                _EvolutionTile(
                  evo: child,
                  isCurrentPokemon: child.id == widget.pokemonId,
                  onTap: () => context.go('/pokemon/${child.id}'),
                ),
                // If this branch continues further, show that too
                if (child.evolvesTo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildEvoTree(child, theme, isDark),
                  ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeDefensesSection(PokemonDetail p, ThemeData theme, bool isDark) {
    final typeNames = p.types.map((t) => t.name).toList();
    final Map<String, double> defenses = {};
    for (final attackType in TypeChart.types) {
      double mult = 1;
      for (final defType in typeNames) {
        mult *= TypeChart.getEffectiveness(attackType, defType);
      }
      defenses[attackType] = mult;
    }

    final weak = defenses.entries.where((e) => e.value > 1).toList()..sort((a, b) => b.value.compareTo(a.value));
    final resist = defenses.entries.where((e) => e.value > 0 && e.value < 1).toList()..sort((a, b) => a.value.compareTo(b.value));
    final immune = defenses.entries.where((e) => e.value == 0).toList();

    return _sectionCard('Type Defenses', theme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The effectiveness of each type on ${_pokemon!.displayName}.',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        if (weak.isNotEmpty) _defenseGroup('Weak to', weak, theme),
        if (resist.isNotEmpty) _defenseGroup('Resistant to', resist, theme),
        if (immune.isNotEmpty) _defenseGroup('Immune to', immune, theme),
      ],
    ));
  }

  Widget _defenseGroup(String label, List<MapEntry<String, double>> entries, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: entries.map((e) => _DefenseBadge(type: e.key, multiplier: e.value)).toList()),
      ]),
    );
  }

  Widget _buildMovesSection(PokemonDetail p, ThemeData theme) {
    final levelMoves = p.moves.where((m) => m.learnMethod == 'level-up').toList()
      ..sort((a, b) => a.levelLearnedAt.compareTo(b.levelLearnedAt));
    final tmMoves = p.moves.where((m) => m.learnMethod == 'machine').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final eggMoves = p.moves.where((m) => m.learnMethod == 'egg').toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return _sectionCard('Moves', theme, DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: theme.dividerColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Level Up (${levelMoves.length})'),
            Tab(text: 'TM/HM (${tmMoves.length})'),
            Tab(text: 'Egg (${eggMoves.length})'),
          ],
        ),
        SizedBox(
          height: (levelMoves.length.clamp(1, 20) * 42.0) + 50,
          child: TabBarView(children: [
            _moveList(levelMoves, showLevel: true),
            _moveList(tmMoves),
            _moveList(eggMoves),
          ]),
        ),
      ]),
    ));
  }

  Widget _moveList(List<PokemonMove> moves, {bool showLevel = false}) {
    final theme = Theme.of(context);
    if (moves.isEmpty) {
      return Center(
        child: Text(
          'No moves',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: moves.length.clamp(0, 20),
      itemBuilder: (context, index) {
        final m = moves[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(children: [
            if (showLevel)
              SizedBox(
                width: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.levelLearnedAt > 0 ? 'Lv${m.levelLearnedAt}' : '—',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (showLevel) const SizedBox(width: 8),
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/moves/${m.name}'),
                  child: Text(
                    m.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _sectionCard(String title, ThemeData theme, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconFirst;
  final VoidCallback onTap;

  const _NavChip({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconFirst) Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (!iconFirst) Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.onSurface.withOpacity(0.5);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
              color: color != null ? color!.withOpacity(0.08) : null,
            ),
            child: Icon(icon, size: 20, color: activeColor),
          ),
        ),
      ),
    );
  }
}

class _EvolutionTile extends StatefulWidget {
  final EvolutionInfo evo;
  final bool isCurrentPokemon;
  final VoidCallback onTap;

  const _EvolutionTile({required this.evo, required this.isCurrentPokemon, required this.onTap});

  @override
  State<_EvolutionTile> createState() => _EvolutionTileState();
}

class _EvolutionTileState extends State<_EvolutionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isCurrentPokemon
                ? colorScheme.primary.withOpacity(0.1)
                : _hovered
                    ? colorScheme.primary.withOpacity(0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isCurrentPokemon
                ? Border.all(color: colorScheme.primary, width: 2)
                : _hovered
                    ? Border.all(color: colorScheme.primary.withOpacity(0.3))
                    : null,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.network(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${widget.evo.id}.png',
              width: 68, height: 68,
              errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 40),
            ),
            Text(
              widget.evo.name[0].toUpperCase() + widget.evo.name.substring(1),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: widget.isCurrentPokemon ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DefenseBadge extends StatelessWidget {
  final String type;
  final double multiplier;

  const _DefenseBadge({required this.type, required this.multiplier});

  String get _label {
    if (multiplier == 0) return '0x';
    if (multiplier == 0.25) return '1/4x';
    if (multiplier == 0.5) return '1/2x';
    if (multiplier == 2) return '2x';
    if (multiplier == 4) return '4x';
    return '${multiplier}x';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.go('/?type=$type'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: 'View all ${type[0].toUpperCase()}${type.substring(1)} Pokemon',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TypeColors.getColor(type),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
              child: Text(
                type[0].toUpperCase() + type.substring(1),
                style: TextStyle(color: TypeColors.getTextColor(type), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: multiplier > 1
                    ? Colors.red.withOpacity(isDark ? 0.2 : 0.08)
                    : multiplier == 0
                        ? Colors.grey.withOpacity(isDark ? 0.2 : 0.1)
                        : Colors.green.withOpacity(isDark ? 0.2 : 0.08),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
              ),
              child: Text(
                _label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: multiplier > 1 ? Colors.red : multiplier == 0 ? Colors.grey : Colors.green,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
