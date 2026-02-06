import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../models/move.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';
import '../widgets/transparent_pokemon_image.dart';

/// Showdown-style damage calculator.
/// Uses Gen V+ damage formula with STAB, type effectiveness, crits.
class DamageCalculatorScreen extends StatefulWidget {
  const DamageCalculatorScreen({super.key});

  @override
  State<DamageCalculatorScreen> createState() => _DamageCalculatorScreenState();
}

class _DamageCalculatorScreenState extends State<DamageCalculatorScreen> {
  // Attacker
  PokemonDetail? _attacker;
  bool _loadingAttacker = false;
  List<PokemonBasic> _atkResults = [];
  int _atkLevel = 50;
  final Map<String, int> _atkEvs = {};
  final Map<String, int> _atkIvs = {};
  String _atkNature = 'Adamant';
  int _atkBoost = 0; // stat stages -6 to +6

  // Defender
  PokemonDetail? _defender;
  bool _loadingDefender = false;
  List<PokemonBasic> _defResults = [];
  int _defLevel = 50;
  final Map<String, int> _defEvs = {};
  final Map<String, int> _defIvs = {};
  String _defNature = 'Bold';
  int _defBoost = 0;

  // Move
  MoveDetail? _selectedMove;
  List<MoveDetail> _atkMoveDetails = [];
  bool _loadingMoves = false;

  // Options
  bool _isCrit = false;
  double _weather = 1.0; // 1.5 sun for fire, 1.5 rain for water, etc.
  String _weatherLabel = 'None';
  bool _isStab = false; // auto-calculated
  bool _isBurned = false;

  static const _statKeys = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
  static const Map<String, Map<String, double>> _natures = {
    'Hardy': {}, 'Lonely': {'attack': 1.1, 'defense': 0.9},
    'Brave': {'attack': 1.1, 'speed': 0.9}, 'Adamant': {'attack': 1.1, 'special-attack': 0.9},
    'Naughty': {'attack': 1.1, 'special-defense': 0.9}, 'Bold': {'defense': 1.1, 'attack': 0.9},
    'Docile': {}, 'Relaxed': {'defense': 1.1, 'speed': 0.9},
    'Impish': {'defense': 1.1, 'special-attack': 0.9}, 'Lax': {'defense': 1.1, 'special-defense': 0.9},
    'Timid': {'speed': 1.1, 'attack': 0.9}, 'Hasty': {'speed': 1.1, 'defense': 0.9},
    'Serious': {}, 'Jolly': {'speed': 1.1, 'special-attack': 0.9},
    'Naive': {'speed': 1.1, 'special-defense': 0.9}, 'Modest': {'special-attack': 1.1, 'attack': 0.9},
    'Mild': {'special-attack': 1.1, 'defense': 0.9}, 'Quiet': {'special-attack': 1.1, 'speed': 0.9},
    'Bashful': {}, 'Rash': {'special-attack': 1.1, 'special-defense': 0.9},
    'Calm': {'special-defense': 1.1, 'attack': 0.9}, 'Gentle': {'special-defense': 1.1, 'defense': 0.9},
    'Sassy': {'special-defense': 1.1, 'speed': 0.9}, 'Careful': {'special-defense': 1.1, 'special-attack': 0.9},
    'Quirky': {},
  };

  @override
  void initState() {
    super.initState();
    for (final s in _statKeys) {
      _atkEvs[s] = 252; _atkIvs[s] = 31;
      _defEvs[s] = 252; _defIvs[s] = 31;
    }
    // Default common spreads
    _atkEvs['hp'] = 0; _atkEvs['defense'] = 0; _atkEvs['special-defense'] = 0;
    _atkEvs['special-attack'] = 0; _atkEvs['attack'] = 252; _atkEvs['speed'] = 252;
    _defEvs['attack'] = 0; _defEvs['special-attack'] = 0; _defEvs['speed'] = 0;
    _defEvs['hp'] = 252; _defEvs['defense'] = 252; _defEvs['special-defense'] = 4;
    // Pre-load active Pokemon as attacker
    final active = AppState().activePokemon;
    if (active != null) {
      _attacker = active;
      _loadAttackerMoves(active);
    }
  }

  int _calcStat(String stat, int baseStat, int level, Map<String, int> evs, Map<String, int> ivs, String nature) {
    final iv = ivs[stat] ?? 31;
    final ev = evs[stat] ?? 0;
    final natureMultipliers = _natures[nature] ?? {};
    final natureMod = natureMultipliers[stat] ?? 1.0;
    if (stat == 'hp') {
      if (baseStat == 1) return 1;
      return ((((2 * baseStat + iv + (ev ~/ 4)) * level) ~/ 100) + level + 10);
    }
    return (((((2 * baseStat + iv + (ev ~/ 4)) * level) ~/ 100) + 5) * natureMod).floor();
  }

