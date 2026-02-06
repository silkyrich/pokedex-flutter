import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/app_state.dart';
import '../services/pokeapi_service.dart';
import '../widgets/type_badge.dart';
import '../widgets/stat_bar.dart';
import '../widgets/pokemon_image.dart';
import '../utils/type_colors.dart';

// Curated list of strong Pokemon for suggestions (competitive viable mons)
const List<_SuggestedMon> _competitivePokemon = [
  _SuggestedMon(id: 6, name: 'Charizard', types: ['fire', 'flying'], bst: 534),
  _SuggestedMon(id: 9, name: 'Blastoise', types: ['water'], bst: 530),
  _SuggestedMon(id: 25, name: 'Pikachu', types: ['electric'], bst: 320),
  _SuggestedMon(id: 59, name: 'Arcanine', types: ['fire'], bst: 555),
  _SuggestedMon(id: 65, name: 'Alakazam', types: ['psychic'], bst: 500),
  _SuggestedMon(id: 68, name: 'Machamp', types: ['fighting'], bst: 505),
  _SuggestedMon(id: 94, name: 'Gengar', types: ['ghost', 'poison'], bst: 500),
  _SuggestedMon(id: 130, name: 'Gyarados', types: ['water', 'flying'], bst: 540),
  _SuggestedMon(id: 131, name: 'Lapras', types: ['water', 'ice'], bst: 535),
  _SuggestedMon(id: 143, name: 'Snorlax', types: ['normal'], bst: 540),
  _SuggestedMon(id: 149, name: 'Dragonite', types: ['dragon', 'flying'], bst: 600),
  _SuggestedMon(id: 150, name: 'Mewtwo', types: ['psychic'], bst: 680),
  _SuggestedMon(id: 212, name: 'Scizor', types: ['bug', 'steel'], bst: 500),
  _SuggestedMon(id: 243, name: 'Raikou', types: ['electric'], bst: 580),
  _SuggestedMon(id: 244, name: 'Entei', types: ['fire'], bst: 580),
  _SuggestedMon(id: 245, name: 'Suicune', types: ['water'], bst: 580),
  _SuggestedMon(id: 248, name: 'Tyranitar', types: ['rock', 'dark'], bst: 600),
  _SuggestedMon(id: 257, name: 'Blaziken', types: ['fire', 'fighting'], bst: 530),
  _SuggestedMon(id: 260, name: 'Swampert', types: ['water', 'ground'], bst: 535),
  _SuggestedMon(id: 282, name: 'Gardevoir', types: ['psychic', 'fairy'], bst: 518),
  _SuggestedMon(id: 306, name: 'Aggron', types: ['steel', 'rock'], bst: 530),
  _SuggestedMon(id: 334, name: 'Altaria', types: ['dragon', 'flying'], bst: 490),
  _SuggestedMon(id: 373, name: 'Salamence', types: ['dragon', 'flying'], bst: 600),
  _SuggestedMon(id: 376, name: 'Metagross', types: ['steel', 'psychic'], bst: 600),
  _SuggestedMon(id: 384, name: 'Rayquaza', types: ['dragon', 'flying'], bst: 680),
  _SuggestedMon(id: 445, name: 'Garchomp', types: ['dragon', 'ground'], bst: 600),
  _SuggestedMon(id: 448, name: 'Lucario', types: ['fighting', 'steel'], bst: 525),
  _SuggestedMon(id: 460, name: 'Abomasnow', types: ['grass', 'ice'], bst: 494),
  _SuggestedMon(id: 475, name: 'Gallade', types: ['psychic', 'fighting'], bst: 518),
  _SuggestedMon(id: 497, name: 'Serperior', types: ['grass'], bst: 528),
  _SuggestedMon(id: 500, name: 'Emboar', types: ['fire', 'fighting'], bst: 528),
  _SuggestedMon(id: 503, name: 'Samurott', types: ['water'], bst: 528),
  _SuggestedMon(id: 530, name: 'Excadrill', types: ['ground', 'steel'], bst: 508),
  _SuggestedMon(id: 553, name: 'Krookodile', types: ['ground', 'dark'], bst: 519),
  _SuggestedMon(id: 591, name: 'Amoonguss', types: ['grass', 'poison'], bst: 464),
  _SuggestedMon(id: 609, name: 'Chandelure', types: ['ghost', 'fire'], bst: 520),
  _SuggestedMon(id: 621, name: 'Druddigon', types: ['dragon'], bst: 485),
  _SuggestedMon(id: 635, name: 'Hydreigon', types: ['dark', 'dragon'], bst: 600),
  _SuggestedMon(id: 658, name: 'Greninja', types: ['water', 'dark'], bst: 530),
  _SuggestedMon(id: 663, name: 'Talonflame', types: ['fire', 'flying'], bst: 499),
  _SuggestedMon(id: 681, name: 'Aegislash', types: ['steel', 'ghost'], bst: 500),
  _SuggestedMon(id: 691, name: 'Dragalge', types: ['poison', 'dragon'], bst: 494),
  _SuggestedMon(id: 700, name: 'Sylveon', types: ['fairy'], bst: 525),
  _SuggestedMon(id: 706, name: 'Goodra', types: ['dragon'], bst: 600),
  _SuggestedMon(id: 715, name: 'Noivern', types: ['flying', 'dragon'], bst: 535),
  _SuggestedMon(id: 727, name: 'Incineroar', types: ['fire', 'dark'], bst: 530),
  _SuggestedMon(id: 730, name: 'Primarina', types: ['water', 'fairy'], bst: 530),
  _SuggestedMon(id: 738, name: 'Vikavolt', types: ['bug', 'electric'], bst: 500),
  _SuggestedMon(id: 745, name: 'Lycanroc', types: ['rock'], bst: 487),
  _SuggestedMon(id: 758, name: 'Salazzle', types: ['poison', 'fire'], bst: 480),
  _SuggestedMon(id: 778, name: 'Mimikyu', types: ['ghost', 'fairy'], bst: 476),
  _SuggestedMon(id: 784, name: 'Kommo-o', types: ['dragon', 'fighting'], bst: 600),
  _SuggestedMon(id: 797, name: 'Celesteela', types: ['steel', 'flying'], bst: 570),
  _SuggestedMon(id: 812, name: 'Rillaboom', types: ['grass'], bst: 530),
  _SuggestedMon(id: 815, name: 'Cinderace', types: ['fire'], bst: 530),
  _SuggestedMon(id: 818, name: 'Inteleon', types: ['water'], bst: 530),
  _SuggestedMon(id: 823, name: 'Corviknight', types: ['flying', 'steel'], bst: 495),
  _SuggestedMon(id: 836, name: 'Boltund', types: ['electric'], bst: 490),
  _SuggestedMon(id: 839, name: 'Coalossal', types: ['rock', 'fire'], bst: 510),
  _SuggestedMon(id: 842, name: 'Appletun', types: ['grass', 'dragon'], bst: 485),
  _SuggestedMon(id: 851, name: 'Centiskorch', types: ['fire', 'bug'], bst: 525),
  _SuggestedMon(id: 884, name: 'Duraludon', types: ['steel', 'dragon'], bst: 535),
  _SuggestedMon(id: 887, name: 'Dragapult', types: ['dragon', 'ghost'], bst: 600),
];

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final Map<int, PokemonDetail> _details = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AppState().addListener(_onStateChanged);
    _loadDetails();
  }

  @override
  void dispose() {
    AppState().removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final ids = AppState().team;
    final missing = ids.where((id) => !_details.containsKey(id)).toList();
    if (missing.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    setState(() => _loading = true);
    final results = await PokeApiService.getPokemonDetailsBatch(missing);
    for (int i = 0; i < missing.length; i++) {
      if (results[i] != null) _details[missing[i]] = results[i]!;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = AppState();
    final teamIds = appState.team;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
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
                            'My Team',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Build and analyze your dream team.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Team slots indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(6, (i) {
                        final isFilled = i < teamIds.length;
                        return Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? theme.colorScheme.primary
                                : isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade200,
                            border: Border.all(
                              color: isFilled
                                  ? theme.colorScheme.primary
                                  : isDark
                                      ? Colors.white.withOpacity(0.15)
                                      : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (teamIds.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => appState.clearTeam(),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (teamIds.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.groups_outlined,
                              size: 56,
                              color: theme.colorScheme.onSurface.withOpacity(0.15),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No team members yet',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the team icon on any Pokemon detail page to build your team.',
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.catching_pokemon, size: 18),
                            label: const Text('Browse Pokedex'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ...teamIds.map((id) {
                    final detail = _details[id];
                    if (detail == null) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text('Loading Pokemon #$id...', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                            ],
                          ),
                        ),
                      );
                    }
                    return _TeamMemberCard(
                      pokemon: detail,
                      isWide: isWide,
                      isDark: isDark,
                      onTap: () => context.go('/pokemon/$id'),
                      onRemove: () => appState.toggleTeamMember(id),
                    );
                  }),
                  const SizedBox(height: 24),
                  if (teamIds.length >= 2)
                    _buildTeamSummary(teamIds, theme, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_Suggestion> _getSuggestions(
    List<String> offensiveGaps,
    Map<String, int> weaknesses,
    List<int> currentTeamIds,
  ) {
    final suggestions = <_Suggestion>[];

    // Get critical weaknesses (3+ team members weak to it)
    final criticalWeaknesses = weaknesses.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toList();

    for (final mon in _competitivePokemon) {
      // Skip if already on team
      if (currentTeamIds.contains(mon.id)) continue;

      int score = 0;
      final reasons = <String>[];

      // Check offensive coverage (can this mon hit our gaps?)
      int gapsCovered = 0;
      for (final gap in offensiveGaps.take(5)) {
        for (final type in mon.types) {
          if (TypeChart.getEffectiveness(type, gap) >= 2.0) {
            gapsCovered++;
            break;
          }
        }
      }
      if (gapsCovered > 0) {
        score += gapsCovered * 10;
        reasons.add('Covers $gapsCovered offensive gap${gapsCovered > 1 ? 's' : ''}');
      }

      // Check defensive value (does it resist critical weaknesses?)
      int resists = 0;
      for (final weakness in criticalWeaknesses) {
        double effectiveness = 1.0;
        for (final type in mon.types) {
          effectiveness *= TypeChart.getEffectiveness(weakness, type);
        }
        if (effectiveness <= 0.5) {
          resists++;
        }
      }
      if (resists > 0) {
        score += resists * 15;
        reasons.add('Resists ${resists} critical weakness${resists > 1 ? 'es' : ''}');
      }

      // Type diversity bonus (adds new type to team)
      final Set<String> teamTypes = {};
      for (final id in currentTeamIds) {
        final d = _details[id];
        if (d != null) {
          teamTypes.addAll(d.types.map((t) => t.name));
        }
      }
      int newTypes = 0;
      for (final type in mon.types) {
        if (!teamTypes.contains(type)) newTypes++;
      }
      if (newTypes > 0) {
        score += newTypes * 5;
        if (newTypes == mon.types.length) {
          reasons.add('Adds unique type coverage');
        }
      }

      // BST bonus (stronger is better)
      if (mon.bst >= 600) score += 5;

      if (score > 0 && reasons.isNotEmpty) {
        suggestions.add(_Suggestion(pokemon: mon, reasons: reasons, score: score));
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(5).toList();
  }

  Widget _buildTeamSummary(List<int> teamIds, ThemeData theme, bool isDark) {
    final Set<String> allTypes = {};
    final Map<String, int> weaknesses = {};
    final Map<String, int> resistances = {};
    final Map<String, int> offensiveCoverage = {};

    for (final id in teamIds) {
      final d = _details[id];
      if (d == null) continue;

      final typeNames = d.types.map((t) => t.name).toList();
      allTypes.addAll(typeNames);

      // Defensive analysis
      for (final attackType in TypeChart.types) {
        double mult = 1;
        for (final defType in typeNames) {
          mult *= TypeChart.getEffectiveness(attackType, defType);
        }
        if (mult > 1) weaknesses[attackType] = (weaknesses[attackType] ?? 0) + 1;
        if (mult < 1) resistances[attackType] = (resistances[attackType] ?? 0) + 1;
      }

      // Offensive coverage (STAB types hitting super effectively)
      for (final atkType in typeNames) {
        for (final defType in TypeChart.types) {
          if (TypeChart.getEffectiveness(atkType, defType) >= 2) {
            offensiveCoverage[defType] = (offensiveCoverage[defType] ?? 0) + 1;
          }
        }
      }
    }

    final coverageTypes = allTypes.toList()..sort();
    final uncoveredTypes = TypeChart.types.where((t) => !coverageTypes.contains(t)).toList();

    // Offensive gaps — types we can't hit super effectively
    final offensiveGaps = TypeChart.types.where((t) => !offensiveCoverage.containsKey(t)).toList();

    // Shared weaknesses — types that hit 3+ team members super effectively
    final criticalWeaknesses = weaknesses.entries.where((e) => e.value >= 3).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Unresisted types — attack types nobody on team resists
    final unresisted = TypeChart.types.where((t) => !resistances.containsKey(t)).toList();

    // Generate warnings
    final warnings = <_TeamWarning>[];
    for (final cw in criticalWeaknesses) {
      warnings.add(_TeamWarning(
        icon: Icons.warning_rounded,
        color: Colors.red,
        text: 'Your team has no answer to ${cw.key[0].toUpperCase()}${cw.key.substring(1)} types — ${cw.value} members are weak to it.',
      ));
    }
    if (offensiveGaps.isNotEmpty && offensiveGaps.length <= 4) {
      final gapNames = offensiveGaps.map((t) => '${t[0].toUpperCase()}${t.substring(1)}').join(', ');
      warnings.add(_TeamWarning(
        icon: Icons.flash_off_rounded,
        color: Colors.orange,
        text: 'No super effective STAB coverage against: $gapNames.',
      ));
    }
    if (unresisted.isNotEmpty && unresisted.length <= 4) {
      final names = unresisted.map((t) => '${t[0].toUpperCase()}${t.substring(1)}').join(', ');
      warnings.add(_TeamWarning(
        icon: Icons.shield_outlined,
        color: Colors.amber,
        text: 'No team member resists: $names.',
      ));
    }

    // Stat overview
    int totalBst = 0;
    int minSpeed = 999;
    int maxSpeed = 0;
    for (final id in teamIds) {
      final d = _details[id];
      if (d == null) continue;
      totalBst += d.stats.values.fold(0, (a, b) => a + b);
      final spd = d.stats['speed'] ?? 0;
      if (spd < minSpeed) minSpeed = spd;
      if (spd > maxSpeed) maxSpeed = spd;
    }
    final avgBst = teamIds.isNotEmpty ? totalBst ~/ teamIds.length : 0;

    // Generate suggestions if team is incomplete
    final suggestions = teamIds.length < 6
        ? _getSuggestions(offensiveGaps, weaknesses, teamIds)
        : <_Suggestion>[];

    return Column(
      children: [
        // Warnings
        if (warnings.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.red, size: 22),
                      const SizedBox(width: 8),
                      Text('Team Warnings', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(w.icon, size: 18, color: w.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(w.text, style: TextStyle(fontSize: 13, height: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        if (warnings.isNotEmpty) const SizedBox(height: 12),

        // Suggestions
        if (suggestions.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Suggested Teammates',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pokemon that would strengthen your team:',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => context.go('/pokemon/${s.pokemon.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(isDark ? 0.08 : 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: TypeColors.getColor(s.pokemon.types.first)
                                    .withOpacity(isDark ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: PokemonImage.sprite(s.pokemon.id,
                                fallbackIconSize: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        s.pokemon.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ...s.pokemon.types.map((t) => Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: TypeBadge(type: t, fontSize: 9),
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...s.reasons.map((r) => Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 12,
                                            color: Colors.green.withOpacity(0.7)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            r,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Main analysis
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Team Analysis', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 16),
                // Stat summary
                Row(
                  children: [
                    _StatSummaryTile(label: 'Avg BST', value: '$avgBst', icon: Icons.bar_chart, color: theme.colorScheme.primary, isDark: isDark),
                    const SizedBox(width: 8),
                    _StatSummaryTile(label: 'Speed Range', value: '$minSpeed-$maxSpeed', icon: Icons.speed, color: const Color(0xFF8B5CF6), isDark: isDark),
                    const SizedBox(width: 8),
                    _StatSummaryTile(label: 'Types', value: '${coverageTypes.length}/18', icon: Icons.grid_view, color: const Color(0xFF22C55E), isDark: isDark),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Offensive STAB coverage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: TypeChart.types.map((t) {
                    final covered = offensiveCoverage.containsKey(t);
                    return Opacity(
                      opacity: covered ? 1.0 : 0.3,
                      child: TypeBadge(type: t, fontSize: 10, navigable: true),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Types on team', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: coverageTypes.map((t) => TypeBadge(type: t, navigable: true)).toList(),
                ),
                if (uncoveredTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Types not on team', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: uncoveredTypes.map((t) => Opacity(opacity: 0.4, child: TypeBadge(type: t, navigable: true))).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                Text('Defensive weaknesses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: (weaknesses.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                    .take(10)
                    .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TypeColors.getColor(e.key).withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TypeColors.getColor(e.key).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${e.key[0].toUpperCase()}${e.key.substring(1)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TypeColors.getColor(e.key)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text('${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red)),
                          ),
                        ],
                      ),
                    ))
                    .toList(),
                ),
                const SizedBox(height: 16),
                // Quick links
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/tools/speed-tiers'),
                        icon: const Icon(Icons.speed_rounded, size: 16),
                        label: const Text('Speed Tiers'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/tools/counter'),
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text('Counter Lookup'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamMemberCard extends StatefulWidget {
  final PokemonDetail pokemon;
  final bool isWide;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _TeamMemberCard({
    required this.pokemon,
    required this.isWide,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = TypeColors.getColor(widget.pokemon.types.first.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _hovered
                ? typeColor.withOpacity(0.4)
                : widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade200,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Subtle type gradient
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: widget.isWide ? _wideLayout(theme) : _narrowLayout(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideLayout(ThemeData theme) {
    final statOrder = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: TypeColors.getColor(widget.pokemon.types.first.name).withOpacity(widget.isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: PokemonImage(
                  imageUrl: widget.pokemon.imageUrl,
                  fit: BoxFit.contain,
                  fallbackIconSize: 36,
                ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.pokemon.displayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface)),
              Text(widget.pokemon.idString, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.35), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, children: widget.pokemon.types.map((t) => TypeBadge(type: t.name, fontSize: 10)).toList()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: statOrder.map((s) => StatBar(label: s, value: widget.pokemon.stats[s] ?? 0, animate: false)).toList(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          onPressed: widget.onRemove,
          tooltip: 'Remove from team',
        ),
      ],
    );
  }

  Widget _narrowLayout(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: TypeColors.getColor(widget.pokemon.types.first.name).withOpacity(widget.isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PokemonImage.sprite(widget.pokemon.id,
            fallbackIconSize: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.pokemon.displayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 4),
              Wrap(spacing: 4, children: widget.pokemon.types.map((t) => TypeBadge(type: t.name, fontSize: 10)).toList()),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          onPressed: widget.onRemove,
          tooltip: 'Remove from team',
        ),
      ],
    );
  }
}

class _TeamWarning {
  final IconData icon;
  final Color color;
  final String text;
  _TeamWarning({required this.icon, required this.color, required this.text});
}

class _StatSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatSummaryTile({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

class _SuggestedMon {
  final int id;
  final String name;
  final List<String> types;
  final int bst;

  const _SuggestedMon({
    required this.id,
    required this.name,
    required this.types,
    required this.bst,
  });
}

class _Suggestion {
  final _SuggestedMon pokemon;
  final List<String> reasons;
  final int score;

  _Suggestion({required this.pokemon, required this.reasons, required this.score});
}
