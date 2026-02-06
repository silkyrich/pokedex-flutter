import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';
import '../services/pokeapi_service.dart';
import '../models/pokemon.dart';
import '../widgets/pokemon_image.dart';

class TypeMatchupScreen extends StatefulWidget {
  final String attackingType;
  final String defendingType;

  const TypeMatchupScreen({
    super.key,
    required this.attackingType,
    required this.defendingType,
  });

  @override
  State<TypeMatchupScreen> createState() => _TypeMatchupScreenState();
}

class _TypeMatchupScreenState extends State<TypeMatchupScreen> {
  List<PokemonBasic>? _attackerPokemon;
  List<PokemonBasic>? _defenderPokemon;
  bool _loadingPokemon = true;

  @override
  void initState() {
    super.initState();
    _loadExamplePokemon();
  }

  Future<void> _loadExamplePokemon() async {
    try {
      final all = await PokeApiService.getAllPokemonBasic();
      // We'll load details for first 60 pokemon to find types
      final detailFutures = <Future<PokemonDetail?>>[];
      final sampleIds = List.generate(60.clamp(0, all.length), (i) => all[i].id);
      final details = await PokeApiService.getPokemonDetailsBatch(sampleIds);

      final attackers = <PokemonBasic>[];
      final defenders = <PokemonBasic>[];

      for (final d in details) {
        if (d == null) continue;
        final types = d.types.map((t) => t.name).toList();
        if (types.contains(widget.attackingType) && attackers.length < 6) {
          attackers.add(PokemonBasic(id: d.id, name: d.name, url: ''));
        }
        if (types.contains(widget.defendingType) && defenders.length < 6) {
          defenders.add(PokemonBasic(id: d.id, name: d.name, url: ''));
        }
      }

      if (mounted) {
        setState(() {
          _attackerPokemon = attackers;
          _defenderPokemon = defenders;
          _loadingPokemon = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPokemon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final atkType = widget.attackingType;
    final defType = widget.defendingType;
    final atkColor = TypeColors.getColor(atkType);
    final defColor = TypeColors.getColor(defType);
    final atkEff = TypeChart.getEffectiveness(atkType, defType);
    final defEff = TypeChart.getEffectiveness(defType, atkType);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back chip
                ActionChip(
                  avatar: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Type Chart'),
                  onPressed: () => context.go('/types'),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Type Matchup',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore the battle dynamics between these two types.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 28),
                // Main matchup card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Type vs Type header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TypeCircle(type: atkType),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _TypeCircle(type: defType),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Effectiveness both ways
                        _EffectivenessRow(
                          attackerType: atkType,
                          defenderType: defType,
                          effectiveness: atkEff,
                          isDark: isDark,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _EffectivenessRow(
                          attackerType: defType,
                          defenderType: atkType,
                          effectiveness: defEff,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Battle analysis
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics_outlined, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Battle Analysis',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildAnalysis(atkType, defType, atkEff, defEff, theme, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Full type chart for attacker
                _TypeBreakdownCard(
                  type: atkType,
                  label: 'Attacking with',
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _TypeBreakdownCard(
                  type: defType,
                  label: 'Defending as',
                  theme: theme,
                  isDark: isDark,
                  defending: true,
                ),
                const SizedBox(height: 20),
                // Example Pokemon
                if (!_loadingPokemon) ...[
                  _PokemonSampleRow(
                    type: atkType,
                    pokemon: _attackerPokemon ?? [],
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _PokemonSampleRow(
                    type: defType,
                    pokemon: _defenderPokemon ?? [],
                    theme: theme,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 24),
                // Head to head compare CTA
                Center(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/battle'),
                    icon: const Icon(Icons.compare_arrows_rounded, size: 20),
                    label: const Text('Compare specific Pokemon'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysis(String atk, String def, double atkEff, double defEff, ThemeData theme, bool isDark) {
    final atkName = _cap(atk);
    final defName = _cap(def);

    String summary;
    Color summaryColor;
    IconData summaryIcon;

    if (atkEff > defEff) {
      summary = '$atkName has the advantage over $defName';
      summaryColor = TypeColors.getColor(atk);
      summaryIcon = Icons.trending_up_rounded;
    } else if (defEff > atkEff) {
      summary = '$defName has the advantage over $atkName';
      summaryColor = TypeColors.getColor(def);
      summaryIcon = Icons.trending_down_rounded;
    } else if (atkEff == 1 && defEff == 1) {
      summary = 'Neutral matchup — no type advantage either way';
      summaryColor = Colors.grey;
      summaryIcon = Icons.horizontal_rule_rounded;
    } else {
      summary = 'Symmetric matchup — equal effectiveness both ways';
      summaryColor = Colors.orange;
      summaryIcon = Icons.swap_horiz_rounded;
    }

    final tips = <String>[];
    if (atkEff == 2) tips.add('$atkName moves deal 2x damage to $defName');
    if (atkEff == 0.5) tips.add('$atkName moves deal only 1/2x damage to $defName');
    if (atkEff == 0) tips.add('$atkName moves have no effect on $defName');
    if (defEff == 2) tips.add('$defName moves deal 2x damage to $atkName');
    if (defEff == 0.5) tips.add('$defName moves deal only 1/2x damage to $atkName');
    if (defEff == 0) tips.add('$defName moves have no effect on $atkName');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: summaryColor.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: summaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(summaryIcon, color: summaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? summaryColor : summaryColor.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  String _cap(String s) => s[0].toUpperCase() + s.substring(1);
}

class _TypeCircle extends StatelessWidget {
  final String type;

  const _TypeCircle({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = TypeColors.getColor(type);
    final textColor = TypeColors.getTextColor(type);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Color.lerp(color, Colors.black, 0.2)!],
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: Text(
              type.substring(0, 3).toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          type[0].toUpperCase() + type.substring(1),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EffectivenessRow extends StatelessWidget {
  final String attackerType;
  final String defenderType;
  final double effectiveness;
  final bool isDark;
  final ThemeData theme;

  const _EffectivenessRow({
    required this.attackerType,
    required this.defenderType,
    required this.effectiveness,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final atkColor = TypeColors.getColor(attackerType);
    final effLabel = _effectivenessLabel(effectiveness);
    final effColor = _effectivenessColor(effectiveness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          TypeBadge(type: attackerType),
          const SizedBox(width: 10),
          Icon(Icons.arrow_forward_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(width: 10),
          TypeBadge(type: defenderType),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: effColor.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: effColor.withOpacity(0.3)),
            ),
            child: Text(
              effLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? effColor : effColor.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _effectivenessLabel(double val) {
    if (val == 0) return '0x (Immune)';
    if (val == 0.5) return '0.5x (Resisted)';
    if (val == 2) return '2x (Super Effective!)';
    return '1x (Normal)';
  }

  Color _effectivenessColor(double val) {
    if (val == 0) return Colors.grey.shade700;
    if (val == 0.5) return const Color(0xFFEF4444);
    if (val == 2) return const Color(0xFF22C55E);
    return Colors.blueGrey;
  }
}

class _TypeBreakdownCard extends StatelessWidget {
  final String type;
  final String label;
  final ThemeData theme;
  final bool isDark;
  final bool defending;

  const _TypeBreakdownCard({
    required this.type,
    required this.label,
    required this.theme,
    required this.isDark,
    this.defending = false,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = TypeColors.getColor(type);
    final superEffective = <String>[];
    final notVeryEffective = <String>[];
    final immune = <String>[];

    for (final t in TypeChart.types) {
      final eff = defending
          ? TypeChart.getEffectiveness(t, type)
          : TypeChart.getEffectiveness(type, t);
      if (eff == 2) superEffective.add(t);
      else if (eff == 0.5) notVeryEffective.add(t);
      else if (eff == 0) immune.add(t);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                TypeBadge(type: type),
              ],
            ),
            const SizedBox(height: 16),
            if (superEffective.isNotEmpty)
              _breakdownRow(
                defending ? 'Weak to' : 'Super effective against',
                superEffective,
                const Color(0xFF22C55E),
              ),
            if (notVeryEffective.isNotEmpty)
              _breakdownRow(
                defending ? 'Resists' : 'Not very effective against',
                notVeryEffective,
                const Color(0xFFEF4444),
              ),
            if (immune.isNotEmpty)
              _breakdownRow(
                defending ? 'Immune to' : 'No effect on',
                immune,
                Colors.grey.shade700,
              ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, List<String> types, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: types.map((t) => TypeBadge(type: t, fontSize: 11, navigable: true)).toList(),
          ),
        ],
      ),
    );
  }
}

class _PokemonSampleRow extends StatelessWidget {
  final String type;
  final List<PokemonBasic> pokemon;
  final ThemeData theme;
  final bool isDark;

  const _PokemonSampleRow({
    required this.type,
    required this.pokemon,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (pokemon.isEmpty) return const SizedBox.shrink();

    final typeColor = TypeColors.getColor(type);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TypeBadge(type: type, fontSize: 11),
                const SizedBox(width: 8),
                Text(
                  'Pokemon',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pokemon.map((p) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => context.go('/pokemon/${p.id}'),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(isDark ? 0.12 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PokemonImage(
                              imageUrl: p.spriteUrl,
                              width: 48,
                              height: 48,
                              fallbackIconColor: typeColor.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.displayName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
