import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pokemon.dart';
import '../models/ability.dart';
import '../models/location.dart';
import '../models/game.dart';
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
  int? _activeFormId; // null = default form
  bool _loadingForm = false;

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
        AppState().setActivePokemon(detail);
        setState(() {
          _pokemon = detail;
          _species = species;
          _evoRoot = evoRoot;
          _loading = false;
          _activeFormId = null;
          _loadingForm = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _switchForm(FormVariety form) async {
    if (_activeFormId == form.id) return;
    setState(() { _loadingForm = true; _activeFormId = form.id; });
    try {
      final detail = await PokeApiService.getPokemonDetail(form.id);
      if (mounted) {
        AppState().setActivePokemon(detail);
        setState(() { _pokemon = detail; _loadingForm = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingForm = false);
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
    final secondaryColor = p.types.length > 1
        ? TypeColors.getColor(p.types[1].name)
        : typeColor;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header with type-colored gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  typeColor.withOpacity(isDark ? 0.25 : 0.15),
                  secondaryColor.withOpacity(isDark ? 0.12 : 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
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
                          // Share
                          _ActionChip(
                            icon: Icons.share_rounded,
                            tooltip: 'Share',
                            onTap: () {
                              final url = 'https://7ea15cc5.pokedex-flutter-898.pages.dev/pokemon/${widget.pokemonId}';
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Link copied for ${_pokemon?.displayName ?? 'Pokemon #${widget.pokemonId}'}'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
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
                    // Phase 1: Extended Pokedex Data
                    if (_species != null) ...[
                      _buildExtendedDataSection(_species!, theme),
                      const SizedBox(height: 20),
                    ],
                    // Phase 1: Enhanced Abilities
                    _buildAbilitiesSection(p, theme),
                    const SizedBox(height: 20),
                    // Phase 1: Breeding Info
                    if (_species != null) ...[
                      _buildBreedingSection(_species!, theme),
                      const SizedBox(height: 20),
                    ],
                    // Phase 3: Encounters
                    _buildEncountersSection(p, theme),
                    const SizedBox(height: 20),
                    // Phase 4: Growth Rate
                    if (_species != null) ...[
                      _buildGrowthSection(_species!, theme),
                      const SizedBox(height: 20),
                    ],
                    if (_evoRoot != null && _evoRoot!.flatten().length > 1) ...[
                      _buildEvolutionSection(theme, isDark),
                      const SizedBox(height: 20),
                    ],
                    _buildTypeDefensesSection(p, theme, isDark),
                    const SizedBox(height: 20),
                    // Quick action buttons
                    _buildQuickActions(p, theme, isDark, typeColor),
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
    final varieties = _species?.varieties ?? [];
    final hasMultipleForms = varieties.length > 1;

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
        Row(
          children: [
            Expanded(
              child: Text(
                p.displayName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (_loadingForm)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
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
        // Form selector
        if (hasMultipleForms) ...[
          const SizedBox(height: 12),
          _buildFormSelector(varieties, theme),
        ],
      ],
    );
  }

  Widget _buildFormSelector(List<FormVariety> varieties, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentId = _pokemon?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORMS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface.withOpacity(0.35),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: varieties.map((form) {
              final isActive = currentId == form.id;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _loadingForm ? null : () => _switchForm(form),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary
                            : isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? colorScheme.primary
                              : isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        form.formLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Image.network(
            p.imageUrl,
            key: ValueKey(p.id),
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

  Widget _buildQuickActions(PokemonDetail p, ThemeData theme, bool isDark, Color typeColor) {
    final appState = AppState();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickActionButton(
          icon: Icons.shield_rounded,
          label: 'What Beats This?',
          color: Colors.red,
          isDark: isDark,
          onTap: () => context.go('/tools/counter/${p.id}'),
        ),
        _QuickActionButton(
          icon: Icons.bar_chart_rounded,
          label: 'Stat Calculator',
          color: const Color(0xFF3B82F6),
          isDark: isDark,
          onTap: () => context.go('/tools/stat-calc/${p.id}'),
        ),
        _QuickActionButton(
          icon: Icons.local_fire_department_rounded,
          label: 'Damage Calc',
          color: const Color(0xFFEF6C00),
          isDark: isDark,
          onTap: () => context.go('/tools/damage-calc'),
        ),
        _QuickActionButton(
          icon: Icons.speed_rounded,
          label: 'Speed Tiers',
          color: const Color(0xFF7C3AED),
          isDark: isDark,
          onTap: () => context.go('/tools/speed-tiers'),
        ),
        _QuickActionButton(
          icon: Icons.compare_arrows,
          label: 'Compare',
          color: typeColor,
          isDark: isDark,
          onTap: () => context.go('/battle/${p.id}/25'),
        ),
        _QuickActionButton(
          icon: appState.isOnTeam(p.id) ? Icons.group_remove : Icons.group_add,
          label: appState.isOnTeam(p.id) ? 'Remove from Team' : 'Add to Team',
          color: const Color(0xFF059669),
          isDark: isDark,
          onTap: () {
            appState.toggleTeamMember(p.id);
            setState(() {});
          },
        ),
        _QuickActionButton(
          icon: Icons.article_outlined,
          label: 'Etymology',
          color: const Color(0xFFF59E0B),
          isDark: isDark,
          onTap: () async {
            final pokemonName = p.displayName.split('(')[0].trim().replaceAll(' ', '_');
            final url = Uri.parse('https://bulbapedia.bulbagarden.net/wiki/${pokemonName}_(Pokémon)');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
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
                _buildEvoTree(child, theme, isDark),
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

  // Phase 1: Extended Pokedex Data Section
  Widget _buildExtendedDataSection(PokemonSpecies species, ThemeData theme) {
    return _sectionCard('Pokédex Data', theme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Generation', _romanNumeral(species.generation), theme),
        if (species.habitat != null)
          _infoRow('Habitat', species.habitat!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '), theme),
        if (species.color != null)
          _infoRow('Color', species.color![0].toUpperCase() + species.color!.substring(1), theme),
        if (species.shape != null)
          _infoRow('Shape', species.shape!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '), theme),
        if (species.captureRate != null)
          _infoRow('Capture Rate', '${species.captureRate}', theme),
        // Badges
        if (species.isLegendary || species.isMythical || species.isBaby) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (species.isLegendary) _Badge('Legendary', Colors.amber),
              if (species.isMythical) _Badge('Mythical', Colors.purple),
              if (species.isBaby) _Badge('Baby Pokémon', Colors.pink),
            ],
          ),
        ],
      ],
    ));
  }

  String _romanNumeral(int gen) {
    const numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
    return gen > 0 && gen <= numerals.length ? numerals[gen - 1] : '$gen';
  }

  // Phase 1: Enhanced Abilities Section
  Widget _buildAbilitiesSection(PokemonDetail p, ThemeData theme) {
    return _sectionCard('Abilities', theme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: p.abilities.map((ability) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AbilityCard(
            abilityName: ability.name,
            isHidden: ability.isHidden,
            theme: theme,
          ),
        );
      }).toList(),
    ));
  }

  // Phase 1: Breeding Info Section
  Widget _buildBreedingSection(PokemonSpecies species, ThemeData theme) {
    return _sectionCard('Breeding', theme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Egg Groups', species.eggGroups.isEmpty
            ? 'Undiscovered'
            : species.eggGroups.map((e) => e.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')).join(', '), theme),
        if (species.genderRate != null)
          _infoRow('Gender Ratio', _formatGenderRatio(species.genderRate!), theme),
        if (species.hatchCounter != null)
          _infoRow('Hatch Time', '${(species.hatchCounter! + 1) * 255} steps', theme),
        if (species.baseHappiness != null)
          _infoRow('Base Happiness', '${species.baseHappiness}', theme),
      ],
    ));
  }

  String _formatGenderRatio(int genderRate) {
    if (genderRate == -1) return 'Genderless';
    if (genderRate == 0) return '100% Male';
    if (genderRate == 8) return '100% Female';
    final femalePercent = (genderRate / 8 * 100).toStringAsFixed(1);
    final malePercent = ((8 - genderRate) / 8 * 100).toStringAsFixed(1);
    return '$malePercent% Male / $femalePercent% Female';
  }

  // Phase 3: Encounters Section
  Widget _buildEncountersSection(PokemonDetail p, ThemeData theme) {
    return _sectionCard('Encounters', theme, _EncountersContent(pokemonId: p.id));
  }

  // Phase 4: Growth Rate Section
  Widget _buildGrowthSection(PokemonSpecies species, ThemeData theme) {
    if (species.growthRate == null) return const SizedBox.shrink();
    return _sectionCard('Growth Rate', theme, _GrowthContent(growthRateName: species.growthRate!));
  }
}

// Encounters content widget (extracted to manage its own state)
class _EncountersContent extends StatefulWidget {
  final int pokemonId;

  const _EncountersContent({required this.pokemonId});

  @override
  State<_EncountersContent> createState() => _EncountersContentState();
}

class _EncountersContentState extends State<_EncountersContent> {
  List<EncounterVersionDetail>? _encounters;
  bool _loading = false;
  bool _expanded = false;

  Future<void> _loadEncounters() async {
    if (_encounters != null) return;
    setState(() => _loading = true);
    try {
      final encounters = await PokeApiService.getPokemonEncounters(widget.pokemonId);
      if (mounted) {
        setState(() {
          _encounters = encounters;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _encounters = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded && _encounters == null) {
              _loadEncounters();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wild Encounters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (_encounters == null || _encounters!.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This Pokémon is not available in the wild.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            )
          else
            ..._encounters!.map((versionDetail) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Version: ${versionDetail.version[0].toUpperCase()}${versionDetail.version.substring(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...versionDetail.encounterDetails.map((encounter) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${encounter.displayMethod} - ${encounter.chance}% (Lv. ${encounter.minLevel}-${encounter.maxLevel})',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
        ],
      ],
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

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(widget.isDark ? 0.2 : 0.1)
                : widget.color.withOpacity(widget.isDark ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withOpacity(_hovered ? 0.4 : 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

// Growth rate content widget (extracted to manage its own state)
class _GrowthContent extends StatefulWidget {
  final String growthRateName;

  const _GrowthContent({required this.growthRateName});

  @override
  State<_GrowthContent> createState() => _GrowthContentState();
}

class _GrowthContentState extends State<_GrowthContent> {
  GrowthRateDetail? _growthRate;
  bool _loading = false;
  bool _expanded = false;

  Future<void> _loadGrowthRate() async {
    if (_growthRate != null) return;
    setState(() => _loading = true);
    try {
      final growthRate = await PokeApiService.getGrowthRate(widget.growthRateName);
      if (mounted) {
        setState(() {
          _growthRate = growthRate;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Key levels to show
    final keyLevels = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded && _growthRate == null) {
              _loadGrowthRate();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _growthRate?.displayName ?? widget.growthRateName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Experience growth pattern',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (_growthRate == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Failed to load growth rate data.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Experience Required',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...keyLevels.map((level) {
                    final levelData = _growthRate!.levels.firstWhere(
                      (l) => l.level == level,
                      orElse: () => ExperienceLevel(level: level, experience: 0),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level $level',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '${levelData.experience.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} XP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AbilityCard extends StatefulWidget {
  final String abilityName;
  final bool isHidden;
  final ThemeData theme;

  const _AbilityCard({
    required this.abilityName,
    required this.isHidden,
    required this.theme,
  });

  @override
  State<_AbilityCard> createState() => _AbilityCardState();
}

class _AbilityCardState extends State<_AbilityCard> {
  bool _expanded = false;
  AbilityDetail? _abilityDetail;
  bool _loading = false;

  Future<void> _loadAbilityDetail() async {
    if (_abilityDetail != null) return;
    setState(() => _loading = true);
    try {
      final detail = await PokeApiService.getAbilityDetail(widget.abilityName);
      if (mounted) {
        setState(() {
          _abilityDetail = detail;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.abilityName
        .split('-')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded && _abilityDetail == null) {
              _loadAbilityDetail();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (widget.isHidden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Hidden',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.theme.colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.theme.colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (_abilityDetail != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _abilityDetail!.shortEffect ?? _abilityDetail!.effect ?? 'No description available.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: widget.theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            )
          else
            Text(
              'Failed to load ability details.',
              style: TextStyle(
                fontSize: 13,
                color: widget.theme.colorScheme.error,
              ),
            ),
        ],
      ],
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