  double _stageMultiplier(int stage) {
    if (stage >= 0) return (2 + stage) / 2;
    return 2 / (2 - stage);
  }

  /// Gen V+ damage formula
  _DamageResult _calculateDamage() {
    if (_attacker == null || _defender == null || _selectedMove == null) {
      return _DamageResult.empty();
    }
    final move = _selectedMove!;
    final power = move.power ?? 0;
    if (power == 0) return _DamageResult.empty();

    final isPhysical = move.damageClass == 'physical';
    final atkStatKey = isPhysical ? 'attack' : 'special-attack';
    final defStatKey = isPhysical ? 'defense' : 'special-defense';

    final atkBase = _attacker!.stats[atkStatKey] ?? 0;
    final defBase = _defender!.stats[defStatKey] ?? 0;

    final atkStat = (_calcStat(atkStatKey, atkBase, _atkLevel, _atkEvs, _atkIvs, _atkNature) *
        _stageMultiplier(_atkBoost)).floor();
    final defStat = (_calcStat(defStatKey, defBase, _defLevel, _defEvs, _defIvs, _defNature) *
        _stageMultiplier(_defBoost)).floor();
    final defHp = _calcStat('hp', _defender!.stats['hp'] ?? 0, _defLevel, _defEvs, _defIvs, _defNature);

    // STAB
    final atkTypes = _attacker!.types.map((t) => t.name).toList();
    final isStab = atkTypes.contains(move.type);
    final stabMod = isStab ? 1.5 : 1.0;

    // Type effectiveness
    final defTypes = _defender!.types.map((t) => t.name).toList();
    double typeEff = 1.0;
    for (final dt in defTypes) {
      typeEff *= TypeChart.getEffectiveness(move.type ?? '', dt);
    }

    // Critical
    final critMod = _isCrit ? 1.5 : 1.0;

    // Burn (halves physical)
    final burnMod = (_isBurned && isPhysical) ? 0.5 : 1.0;

    // Weather
    double weatherMod = 1.0;
    if (_weatherLabel == 'Sun' && move.type == 'fire') weatherMod = 1.5;
    if (_weatherLabel == 'Sun' && move.type == 'water') weatherMod = 0.5;
    if (_weatherLabel == 'Rain' && move.type == 'water') weatherMod = 1.5;
    if (_weatherLabel == 'Rain' && move.type == 'fire') weatherMod = 0.5;

    // Formula: ((((2*Level/5+2) * Power * A/D) / 50) + 2) * Modifiers
    final baseDamage = (((2.0 * _atkLevel / 5 + 2) * power * atkStat / defStat) / 50 + 2);
    final modifier = stabMod * typeEff * critMod * burnMod * weatherMod;

    // Random roll range: 85% to 100%
    final minDmg = (baseDamage * modifier * 0.85).floor().clamp(1, 99999);
    final maxDmg = (baseDamage * modifier * 1.0).floor().clamp(1, 99999);

    final minPct = (minDmg / defHp * 100);
    final maxPct = (maxDmg / defHp * 100);

    // How many hits to KO
    int hitsToKo = 0;
    if (maxDmg > 0) {
      double hp = defHp.toDouble();
      while (hp > 0 && hitsToKo < 10) {
        hp -= (minDmg + maxDmg) / 2; // average
        hitsToKo++;
      }
    }

    return _DamageResult(
      minDamage: minDmg, maxDamage: maxDmg,
      minPercent: minPct, maxPercent: maxPct,
      defHp: defHp, hitsToKo: hitsToKo,
      typeEffectiveness: typeEff, isStab: isStab,
      isCrit: _isCrit,
    );
  }

  Future<void> _searchPokemon(int slot, String query) async {
    if (query.length < 2) {
      setState(() { if (slot == 1) _atkResults = []; else _defResults = []; });
      return;
    }
    try {
      final results = await PokeApiService.searchPokemon(query);
      if (mounted) {
        setState(() { if (slot == 1) _atkResults = results.take(6).toList(); else _defResults = results.take(6).toList(); });
      }
    } catch (_) {}
  }

  Future<void> _loadPokemon(int slot, int id) async {
    setState(() { if (slot == 1) _loadingAttacker = true; else _loadingDefender = true; });
    try {
      final detail = await PokeApiService.getPokemonDetail(id);
      if (mounted) {
        setState(() {
          if (slot == 1) {
            _attacker = detail;
            _loadingAttacker = false;
            _atkResults = [];
          } else {
            _defender = detail;
            _loadingDefender = false;
            _defResults = [];
          }
        });
        if (slot == 1) _loadAttackerMoves(detail);
      }
    } catch (_) {
      if (mounted) setState(() { if (slot == 1) _loadingAttacker = false; else _loadingDefender = false; });
    }
  }

