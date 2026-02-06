import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';
import '../widgets/transparent_pokemon_image.dart';

/// "What beats this?" quick lookup.
/// Tap a Pokemon, instantly get type counters and best team answers.
class CounterScreen extends StatefulWidget {
  final int? pokemonId;
  const CounterScreen({super.key, this.pokemonId});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  PokemonDetail? _target;
  bool _loading = false;
  List<PokemonBasic> _searchResults = [];

  // Counter results
  List<String> _superEffectiveTypes = [];
  List<String> _resistedTypes = [];
  List<String> _immuneTypes = [];
  Map<String, double> _typeMultipliers = {};

  // Team counters
  List<_TeamCounter> _teamCounters = [];
  bool _loadingTeam = false;

  @override
  void initState() {
    super.initState();
    if (widget.pokemonId != null) {
      _loadPokemon(widget.pokemonId!);
    } else {
      final active = AppState().activePokemon;
      if (active != null) {
        _target = active;
        _analyzeCounters(active);
        _analyzeTeamCounters(active);
      }
    }
  }

  Future<void> _loadPokemon(int id) async {
    setState(() => _loading = true);
    try {
      final detail = await PokeApiService.getPokemonDetail(id);
      if (mounted) {
        setState(() { _target = detail; _loading = false; });
        _analyzeCounters(detail);
        _analyzeTeamCounters(detail);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _analyzeCounters(PokemonDetail pokemon) {
    final defTypes = pokemon.types.map((t) => t.name).toList();
    final multipliers = <String, double>{};
    final superEffective = <String>[];
    final resisted = <String>[];
    final immune = <String>[];

    for (final attackType in TypeChart.types) {
      double mult = 1;
      for (final defType in defTypes) {
        mult *= TypeChart.getEffectiveness(attackType, defType);
      }
      multipliers[attackType] = mult;
      if (mult >= 2) superEffective.add(attackType);
      else if (mult > 0 && mult < 1) resisted.add(attackType);
      else if (mult == 0) immune.add(attackType);
    }

    // Sort super effective by multiplier (4x before 2x)
    superEffective.sort((a, b) => (multipliers[b] ?? 1).compareTo(multipliers[a] ?? 1));

    setState(() {
      _superEffectiveTypes = superEffective;
      _resistedTypes = resisted;
      _immuneTypes = immune;
      _typeMultipliers = multipliers;
    });
  }

  Future<void> _analyzeTeamCounters(PokemonDetail target) async {
    final teamIds = AppState().team;
    if (teamIds.isEmpty) return;

    setState(() => _loadingTeam = true);
    final counters = <_TeamCounter>[];

    for (final id in teamIds) {
      try {
        final detail = await PokeApiService.getPokemonDetail(id);
        final atkTypes = detail.types.map((t) => t.name).toList();
        final defTypes = target.types.map((t) => t.name).toList();

        // How well does this team member attack the target?
        double bestOffense = 0;
        String? bestAtkType;
        for (final at in atkTypes) {
          double mult = 1;
          for (final dt in defTypes) {
            mult *= TypeChart.getEffectiveness(at, dt);
          }
          if (mult > bestOffense) {
            bestOffense = mult;
            bestAtkType = at;
          }
        }

        // How well does the target attack this team member?
        double worstDefense = 0;
        for (final at in defTypes) {
          double mult = 1;
          for (final dt in atkTypes) {
            mult *= TypeChart.getEffectiveness(at, dt);
          }
          if (mult > worstDefense) worstDefense = mult;
        }

        counters.add(_TeamCounter(
          pokemon: detail,
          offenseMultiplier: bestOffense,
          defenseMultiplier: worstDefense,
          bestAtkType: bestAtkType,
        ));
      } catch (_) {}
    }

    // Sort by offensive advantage
    counters.sort((a, b) {
      final aScore = a.offenseMultiplier - a.defenseMultiplier;
      final bScore = b.offenseMultiplier - b.defenseMultiplier;
      return bScore.compareTo(aScore);
    });

    if (mounted) setState(() { _teamCounters = counters; _loadingTeam = false; });
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final results = await PokeApiService.searchPokemon(query);
      if (mounted) setState(() => _searchResults = results.take(8).toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What Beats This?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Instant counter lookup. See best attacking types and your team\'s answers.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 24),
                // Search
                _buildSearch(theme, isDark),
                if (_target != null) ...[
                  const SizedBox(height: 20),
                  _buildTargetDisplay(theme, isDark),
                  const SizedBox(height: 20),
                  _buildWeaknessOverview(theme, isDark),
                  const SizedBox(height: 20),
                  if (_teamCounters.isNotEmpty || _loadingTeam)
                    _buildTeamAnalysis(theme, isDark),
                  const SizedBox(height: 20),
                  _buildCounterTips(theme, isDark),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Who are you facing? Search a Pokemon...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                suffixIcon: _loading ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ) : null,
              ),
              onChanged: (v) => _search(v),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                ),
                child: ListView.builder(
                  shrinkWrap: true, itemCount: _searchResults.length,
                  itemBuilder: (_, i) {
                    final p = _searchResults[i];
                    return ListTile(
                      dense: true,
                      leading: Image.network(p.spriteUrl, width: 32, height: 32,
                          errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 24)),
                      title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(p.idString, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      onTap: () {
                        setState(() => _searchResults = []);
                        _loadPokemon(p.id);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetDisplay(ThemeData theme, bool isDark) {
    final p = _target!;
    final typeColor = TypeColors.getColor(p.types.first.name);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor.withOpacity(isDark ? 0.15 : 0.08), typeColor.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: AppState().transparentBackgrounds
                ? TransparentPokemonImage(
                    imageUrl: p.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, size: 40, color: typeColor.withOpacity(0.3)),
                  )
                : Image.network(p.imageUrl, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, size: 40, color: typeColor.withOpacity(0.3))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.go('/pokemon/${p.id}'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(p.displayName, style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 22, color: typeColor,
                      decoration: TextDecoration.underline, decorationColor: typeColor.withOpacity(0.3),
                    )),
                  ),
                ),
                Text(p.idString, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: p.types.map((t) => TypeBadge(type: t.name, fontSize: 12)).toList()),
              ],
            ),
          ),
          // Quick action to compare
          FilledButton.icon(
            onPressed: () => context.go('/battle/${p.id}/25'),
            icon: const Icon(Icons.compare_arrows, size: 16),
            label: const Text('Compare'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaknessOverview(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Text('Weak To', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Use these types!', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (_superEffectiveTypes.isEmpty)
              Text('No weaknesses found', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)))
            else
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _superEffectiveTypes.map((type) {
                  final mult = _typeMultipliers[type] ?? 1;
                  final label = mult >= 4 ? '4x' : '2x';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TypeBadge(type: type, fontSize: 12, navigable: true),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            // Resists
            Row(
              children: [
                Icon(Icons.shield_rounded, color: const Color(0xFF22C55E), size: 22),
                const SizedBox(width: 8),
                Text('Resists', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Avoid these', style: TextStyle(fontSize: 12, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _resistedTypes.map((type) {
                final mult = _typeMultipliers[type] ?? 1;
                final label = mult <= 0.25 ? '1/4x' : '1/2x';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TypeBadge(type: type, fontSize: 11),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: const Color(0xFF22C55E))),
                  ],
                );
              }).toList(),
            ),
            if (_immuneTypes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.block_rounded, color: Colors.grey, size: 22),
                  const SizedBox(width: 8),
                  Text('Immune To', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _immuneTypes.map((t) => TypeBadge(type: t, fontSize: 11)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamAnalysis(ThemeData theme, bool isDark) {
    if (_loadingTeam) {
      return const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Your Team\'s Answers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text('How your current team members match up',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
            const SizedBox(height: 16),
            ..._teamCounters.map((tc) {
              final color = TypeColors.getColor(tc.pokemon.types.first.name);
              final score = tc.offenseMultiplier - tc.defenseMultiplier;
              Color scoreColor;
              String verdict;
              IconData verdictIcon;

              if (score > 1) {
                scoreColor = const Color(0xFF22C55E);
                verdict = 'Strong counter';
                verdictIcon = Icons.check_circle;
              } else if (score > 0) {
                scoreColor = const Color(0xFFEAB308);
                verdict = 'Decent matchup';
                verdictIcon = Icons.radio_button_checked;
              } else if (score == 0) {
                scoreColor = Colors.blueGrey;
                verdict = 'Neutral';
                verdictIcon = Icons.remove_circle_outline;
              } else {
                scoreColor = const Color(0xFFEF4444);
                verdict = 'Disadvantaged';
                verdictIcon = Icons.cancel;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(isDark ? 0.06 : 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 40,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 10),
                    AppState().transparentBackgrounds
                        ? TransparentPokemonImage(
                            imageUrl: tc.pokemon.imageUrl,
                            width: 40, height: 40,
                            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 28),
                          )
                        : Image.network(
                            tc.pokemon.imageUrl, width: 40, height: 40,
                            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 28),
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tc.pokemon.displayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface)),
                          Row(
                            children: [
                              if (tc.bestAtkType != null) ...[
                                Text('Best: ', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                                TypeBadge(type: tc.bestAtkType!, fontSize: 9),
                                Text(' (${tc.offenseMultiplier}x)',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                        color: tc.offenseMultiplier >= 2 ? const Color(0xFF22C55E) : theme.colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(verdictIcon, size: 18, color: scoreColor),
                        Text(verdict, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: scoreColor)),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (_teamCounters.isEmpty && AppState().team.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.groups_outlined, size: 32, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                      const SizedBox(height: 8),
                      Text('Add Pokemon to your team to see matchups',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterTips(ThemeData theme, bool isDark) {
    if (_target == null || _superEffectiveTypes.isEmpty) return const SizedBox.shrink();

    final p = _target!;
    final bestType = _superEffectiveTypes.first;
    final bestMult = _typeMultipliers[bestType] ?? 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Text('Quick Tips', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            _TipRow(
              icon: Icons.bolt_rounded,
              color: Colors.red,
              text: '${bestType[0].toUpperCase()}${bestType.substring(1)} moves deal ${bestMult >= 4 ? "4x" : "2x"} damage to ${p.displayName}.',
            ),
            if (p.stats['speed'] != null)
              _TipRow(
                icon: Icons.speed_rounded,
                color: theme.colorScheme.primary,
                text: '${p.displayName} has ${p.stats["speed"]} base Speed. ${p.stats["speed"]! >= 100 ? "It\'s fast — consider priority moves or a faster counter." : "It\'s relatively slow — most offensive threats can outspeed."}',
              ),
            if (p.stats['defense'] != null && p.stats['special-defense'] != null) ...[
              if ((p.stats['defense'] ?? 0) > (p.stats['special-defense'] ?? 0) + 20)
                _TipRow(
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFEF4444),
                  text: 'Higher physical defense (${p.stats["defense"]}) than special defense (${p.stats["special-defense"]}). Hit it with special attacks.',
                )
              else if ((p.stats['special-defense'] ?? 0) > (p.stats['defense'] ?? 0) + 20)
                _TipRow(
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFEF4444),
                  text: 'Higher special defense (${p.stats["special-defense"]}) than physical defense (${p.stats["defense"]}). Hit it with physical attacks.',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamCounter {
  final PokemonDetail pokemon;
  final double offenseMultiplier;
  final double defenseMultiplier;
  final String? bestAtkType;

  _TeamCounter({required this.pokemon, required this.offenseMultiplier, required this.defenseMultiplier, this.bestAtkType});
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _TipRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, height: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }
}
