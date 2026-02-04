import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/type_badge.dart';
import '../widgets/stat_bar.dart';
import '../widgets/stat_radar_chart.dart';
import '../utils/type_colors.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailScreen({super.key, required this.pokemonId});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen>
    with TickerProviderStateMixin {
  PokemonDetail? _pokemon;
  PokemonSpecies? _species;
  List<EvolutionInfo>? _evolutions;
  bool _loading = true;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void didUpdateWidget(PokemonDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.pokemonId != widget.pokemonId) {
      _fadeController.reset();
      _loadData();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        PokeApiService.getPokemonDetail(widget.pokemonId),
        PokeApiService.getPokemonSpecies(widget.pokemonId),
      ]);

      final detail = results[0] as PokemonDetail;
      final species = results[1] as PokemonSpecies;

      List<EvolutionInfo>? evolutions;
      if (species.evolutionChainId != null) {
        try {
          evolutions = await PokeApiService.getEvolutionChain(
              species.evolutionChainId!);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _pokemon = detail;
          _species = species;
          _evolutions = evolutions;
          _loading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: _loading
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
                const SizedBox(height: 16),
                Text('Loading Pokémon #${widget.pokemonId}...',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5))),
              ],
            ))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                          'Failed to load Pokémon #${widget.pokemonId}'),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _loadData,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(context),
                ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = _pokemon!;
    final isWide = MediaQuery.of(context).size.width > 800;
    final colorScheme = Theme.of(context).colorScheme;
    final appState = AppState();
    final primaryType = p.types.first.name;
    final typeColor = TypeColors.getColor(primaryType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nav + actions
              Row(
                children: [
                  if (widget.pokemonId > 1)
                    _NavChip(
                      label: '#${widget.pokemonId - 1}',
                      icon: Icons.chevron_left,
                      iconLeft: true,
                      onTap: () => context
                          .go('/pokemon/${widget.pokemonId - 1}'),
                    ),
                  const Spacer(),
                  // Favorite button
                  ListenableBuilder(
                    listenable: appState,
                    builder: (context, _) => _ActionButton(
                      icon: appState.isFavorite(widget.pokemonId)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: appState.isFavorite(widget.pokemonId)
                          ? Colors.red
                          : null,
                      tooltip: appState.isFavorite(widget.pokemonId)
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      onTap: () =>
                          appState.toggleFavorite(widget.pokemonId),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Team button
                  ListenableBuilder(
                    listenable: appState,
                    builder: (context, _) => _ActionButton(
                      icon: appState.isOnTeam(widget.pokemonId)
                          ? Icons.groups_rounded
                          : Icons.group_add_outlined,
                      color: appState.isOnTeam(widget.pokemonId)
                          ? colorScheme.primary
                          : null,
                      tooltip: appState.isOnTeam(widget.pokemonId)
                          ? 'Remove from team'
                          : 'Add to team',
                      onTap: () {
                        if (!appState.isOnTeam(widget.pokemonId) &&
                            appState.teamFull) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Team is full (max 6)'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
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
                    icon: Icons.chevron_right,
                    iconLeft: false,
                    onTap: () => context
                        .go('/pokemon/${widget.pokemonId + 1}'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title with type accent
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              p.idString,
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface
                                    .withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_species?.genus != null) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _species!.genus!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: typeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Main layout
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 2, child: _buildImageSection(p)),
                    const SizedBox(width: 24),
                    Expanded(
                        flex: 3, child: _buildInfoSection(p)),
                  ],
                )
              else
                Column(children: [
                  _buildImageSection(p),
                  const SizedBox(height: 16),
                  _buildInfoSection(p),
                ]),
              const SizedBox(height: 24),
              _buildStatsSection(p, isWide),
              const SizedBox(height: 24),
              if (_evolutions != null &&
                  _evolutions!.length > 1) ...[
                _buildEvolutionSection(),
                const SizedBox(height: 24),
              ],
              _buildTypeDefensesSection(p),
              const SizedBox(height: 24),
              _buildMovesSection(p),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(PokemonDetail p) {
    final primaryType = p.types.first.name;
    final typeColor = TypeColors.getColor(primaryType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withOpacity(isDark ? 0.2 : 0.15),
            typeColor.withOpacity(isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: typeColor.withOpacity(0.2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pokeball watermark
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.catching_pokemon,
              size: 180,
              color: typeColor.withOpacity(0.06),
            ),
          ),
          Center(
            child: Hero(
              tag: 'pokemon-${p.id}',
              child: Image.network(
                p.imageUrl,
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.catching_pokemon,
                    size: 120,
                    color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(PokemonDetail p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_species?.flavorText != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  _species!.flavorText!,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _infoTable([
              [
                'Height',
                '${p.heightInMeters} m (${(p.heightInMeters * 3.281).toStringAsFixed(1)} ft)'
              ],
              [
                'Weight',
                '${p.weightInKg} kg (${(p.weightInKg * 2.205).toStringAsFixed(1)} lbs)'
              ],
              [
                'Abilities',
                p.abilities
                    .map((a) =>
                        '${a.displayName}${a.isHidden ? ' (hidden)' : ''}')
                    .join(', ')
              ],
              if (p.baseExperience > 0)
                ['Base Exp', '${p.baseExperience}'],
            ]),
            const SizedBox(height: 14),
            const Text('Type',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: p.types
                  .map((t) => TypeBadge(
                      type: t.name, large: true, fontSize: 14))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTable(List<List<String>> rows) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth()
      },
      children: rows
          .map((row) => TableRow(children: [
                Padding(
                  padding:
                      const EdgeInsets.only(right: 16, bottom: 10),
                  child: Text(row[0],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(row[1],
                      style: const TextStyle(fontSize: 14)),
                ),
              ]))
          .toList(),
    );
  }

  Widget _buildStatsSection(PokemonDetail p, bool isWide) {
    final statOrder = [
      'hp',
      'attack',
      'defense',
      'special-attack',
      'special-defense',
      'speed'
    ];
    final total = p.stats.values.fold<int>(0, (a, b) => a + b);
    final primaryType = p.types.first.name;
    final typeColor = TypeColors.getColor(primaryType);

    return _sectionCard(
      'Base Stats',
      Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radar chart
                StatRadarChart(
                  stats: p.stats,
                  imageUrl: p.imageUrl,
                  fillColor: typeColor,
                  borderColor: typeColor,
                  size: 260,
                ),
                const SizedBox(width: 24),
                // Bar stats
                Expanded(
                  child: Column(
                    children: [
                      ...statOrder.map((s) => StatBar(
                          label: s,
                          value: p.stats[s] ?? 0)),
                      const Divider(height: 20),
                      _totalRow(total),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            Center(
              child: StatRadarChart(
                stats: p.stats,
                imageUrl: p.imageUrl,
                fillColor: typeColor,
                borderColor: typeColor,
                size: 240,
              ),
            ),
            const SizedBox(height: 20),
            ...statOrder.map((s) =>
                StatBar(label: s, value: p.stats[s] ?? 0)),
            const Divider(height: 20),
            _totalRow(total),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(int total) {
    final color = total < 300
        ? const Color(0xFFF34444)
        : total < 400
            ? const Color(0xFFFF7F0F)
            : total < 500
                ? const Color(0xFFFFDD57)
                : total < 550
                    ? const Color(0xFFA0E515)
                    : const Color(0xFF23CD5E);

    return Row(children: [
      const SizedBox(
          width: 80,
          child: Text('Total',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14))),
      SizedBox(
        width: 40,
        child: Text(
          '$total',
          textAlign: TextAlign.right,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color),
        ),
      ),
    ]);
  }

  Widget _buildEvolutionSection() {
    return _sectionCard(
        'Evolution Chain',
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _evolutions!.length; i++) ...[
              if (i > 0)
                Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            size: 18),
                      ),
                      if (_evolutions![i]
                          .displayTrigger
                          .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              _evolutions![i].displayTrigger,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
              _EvolutionTile(
                evo: _evolutions![i],
                isCurrentPokemon:
                    _evolutions![i].id == widget.pokemonId,
                onTap: () =>
                    context.go('/pokemon/${_evolutions![i].id}'),
              ),
            ],
          ],
        ));
  }

  Widget _buildTypeDefensesSection(PokemonDetail p) {
    final typeNames = p.types.map((t) => t.name).toList();
    final Map<String, double> defenses = {};
    for (final attackType in TypeChart.types) {
      double mult = 1;
      for (final defType in typeNames) {
        mult *= TypeChart.getEffectiveness(attackType, defType);
      }
      defenses[attackType] = mult;
    }

    final weak = defenses.entries.where((e) => e.value > 1).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final resist = defenses.entries
        .where((e) => e.value > 0 && e.value < 1)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final immune =
        defenses.entries.where((e) => e.value == 0).toList();

    return _sectionCard(
        'Type Defenses',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'The effectiveness of each type on ${_pokemon!.displayName}.',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6))),
            const SizedBox(height: 12),
            if (weak.isNotEmpty) _defenseGroup('Weak to:', weak),
            if (resist.isNotEmpty)
              _defenseGroup('Resistant to:', resist),
            if (immune.isNotEmpty)
              _defenseGroup('Immune to:', immune),
          ],
        ));
  }

  Widget _defenseGroup(
      String label, List<MapEntry<String, double>> entries) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entries
                    .map((e) => _DefenseBadge(
                        type: e.key, multiplier: e.value))
                    .toList()),
          ]),
    );
  }

  Widget _buildMovesSection(PokemonDetail p) {
    final levelMoves = p.moves
        .where((m) => m.learnMethod == 'level-up')
        .toList()
      ..sort(
          (a, b) => a.levelLearnedAt.compareTo(b.levelLearnedAt));
    final tmMoves = p.moves
        .where((m) => m.learnMethod == 'machine')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final eggMoves =
        p.moves.where((m) => m.learnMethod == 'egg').toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return _sectionCard(
        'Moves',
        DefaultTabController(
          length: 3,
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                labelColor:
                    Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5),
                indicatorColor:
                    Theme.of(context).colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Level Up (${levelMoves.length})'),
                  Tab(text: 'TM/HM (${tmMoves.length})'),
                  Tab(text: 'Egg (${eggMoves.length})'),
                ],
              ),
            ),
            SizedBox(
              height:
                  (levelMoves.length.clamp(1, 20) * 40.0) + 50,
              child: TabBarView(children: [
                _moveList(levelMoves, showLevel: true),
                _moveList(tmMoves),
                _moveList(eggMoves),
              ]),
            ),
          ]),
        ));
  }

  Widget _moveList(List<PokemonMove> moves,
      {bool showLevel = false}) {
    if (moves.isEmpty) {
      return Center(
          child: Text('No moves',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4))));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: moves.length.clamp(0, 20),
      itemBuilder: (context, index) {
        final m = moves[index];
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
            color: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
          ))),
          child: Row(children: [
            if (showLevel)
              SizedBox(
                  width: 44,
                  child: Text(
                    m.levelLearnedAt > 0
                        ? 'Lv${m.levelLearnedAt}'
                        : '-',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                        fontWeight: FontWeight.w600),
                  )),
            Expanded(
                child: Text(m.displayName,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        fontSize: 14))),
          ]),
        );
      },
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ]),
      ),
    );
  }
}