  Future<void> _loadAttackerMoves(PokemonDetail pokemon) async {
    setState(() => _loadingMoves = true);
    final moves = <MoveDetail>[];
    final damagingMoves = pokemon.moves
        .where((m) => m.learnMethod == 'level-up' || m.learnMethod == 'machine')
        .take(30)
        .toList();

    for (final m in damagingMoves) {
      try {
        final detail = await PokeApiService.getMoveDetail(m.name);
        if (detail.power != null && detail.power! > 0) moves.add(detail);
      } catch (_) {}
    }
    moves.sort((a, b) => (b.power ?? 0).compareTo(a.power ?? 0));
    if (mounted) {
      setState(() {
        _atkMoveDetails = moves;
        _loadingMoves = false;
        if (moves.isNotEmpty) _selectedMove = moves.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Damage Calculator', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Showdown-style damage calculator with EVs, IVs, natures, and modifiers.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 24),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPokemonColumn(1, theme, isDark)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildPokemonColumn(2, theme, isDark)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildPokemonColumn(1, theme, isDark),
                      const SizedBox(height: 16),
                      _buildPokemonColumn(2, theme, isDark),
                    ],
                  ),
                const SizedBox(height: 20),
                _buildMoveSelector(theme, isDark),
                const SizedBox(height: 20),
                _buildModifiers(theme, isDark),
                const SizedBox(height: 20),
                _buildResult(theme, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPokemonColumn(int slot, ThemeData theme, bool isDark) {
    final pokemon = slot == 1 ? _attacker : _defender;
    final loading = slot == 1 ? _loadingAttacker : _loadingDefender;
    final results = slot == 1 ? _atkResults : _defResults;
    final label = slot == 1 ? 'Attacker' : 'Defender';
    final level = slot == 1 ? _atkLevel : _defLevel;
    final nature = slot == 1 ? _atkNature : _defNature;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // Search
            TextField(
              decoration: InputDecoration(hintText: 'Search $label...', prefixIcon: const Icon(Icons.search_rounded, size: 20), isDense: true),
              onChanged: (v) => _searchPokemon(slot, v),
            ),
            if (results.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                ),
                child: ListView.builder(
                  shrinkWrap: true, itemCount: results.length,
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    leading: Image.network(results[i].spriteUrl, width: 28, height: 28,
                        errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 20)),
                    title: Text(results[i].displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    onTap: () => _loadPokemon(slot, results[i].id),
                  ),
                ),
              ),
            if (loading) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            if (pokemon != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  AppState().transparentBackgrounds
                      ? TransparentPokemonImage(
                          imageUrl: pokemon.imageUrl,
                          width: 56, height: 56,
                          errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 36),
                        )
                      : Image.network(pokemon.imageUrl, width: 56, height: 56,
                          errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pokemon.displayName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.onSurface)),
                        Wrap(spacing: 4, children: pokemon.types.map((t) => TypeBadge(type: t.name, fontSize: 10)).toList()),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Level + Nature
              Row(
                children: [
                  Text('Lv.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: TextEditingController(text: '$level'),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n >= 1 && n <= 100) {
                          setState(() { if (slot == 1) _atkLevel = n; else _defLevel = n; });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: nature, isExpanded: true,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      items: _natures.keys.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() { if (slot == 1) _atkNature = v; else _defNature = v; });
                      },
                    ),
                  ),
                ],
              ),
              // Stat boost (attacker gets offensive boost, defender gets defensive)
              if (slot == 1) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Atk boost:', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    Expanded(
                      child: Slider(
                        value: _atkBoost.toDouble(), min: -6, max: 6, divisions: 12,
                        label: _atkBoost >= 0 ? '+$_atkBoost' : '$_atkBoost',
                        onChanged: (v) => setState(() => _atkBoost = v.round()),
                      ),
                    ),
                    Text('${_atkBoost >= 0 ? "+" : ""}$_atkBoost', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: theme.colorScheme.primary)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Def boost:', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    Expanded(
                      child: Slider(
                        value: _defBoost.toDouble(), min: -6, max: 6, divisions: 12,
                        label: _defBoost >= 0 ? '+$_defBoost' : '$_defBoost',
                        onChanged: (v) => setState(() => _defBoost = v.round()),
                      ),
                    ),
                    Text('${_defBoost >= 0 ? "+" : ""}$_defBoost', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: theme.colorScheme.primary)),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoveSelector(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Move', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingMoves)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_atkMoveDetails.isEmpty)
              Text(_attacker == null ? 'Select an attacker first' : 'No damaging moves found',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)))
            else
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _atkMoveDetails.map((m) {
                  final isSelected = _selectedMove?.name == m.name;
                  final moveColor = m.type != null ? TypeColors.getColor(m.type!) : Colors.grey;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMove = m),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? moveColor.withOpacity(isDark ? 0.25 : 0.15) : isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? moveColor : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (m.type != null) ...[
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(color: moveColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(m.displayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isSelected ? moveColor : theme.colorScheme.onSurface)),
                              ],
                            ),
                            Text(
                              '${m.damageClass ?? "?"} | ${m.power ?? "—"} BP',
                              style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifiers(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifiers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12, runSpacing: 8,
              children: [
                _ModifierToggle(label: 'Critical Hit', value: _isCrit, onChanged: (v) => setState(() => _isCrit = v)),
                _ModifierToggle(label: 'Burned', value: _isBurned, onChanged: (v) => setState(() => _isBurned = v)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weather:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: ['None', 'Sun', 'Rain', 'Sand', 'Hail'].map((w) => GestureDetector(
                    onTap: () => setState(() => _weatherLabel = w),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _weatherLabel == w ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(w, style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 11,
                          color: _weatherLabel == w ? Colors.white : theme.colorScheme.primary,
                        )),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ThemeData theme, bool isDark) {
    final result = _calculateDamage();

    if (result.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Select both Pokemon and a move to calculate damage',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ),
        ),
      );
    }

    Color resultColor;
    String koLabel;
    if (result.maxPercent >= 100) {
      resultColor = const Color(0xFFEF4444);
      koLabel = result.minPercent >= 100 ? 'Guaranteed OHKO' : 'Possible OHKO (${result.minPercent.toStringAsFixed(1)}% - ${result.maxPercent.toStringAsFixed(1)}%)';
    } else if (result.hitsToKo <= 2) {
      resultColor = const Color(0xFFF97316);
      koLabel = '${result.hitsToKo}HKO';
    } else if (result.hitsToKo <= 4) {
      resultColor = const Color(0xFFEAB308);
      koLabel = '${result.hitsToKo}HKO';
    } else {
      resultColor = const Color(0xFF22C55E);
      koLabel = '${result.hitsToKo}HKO';
    }

    // Type effectiveness label
    String effLabel;
    if (result.typeEffectiveness == 0) effLabel = 'Immune';
    else if (result.typeEffectiveness >= 4) effLabel = 'Super effective (4x)';
    else if (result.typeEffectiveness >= 2) effLabel = 'Super effective (2x)';
    else if (result.typeEffectiveness <= 0.25) effLabel = 'Not very effective (1/4x)';
    else if (result.typeEffectiveness <= 0.5) effLabel = 'Not very effective (1/2x)';
    else effLabel = 'Neutral';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Result', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            // Main result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [resultColor.withOpacity(isDark ? 0.15 : 0.08), resultColor.withOpacity(0.02)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: resultColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.minDamage} - ${result.maxDamage}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: resultColor),
                  ),
                  Text(
                    '${result.minPercent.toStringAsFixed(1)}% - ${result.maxPercent.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: resultColor.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(koLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: resultColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // HP bar
            Row(
              children: [
                Text('HP: ${result.defHp}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 12,
                      child: Stack(
                        children: [
                          Container(color: const Color(0xFF22C55E).withOpacity(0.2)),
                          FractionallySizedBox(
                            widthFactor: ((result.defHp - (result.minDamage + result.maxDamage) / 2) / result.defHp).clamp(0, 1),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF4ADE80)]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Breakdown
            Wrap(
              spacing: 12, runSpacing: 6,
              children: [
                _ResultBadge(label: effLabel, color: result.typeEffectiveness > 1 ? const Color(0xFF22C55E) : result.typeEffectiveness < 1 ? const Color(0xFFEF4444) : Colors.blueGrey),
                if (result.isStab) _ResultBadge(label: 'STAB (1.5x)', color: Colors.amber),
                if (result.isCrit) _ResultBadge(label: 'Critical (1.5x)', color: Colors.orange),
                if (_isBurned && _selectedMove?.damageClass == 'physical') _ResultBadge(label: 'Burned (0.5x)', color: Colors.red),
                if (_weatherLabel != 'None') _ResultBadge(label: _weatherLabel, color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModifierToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ModifierToggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20, height: 20,
          child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7))),
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ResultBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: color)),
    );
  }
}

class _DamageResult {
  final int minDamage, maxDamage, defHp, hitsToKo;
  final double minPercent, maxPercent, typeEffectiveness;
  final bool isStab, isCrit, isEmpty;

  _DamageResult({
    required this.minDamage, required this.maxDamage,
    required this.minPercent, required this.maxPercent,
    required this.defHp, required this.hitsToKo,
    required this.typeEffectiveness, required this.isStab,
    required this.isCrit, this.isEmpty = false,
  });

  factory _DamageResult.empty() => _DamageResult(
    minDamage: 0, maxDamage: 0, minPercent: 0, maxPercent: 0,
    defHp: 0, hitsToKo: 0, typeEffectiveness: 1, isStab: false, isCrit: false, isEmpty: true,
  );
}
