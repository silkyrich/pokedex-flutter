import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../models/move.dart';
import '../services/pokeapi_service.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';
import '../widgets/stat_bar.dart';

class BattleScreen extends StatefulWidget {
  final int? initialId1;
  final int? initialId2;

  const BattleScreen({super.key, this.initialId1, this.initialId2});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> with TickerProviderStateMixin {
  // Pokemon 1
  PokemonDetail? _pokemon1;
  PokemonSpecies? _species1;
  EvolutionInfo? _evoRoot1;
  Map<String, MoveDetail>? _moveDetails1;

  // Pokemon 2
  PokemonDetail? _pokemon2;
  PokemonSpecies? _species2;
  EvolutionInfo? _evoRoot2;
  Map<String, MoveDetail>? _moveDetails2;

  bool _loading1 = false;
  bool _loading2 = false;
  String _search1 = '';
  String _search2 = '';
  List<PokemonBasic> _searchResults1 = [];
  List<PokemonBasic> _searchResults2 = [];
  bool _searching1 = false;
  bool _searching2 = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);

    if (widget.initialId1 != null) _loadPokemon(1, widget.initialId1!);
    if (widget.initialId2 != null) _loadPokemon(2, widget.initialId2!);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon(int slot, int id) async {
    setState(() {
      if (slot == 1) _loading1 = true; else _loading2 = true;
    });

    try {
      final detail = await PokeApiService.getPokemonDetail(id);
      final species = await PokeApiService.getPokemonSpecies(id);
      EvolutionInfo? evoRoot;
      if (species.evolutionChainId != null) {
        evoRoot = await PokeApiService.getEvolutionChain(species.evolutionChainId!);
      }

      // Load move details for STAB and effectiveness analysis
      final moveMap = <String, MoveDetail>{};
      final movesToLoad = detail.moves.take(20).toList();
      for (final m in movesToLoad) {
        try {
          final md = await PokeApiService.getMoveDetail(m.name);
          moveMap[m.name] = md;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          if (slot == 1) {
            _pokemon1 = detail;
            _species1 = species;
            _evoRoot1 = evoRoot;
            _moveDetails1 = moveMap;
            _loading1 = false;
          } else {
            _pokemon2 = detail;
            _species2 = species;
            _evoRoot2 = evoRoot;
            _moveDetails2 = moveMap;
            _loading2 = false;
          }
        });
        if (_pokemon1 != null && _pokemon2 != null) {
          _animController.forward(from: 0);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (slot == 1) _loading1 = false; else _loading2 = false;
        });
      }
    }
  }

  Future<void> _search(int slot, String query) async {
    if (query.length < 2) {
      setState(() {
        if (slot == 1) { _searchResults1 = []; _searching1 = false; }
        else { _searchResults2 = []; _searching2 = false; }
      });
      return;
    }

    setState(() {
      if (slot == 1) _searching1 = true; else _searching2 = true;
    });

    try {
      final results = await PokeApiService.searchPokemon(query);
      if (mounted) {
        setState(() {
          if (slot == 1) { _searchResults1 = results.take(8).toList(); _searching1 = false; }
          else { _searchResults2 = results.take(8).toList(); _searching2 = false; }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (slot == 1) _searching1 = false; else _searching2 = false;
        });
      }
    }
  }

  void _selectPokemon(int slot, PokemonBasic pokemon) {
    setState(() {
      if (slot == 1) {
        _search1 = '';
        _searchResults1 = [];
      } else {
        _search2 = '';
        _searchResults2 = [];
      }
    });
    _loadPokemon(slot, pokemon.id);
    // Update URL
    final id1 = slot == 1 ? pokemon.id : _pokemon1?.id;
    final id2 = slot == 2 ? pokemon.id : _pokemon2?.id;
    if (id1 != null && id2 != null) {
      context.go('/battle/$id1/$id2');
    }
  }

  void _switchToEvolution(int slot, EvolutionInfo evo) {
    _loadPokemon(slot, evo.id);
    final id1 = slot == 1 ? evo.id : _pokemon1?.id;
    final id2 = slot == 2 ? evo.id : _pokemon2?.id;
    if (id1 != null && id2 != null) {
      context.go('/battle/$id1/$id2');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Battle Simulator',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compare two Pokemon head-to-head. Analyze type matchups, moves, and stats.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                // Pokemon pickers
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPokemonSlot(1, theme, isDark)),
                      const SizedBox(width: 24),
                      // VS badge
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: _buildVsBadge(theme, isDark),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: _buildPokemonSlot(2, theme, isDark)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildPokemonSlot(1, theme, isDark),
                      const SizedBox(height: 8),
                      _buildVsBadge(theme, isDark),
                      const SizedBox(height: 8),
                      _buildPokemonSlot(2, theme, isDark),
                    ],
                  ),
                // Analysis section
                if (_pokemon1 != null && _pokemon2 != null) ...[
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        _buildAdvantageScore(theme, isDark),
                        const SizedBox(height: 20),
                        _buildTypeAnalysis(theme, isDark, isWide),
                        const SizedBox(height: 20),
                        _buildStatsComparison(theme, isDark),
                        const SizedBox(height: 20),
                        _buildMoveAnalysis(theme, isDark, isWide),
                        const SizedBox(height: 20),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildEvolutionStepper(1, theme, isDark)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildEvolutionStepper(2, theme, isDark)),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildEvolutionStepper(1, theme, isDark),
                              const SizedBox(height: 16),
                              _buildEvolutionStepper(2, theme, isDark),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVsBadge(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.secondary.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'VS',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: theme.colorScheme.primary,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildPokemonSlot(int slot, ThemeData theme, bool isDark) {
    final pokemon = slot == 1 ? _pokemon1 : _pokemon2;
    final loading = slot == 1 ? _loading1 : _loading2;
    final search = slot == 1 ? _search1 : _search2;
    final results = slot == 1 ? _searchResults1 : _searchResults2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Pokemon...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) {
                if (slot == 1) _search1 = v; else _search2 = v;
                _search(slot, v);
              },
            ),
            // Search results
            if (results.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final p = results[i];
                    return ListTile(
                      dense: true,
                      leading: Image.network(p.spriteUrl, width: 32, height: 32,
                        errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 24)),
                      title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(p.idString, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      onTap: () => _selectPokemon(slot, p),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            // Pokemon display
            if (loading)
              SizedBox(
                height: 120,
                child: Center(
                  child: SizedBox(
                    width: 32, height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.primary),
                  ),
                ),
              )
            else if (pokemon != null)
              _PokemonSlotDisplay(pokemon: pokemon, theme: theme, isDark: isDark)
            else
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.catching_pokemon_outlined, size: 40, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                      const SizedBox(height: 8),
                      Text(
                        'Select a Pokemon',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Advantage Score ---
  Widget _buildAdvantageScore(ThemeData theme, bool isDark) {
    final p1 = _pokemon1!;
    final p2 = _pokemon2!;
    final score = _calculateAdvantageScore(p1, p2, _moveDetails1, _moveDetails2);

    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score > 0.5) {
      scoreColor = TypeColors.getColor(p1.types.first.name);
      scoreLabel = '${p1.displayName} has the advantage';
      scoreIcon = Icons.arrow_back_rounded;
    } else if (score < -0.5) {
      scoreColor = TypeColors.getColor(p2.types.first.name);
      scoreLabel = '${p2.displayName} has the advantage';
      scoreIcon = Icons.arrow_forward_rounded;
    } else {
      scoreColor = Colors.orange;
      scoreLabel = 'Evenly matched';
      scoreIcon = Icons.swap_horiz_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.military_tech_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Battle Verdict', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scoreColor.withOpacity(isDark ? 0.15 : 0.08), scoreColor.withOpacity(0.02)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scoreColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(scoreIcon, color: scoreColor, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      scoreLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: isDark ? scoreColor : scoreColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Score breakdown
            _ScoreBar(
              label1: p1.displayName,
              label2: p2.displayName,
              score: score,
              color1: TypeColors.getColor(p1.types.first.name),
              color2: TypeColors.getColor(p2.types.first.name),
              theme: theme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAdvantageScore(PokemonDetail p1, PokemonDetail p2,
      Map<String, MoveDetail>? moves1, Map<String, MoveDetail>? moves2) {
    double score = 0;

    // Type effectiveness (weight: 3)
    final p1Types = p1.types.map((t) => t.name).toList();
    final p2Types = p2.types.map((t) => t.name).toList();

    double p1EffVsP2 = 1;
    for (final at in p1Types) {
      double best = 0;
      for (final dt in p2Types) {
        final eff = TypeChart.getEffectiveness(at, dt);
        if (eff > best) best = eff;
      }
      if (best > p1EffVsP2) p1EffVsP2 = best;
    }

    double p2EffVsP1 = 1;
    for (final at in p2Types) {
      double best = 0;
      for (final dt in p1Types) {
        final eff = TypeChart.getEffectiveness(at, dt);
        if (eff > best) best = eff;
      }
      if (best > p2EffVsP1) p2EffVsP1 = best;
    }

    if (p1EffVsP2 > p2EffVsP1) score += 3;
    else if (p2EffVsP1 > p1EffVsP2) score -= 3;

    // Stats total (weight: 2)
    final p1Total = p1.stats.values.fold(0, (a, b) => a + b);
    final p2Total = p2.stats.values.fold(0, (a, b) => a + b);
    if (p1Total > p2Total + 30) score += 2;
    else if (p2Total > p1Total + 30) score -= 2;

    // Speed advantage (weight: 1.5)
    final p1Speed = p1.stats['speed'] ?? 0;
    final p2Speed = p2.stats['speed'] ?? 0;
    if (p1Speed > p2Speed) score += 1.5;
    else if (p2Speed > p1Speed) score -= 1.5;

    // Move coverage (weight: 2)
    if (moves1 != null && moves2 != null) {
      int p1SuperMoves = 0;
      int p2SuperMoves = 0;

      for (final m in moves1.values) {
        if (m.type == null || m.power == null || m.power == 0) continue;
        for (final dt in p2Types) {
          if (TypeChart.getEffectiveness(m.type!, dt) >= 2) {
            p1SuperMoves++;
            break;
          }
        }
      }

      for (final m in moves2.values) {
        if (m.type == null || m.power == null || m.power == 0) continue;
        for (final dt in p1Types) {
          if (TypeChart.getEffectiveness(m.type!, dt) >= 2) {
            p2SuperMoves++;
            break;
          }
        }
      }

      if (p1SuperMoves > p2SuperMoves) score += 2;
      else if (p2SuperMoves > p1SuperMoves) score -= 2;
    }

    return score.clamp(-10, 10);
  }

  // --- Type Analysis ---
  Widget _buildTypeAnalysis(ThemeData theme, bool isDark, bool isWide) {
    final p1 = _pokemon1!;
    final p2 = _pokemon2!;
    final p1Types = p1.types.map((t) => t.name).toList();
    final p2Types = p2.types.map((t) => t.name).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Type Matchup Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            // P1 attacking P2
            _buildDirectionAnalysis(p1, p2, p1Types, p2Types, theme, isDark),
            const Divider(height: 32),
            // P2 attacking P1
            _buildDirectionAnalysis(p2, p1, p2Types, p1Types, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionAnalysis(PokemonDetail attacker, PokemonDetail defender,
      List<String> atkTypes, List<String> defTypes, ThemeData theme, bool isDark) {

    final results = <Widget>[];
    for (final at in atkTypes) {
      double combined = 1;
      for (final dt in defTypes) {
        combined *= TypeChart.getEffectiveness(at, dt);
      }

      Color effColor;
      String effLabel;
      if (combined >= 4) { effColor = const Color(0xFF22C55E); effLabel = '4x'; }
      else if (combined >= 2) { effColor = const Color(0xFF22C55E); effLabel = '2x'; }
      else if (combined == 0) { effColor = Colors.grey.shade700; effLabel = '0x'; }
      else if (combined <= 0.25) { effColor = const Color(0xFFEF4444); effLabel = '1/4x'; }
      else if (combined <= 0.5) { effColor = const Color(0xFFEF4444); effLabel = '1/2x'; }
      else { effColor = Colors.blueGrey; effLabel = '1x'; }

      results.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            TypeBadge(type: at, fontSize: 11),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(width: 8),
            ...defTypes.map((dt) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TypeBadge(type: dt, fontSize: 11),
            )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: effColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                effLabel,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: effColor),
              ),
            ),
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.network(
              attacker.imageUrl,
              width: 32, height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              '${attacker.displayName} attacking',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...results,
      ],
    );
  }

  // --- Stats Comparison ---
  Widget _buildStatsComparison(ThemeData theme, bool isDark) {
    final p1 = _pokemon1!;
    final p2 = _pokemon2!;
    final statNames = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    final statLabels = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed'];

    final p1Total = p1.stats.values.fold(0, (a, b) => a + b);
    final p2Total = p2.stats.values.fold(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Stats Comparison', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              children: [
                _StatLegend(
                  name: p1.displayName,
                  color: TypeColors.getColor(p1.types.first.name),
                  total: p1Total,
                ),
                const SizedBox(width: 20),
                _StatLegend(
                  name: p2.displayName,
                  color: TypeColors.getColor(p2.types.first.name),
                  total: p2Total,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(statNames.length, (i) {
              final s1 = p1.stats[statNames[i]] ?? 0;
              final s2 = p2.stats[statNames[i]] ?? 0;
              final c1 = TypeColors.getColor(p1.types.first.name);
              final c2 = TypeColors.getColor(p2.types.first.name);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DualStatBar(
                  label: statLabels[i],
                  value1: s1,
                  value2: s2,
                  color1: c1,
                  color2: c2,
                  theme: theme,
                  isDark: isDark,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- Move Analysis ---
  Widget _buildMoveAnalysis(ThemeData theme, bool isDark, bool isWide) {
    final p1 = _pokemon1!;
    final p2 = _pokemon2!;
    final p1Types = p1.types.map((t) => t.name).toList();
    final p2Types = p2.types.map((t) => t.name).toList();

    final p1SuperMoves = _getSuperEffectiveMoves(_moveDetails1, p1Types, p2Types);
    final p2SuperMoves = _getSuperEffectiveMoves(_moveDetails2, p2Types, p1Types);

    Widget buildMoveList(PokemonDetail pokemon, List<_EffectiveMove> moves, ThemeData theme, bool isDark) {
      final color = TypeColors.getColor(pokemon.types.first.name);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.network(pokemon.imageUrl, width: 28, height: 28,
                  errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pokemon.displayName}\'s super effective moves',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${moves.length}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (moves.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'No super effective moves',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
            )
          else
            ...moves.take(8).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    if (m.type != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TypeBadge(type: m.type!, fontSize: 10),
                      ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/moves/${m.rawName}'),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Text(
                            m.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (m.power != null)
                      Text(
                        'Pow: ${m.power}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${m.effectiveMultiplier}x',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF22C55E)),
                      ),
                    ),
                    if (m.isStab) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'STAB',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.amber),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Move Coverage', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: buildMoveList(p1, p1SuperMoves, theme, isDark)),
                  const SizedBox(width: 20),
                  Expanded(child: buildMoveList(p2, p2SuperMoves, theme, isDark)),
                ],
              )
            else
              Column(
                children: [
                  buildMoveList(p1, p1SuperMoves, theme, isDark),
                  const SizedBox(height: 20),
                  buildMoveList(p2, p2SuperMoves, theme, isDark),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<_EffectiveMove> _getSuperEffectiveMoves(
      Map<String, MoveDetail>? moveDetails, List<String> ownTypes, List<String> opponentTypes) {
    if (moveDetails == null) return [];

    final result = <_EffectiveMove>[];
    for (final entry in moveDetails.entries) {
      final m = entry.value;
      if (m.type == null || m.power == null || m.power == 0) continue;

      double multiplier = 1;
      for (final dt in opponentTypes) {
        multiplier *= TypeChart.getEffectiveness(m.type!, dt);
      }

      if (multiplier >= 2) {
        final isStab = ownTypes.contains(m.type);
        result.add(_EffectiveMove(
          name: m.displayName,
          rawName: m.name,
          type: m.type,
          power: m.power,
          effectiveMultiplier: multiplier,
          isStab: isStab,
          effectivePower: (m.power! * multiplier * (isStab ? 1.5 : 1)).round(),
        ));
      }
    }

    result.sort((a, b) => b.effectivePower.compareTo(a.effectivePower));
    return result;
  }

  // --- Evolution Stepper ---
  Widget _buildEvolutionStepper(int slot, ThemeData theme, bool isDark) {
    final evoRoot = slot == 1 ? _evoRoot1 : _evoRoot2;
    final pokemon = slot == 1 ? _pokemon1 : _pokemon2;
    if (evoRoot == null || pokemon == null) return const SizedBox.shrink();
    final allEvos = evoRoot.flatten();
    if (allEvos.length <= 1) return const SizedBox.shrink();

    final color = TypeColors.getColor(pokemon.types.first.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${pokemon.displayName}\'s Evolution Chain',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap an evolution to see how the matchup changes',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 14),
            _buildEvoNode(slot, evoRoot, pokemon.id, color, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEvoNode(int slot, EvolutionInfo node, int currentId, Color color, ThemeData theme, bool isDark) {
    final tile = _buildEvoTile(slot, node, currentId, color, theme, isDark);

    if (node.evolvesTo.isEmpty) return tile;

    // Linear chain
    if (node.evolvesTo.length == 1) {
      final child = node.evolvesTo.first;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  if (child.displayTrigger.isNotEmpty)
                    Text(child.displayTrigger, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                ],
              ),
            ),
            _buildEvoNode(slot, child, currentId, color, theme, isDark),
          ],
        ),
      );
    }

    // Branching chain (e.g. Eevee)
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        tile,
        const SizedBox(height: 6),
        Icon(Icons.call_split_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: node.evolvesTo.map((child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (child.displayTrigger.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(child.displayTrigger, style: TextStyle(fontSize: 8, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      ),
                    _buildEvoNode(slot, child, currentId, color, theme, isDark),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEvoTile(int slot, EvolutionInfo evo, int currentId, Color color, ThemeData theme, bool isDark) {
    final isCurrent = evo.id == currentId;
    final spriteUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${evo.id}.png';

    return GestureDetector(
      onTap: isCurrent ? null : () => _switchToEvolution(slot, evo),
      child: MouseRegion(
        cursor: isCurrent ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isCurrent
                ? color.withOpacity(isDark ? 0.2 : 0.1)
                : isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(spriteUrl, width: 40, height: 40,
                  errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 28)),
              const SizedBox(height: 2),
              Text(
                evo.displayName,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 10,
                  color: isCurrent ? color : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokemonSlotDisplay extends StatelessWidget {
  final PokemonDetail pokemon;
  final ThemeData theme;
  final bool isDark;

  const _PokemonSlotDisplay({required this.pokemon, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = TypeColors.getColor(pokemon.types.first.name);

    return Column(
      children: [
        // Image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.03)],
            ),
            shape: BoxShape.circle,
          ),
          child: Image.network(
            pokemon.imageUrl,
            width: 100,
            height: 100,
            errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, size: 48, color: color.withOpacity(0.3)),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.go('/pokemon/${pokemon.id}'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              pokemon.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
          ),
        ),
        Text(
          pokemon.idString,
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: pokemon.types.map((t) => TypeBadge(type: t.name, fontSize: 11)).toList(),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label1;
  final String label2;
  final double score; // -10 to 10
  final Color color1;
  final Color color2;
  final ThemeData theme;
  final bool isDark;

  const _ScoreBar({
    required this.label1, required this.label2, required this.score,
    required this.color1, required this.color2, required this.theme, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (score + 10) / 20; // 0 to 1

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label1, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color1)),
            Text(label2, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color2)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: (normalized * 100).round().clamp(5, 95),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color1, color1.withOpacity(0.7)]),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - normalized) * 100).round().clamp(5, 95),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color2.withOpacity(0.7), color2]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatLegend extends StatelessWidget {
  final String name;
  final Color color;
  final int total;

  const _StatLegend({required this.name, required this.color, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
        const SizedBox(width: 4),
        Text('($total)', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
      ],
    );
  }
}

class _DualStatBar extends StatelessWidget {
  final String label;
  final int value1;
  final int value2;
  final Color color1;
  final Color color2;
  final ThemeData theme;
  final bool isDark;

  const _DualStatBar({
    required this.label, required this.value1, required this.value2,
    required this.color1, required this.color2, required this.theme, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const maxStat = 255;
    final pct1 = (value1 / maxStat).clamp(0.0, 1.0);
    final pct2 = (value2 / maxStat).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value1',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: value1 > value2 ? color1 : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Container(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100),
                  FractionallySizedBox(
                    widthFactor: pct1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color1, color1.withOpacity(0.7)]),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: pct2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: color2, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$value2',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: value2 > value1 ? color2 : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _EffectiveMove {
  final String name;
  final String rawName;
  final String? type;
  final int? power;
  final double effectiveMultiplier;
  final bool isStab;
  final int effectivePower;

  _EffectiveMove({
    required this.name,
    required this.rawName,
    this.type,
    this.power,
    required this.effectiveMultiplier,
    required this.isStab,
    required this.effectivePower,
  });
}