class _NavChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool iconLeft;
  final VoidCallback onTap;

  const _NavChip(
      {required this.label,
      required this.icon,
      required this.iconLeft,
      required this.onTap});

  @override
  State<_NavChip> createState() => _NavChipState();
}

class _NavChipState extends State<_NavChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? colorScheme.primary.withOpacity(0.3)
                  : colorScheme.onSurface.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.iconLeft)
                Icon(widget.icon,
                    size: 16, color: colorScheme.primary),
              Text(widget.label,
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              if (!widget.iconLeft)
                Icon(widget.icon,
                    size: 16, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon,
      this.color,
      required this.tooltip,
      required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onTap();
        },
        onTapCancel: () => _controller.forward(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _controller.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color?.withOpacity(0.1) ??
                    Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon,
                  color: widget.color ??
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5)),
            ),
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

  const _EvolutionTile(
      {required this.evo,
      required this.isCurrentPokemon,
      required this.onTap});

  @override
  State<_EvolutionTile> createState() => _EvolutionTileState();
}

class _EvolutionTileState extends State<_EvolutionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isCurrentPokemon
                ? colorScheme.primary.withOpacity(0.1)
                : _hovered
                    ? colorScheme.primary.withOpacity(0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: widget.isCurrentPokemon
                ? Border.all(
                    color: colorScheme.primary, width: 2)
                : null,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary
                          .withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${widget.evo.id}.png',
                  width: 68,
                  height: 68,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.catching_pokemon, size: 40),
                ),
                Text(
                  widget.evo.name[0].toUpperCase() +
                      widget.evo.name.substring(1),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.primary),
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

  const _DefenseBadge(
      {required this.type, required this.multiplier});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: TypeColors.getColor(type),
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8)),
          ),
          child: Text(
              type[0].toUpperCase() + type.substring(1),
              style: TextStyle(
                  color: TypeColors.getTextColor(type),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: multiplier > 1
                ? (isDark
                    ? Colors.red.shade900.withOpacity(0.6)
                    : Colors.red.shade50)
                : multiplier == 0
                    ? (isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200)
                    : (isDark
                        ? Colors.green.shade900
                            .withOpacity(0.6)
                        : Colors.green.shade50),
            borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(8)),
          ),
          child: Text(_label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: multiplier > 1
                    ? (isDark
                        ? Colors.red.shade200
                        : Colors.red.shade700)
                    : multiplier == 0
                        ? (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600)
                        : (isDark
                            ? Colors.green.shade200
                            : Colors.green.shade700),
              )),
        ),
      ]),
    );
  }
}
