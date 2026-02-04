import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';

/// Pokemon stat calculator with EV/IV/Nature inputs.
/// Calculates actual stats at levels 50 and 100.
class StatCalculatorScreen extends StatefulWidget {
  final int? pokemonId;
  const StatCalculatorScreen({super.key, this.pokemonId});

  @override
  State<StatCalculatorScreen> createState() => _StatCalculatorScreenState();
}

class _StatCalculatorScreenState extends State<StatCalculatorScreen> {
  PokemonDetail? _pokemon;
  bool _loading = false;
  String _searchQuery = '';
  List<PokemonBasic> _searchResults = [];

  int _level = 50;
  final Map<String, int> _evs = {};
  final Map<String, int> _ivs = {};
  String _nature = 'Adamant';

  static const _statKeys = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
  static const _statLabels = {
    'hp': 'HP', 'attack': 'Attack', 'defense': 'Defense',
    'special-attack': 'Sp. Atk', 'special-defense': 'Sp. Def', 'speed': 'Speed',
  };

  static const Map<String, Map<String, double>> _natures = {
    'Hardy':   {},
    'Lonely':  {'attack': 1.1, 'defense': 0.9},
    'Brave':   {'attack': 1.1, 'speed': 0.9},
    'Adamant': {'attack': 1.1, 'special-attack': 0.9},
    'Naughty': {'attack': 1.1, 'special-defense': 0.9},
    'Bold':    {'defense': 1.1, 'attack': 0.9},
    'Docile':  {},
    'Relaxed': {'defense': 1.1, 'speed': 0.9},
    'Impish':  {'defense': 1.1, 'special-attack': 0.9},
    'Lax':     {'defense': 1.1, 'special-defense': 0.9},
    'Timid':   {'speed': 1.1, 'attack': 0.9},
    'Hasty':   {'speed': 1.1, 'defense': 0.9},
    'Serious': {},
    'Jolly':   {'speed': 1.1, 'special-attack': 0.9},
    'Naive':   {'speed': 1.1, 'special-defense': 0.9},
    'Modest':  {'special-attack': 1.1, 'attack': 0.9},
    'Mild':    {'special-attack': 1.1, 'defense': 0.9},
    'Quiet':   {'special-attack': 1.1, 'speed': 0.9},
    'Bashful': {},
    'Rash':    {'special-attack': 1.1, 'special-defense': 0.9},
    'Calm':    {'special-defense': 1.1, 'attack': 0.9},
    'Gentle':  {'special-defense': 1.1, 'defense': 0.9},
    'Sassy':   {'special-defense': 1.1, 'speed': 0.9},
    'Careful': {'special-defense': 1.1, 'special-attack': 0.9},
    'Quirky':  {},
  };

  @override
  void initState() {
    super.initState();
    for (final s in _statKeys) {
      _evs[s] = 0;
      _ivs[s] = 31;
    }
    if (widget.pokemonId != null) _loadPokemon(widget.pokemonId!);
  }

  Future<void> _loadPokemon(int id) async {
    setState(() => _loading = true);
    try {
      final detail = await PokeApiService.getPokemonDetail(id);
      if (mounted) setState(() { _pokemon = detail; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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

  int _calcStat(String stat, int baseStat, int level) {
    final iv = _ivs[stat] ?? 31;
    final ev = _evs[stat] ?? 0;
    final natureMultipliers = _natures[_nature] ?? {};
    final natureMod = natureMultipliers[stat] ?? 1.0;

    if (stat == 'hp') {
      if (baseStat == 1) return 1; // Shedinja
      return ((((2 * baseStat + iv + (ev ~/ 4)) * level) ~/ 100) + level + 10);
    }
    return (((((2 * baseStat + iv + (ev ~/ 4)) * level) ~/ 100) + 5) * natureMod).floor();
  }

  int get _totalEvs => _evs.values.fold(0, (a, b) => a + b);

  void _setPreset(String preset) {
    setState(() {
      for (final s in _statKeys) { _evs[s] = 0; _ivs[s] = 31; }
      switch (preset) {
        case 'competitive_physical':
          _evs['attack'] = 252; _evs['speed'] = 252; _evs['hp'] = 4;
          _nature = 'Adamant';
          break;
        case 'competitive_special':
          _evs['special-attack'] = 252; _evs['speed'] = 252; _evs['hp'] = 4;
          _nature = 'Modest';
          break;
        case 'competitive_bulky':
          _evs['hp'] = 252; _evs['defense'] = 128; _evs['special-defense'] = 128;
          _nature = 'Bold';
          break;
        case 'competitive_fast':
          _evs['speed'] = 252; _evs['attack'] = 252; _evs['hp'] = 4;
          _nature = 'Jolly';
          break;
        case 'max_ivs':
          for (final s in _statKeys) _ivs[s] = 31;
          break;
        case 'zero_ivs':
          for (final s in _statKeys) _ivs[s] = 0;
          break;
      }
    });
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
                Text('Stat Calculator',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Calculate actual stats with EVs, IVs, and Nature at any level.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 24),
                // Pokemon picker
                _buildPokemonPicker(theme, isDark),
                if (_pokemon != null) ...[
                  const SizedBox(height: 20),
                  _buildControls(theme, isDark),
                  const SizedBox(height: 20),
                  _buildStatTable(theme, isDark),
                  const SizedBox(height: 20),
                  _buildShowdownExport(theme, isDark),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPokemonPicker(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Pokemon...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
              onChanged: (v) {
                _searchQuery = v;
                _search(v);
              },
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
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (_, i) {
                    final p = _searchResults[i];
                    return ListTile(
                      dense: true,
                      leading: Image.network(p.spriteUrl, width: 32, height: 32,
                          errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 24)),
                      title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(p.idString, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      onTap: () {
                        setState(() { _searchResults = []; _searchQuery = ''; });
                        _loadPokemon(p.id);
                      },
                    );
                  },
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_pokemon != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: TypeColors.getColor(_pokemon!.types.first.name).withOpacity(isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.network(_pokemon!.imageUrl, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 40)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/pokemon/${_pokemon!.id}'),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(_pokemon!.displayName, style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 20,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: theme.colorScheme.primary.withOpacity(0.3),
                              )),
                            ),
                          ),
                          Text(_pokemon!.idString, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: _pokemon!.types.map((t) => TypeBadge(type: t.name, fontSize: 11)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isDark) {
    final natureData = _natures[_nature] ?? {};
    String? boosted, lowered;
    for (final e in natureData.entries) {
      if (e.value > 1) boosted = e.key;
      if (e.value < 1) lowered = e.key;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // Level
            Row(
              children: [
                Text('Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(width: 16),
                _LevelChip(level: 1, selected: _level == 1, onTap: () => setState(() => _level = 1)),
                _LevelChip(level: 50, selected: _level == 50, onTap: () => setState(() => _level = 50)),
                _LevelChip(level: 100, selected: _level == 100, onTap: () => setState(() => _level = 100)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 70,
                  child: TextField(
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: TextEditingController(text: '$_level'),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 1 && n <= 100) setState(() => _level = n);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nature
            Row(
              children: [
                Text('Nature', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _nature,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: _natures.keys.map((n) {
                      final nd = _natures[n]!;
                      String? up, down;
                      for (final e in nd.entries) {
                        if (e.value > 1) up = _statLabels[e.key];
                        if (e.value < 1) down = _statLabels[e.key];
                      }
                      final suffix = up != null ? ' (+$up / -$down)' : ' (Neutral)';
                      return DropdownMenuItem(value: n, child: Text('$n$suffix', style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (v) { if (v != null) setState(() => _nature = v); },
                  ),
                ),
              ],
            ),
            if (boosted != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.green),
                    Text(' ${_statLabels[boosted]}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.red),
                    Text(' ${_statLabels[lowered]}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // EV presets
            Text('EV Presets', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PresetChip(label: 'Physical Attacker', onTap: () => _setPreset('competitive_physical')),
                _PresetChip(label: 'Special Attacker', onTap: () => _setPreset('competitive_special')),
                _PresetChip(label: 'Bulky', onTap: () => _setPreset('competitive_bulky')),
                _PresetChip(label: 'Fast Physical', onTap: () => _setPreset('competitive_fast')),
                _PresetChip(label: 'Max IVs', onTap: () => _setPreset('max_ivs')),
                _PresetChip(label: 'Zero IVs', onTap: () => _setPreset('zero_ivs')),
              ],
            ),
            const SizedBox(height: 12),
            // Total EVs
            Row(
              children: [
                Text('Total EVs: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                Text('$_totalEvs / 510', style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13,
                  color: _totalEvs > 510 ? Colors.red : theme.colorScheme.primary,
                )),
                if (_totalEvs > 510)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTable(ThemeData theme, bool isDark) {
    final p = _pokemon!;
    final natureData = _natures[_nature] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Calculated Stats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Level $_level', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: theme.colorScheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Header row
            Row(
              children: [
                const SizedBox(width: 72),
                _headerCell('Base', theme),
                _headerCell('IV', theme),
                _headerCell('EV', theme),
                Expanded(child: Center(child: Text('Final', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))))),
                const SizedBox(width: 60),
              ],
            ),
            const Divider(height: 16),
            ...List.generate(_statKeys.length, (i) {
              final stat = _statKeys[i];
              final base = p.stats[stat] ?? 0;
              final natureMod = natureData[stat] ?? 1.0;
              final finalStat = _calcStat(stat, base, _level);

              Color natureColor = theme.colorScheme.onSurface;
              String natureIndicator = '';
              if (natureMod > 1) { natureColor = Colors.green; natureIndicator = '+'; }
              else if (natureMod < 1) { natureColor = Colors.red; natureIndicator = '-'; }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statLabels[stat]!,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: natureColor),
                            ),
                          ),
                          if (natureIndicator.isNotEmpty)
                            Text(natureIndicator, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: natureColor)),
                        ],
                      ),
                    ),
                    _valueCell('$base', theme),
                    // IV input
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: TextEditingController(text: '${_ivs[stat]}'),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n >= 0 && n <= 31) setState(() => _ivs[stat] = n);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // EV slider + input
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: TextField(
                              controller: TextEditingController(text: '${_evs[stat]}'),
                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (n != null && n >= 0 && n <= 252) setState(() => _evs[stat] = n);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                activeTrackColor: theme.colorScheme.primary,
                                inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.15),
                                thumbColor: theme.colorScheme.primary,
                              ),
                              child: Slider(
                                value: (_evs[stat] ?? 0).toDouble(),
                                min: 0, max: 252,
                                divisions: 63,
                                onChanged: (v) => setState(() => _evs[stat] = (v / 4).round() * 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Final stat
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _getStatColor(finalStat).withOpacity(isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$finalStat',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _getStatColor(finalStat)),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 16),
            // Total row
            Row(
              children: [
                const SizedBox(width: 72, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                _valueCell('${p.stats.values.fold(0, (a, b) => a + b)}', theme),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_statKeys.map((s) => _calcStat(s, p.stats[s] ?? 0, _level)).fold(0, (a, b) => a + b)}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowdownExport(ThemeData theme, bool isDark) {
    if (_pokemon == null) return const SizedBox.shrink();
    final p = _pokemon!;
    final natureData = _natures[_nature] ?? {};
    String? boosted;
    for (final e in natureData.entries) {
      if (e.value > 1) boosted = e.key;
    }

    final evParts = <String>[];
    for (final s in _statKeys) {
      if ((_evs[s] ?? 0) > 0) {
        evParts.add('${_evs[s]} ${_statLabels[s]}');
      }
    }

    final ivParts = <String>[];
    for (final s in _statKeys) {
      if ((_ivs[s] ?? 31) != 31) {
        ivParts.add('${_ivs[s]} ${_statLabels[s]}');
      }
    }

    final buffer = StringBuffer();
    buffer.writeln(p.displayName);
    buffer.writeln('Level: $_level');
    if (evParts.isNotEmpty) buffer.writeln('EVs: ${evParts.join(' / ')}');
    buffer.writeln('$_nature Nature');
    if (ivParts.isNotEmpty) buffer.writeln('IVs: ${ivParts.join(' / ')}');

    final paste = buffer.toString().trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Showdown Format', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy to clipboard',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paste));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
              ),
              child: SelectableText(
                paste,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatColor(int stat) {
    if (stat < 60) return const Color(0xFFEF4444);
    if (stat < 100) return const Color(0xFFF97316);
    if (stat < 150) return const Color(0xFFEAB308);
    if (stat < 200) return const Color(0xFF22C55E);
    return const Color(0xFF06B6D4);
  }

  Widget _headerCell(String label, ThemeData theme) {
    return SizedBox(
      width: 56,
      child: Center(
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
      ),
    );
  }

  Widget _valueCell(String value, ThemeData theme) {
    return SizedBox(
      width: 56,
      child: Center(
        child: Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7))),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final int level;
  final bool selected;
  final VoidCallback onTap;
  const _LevelChip({required this.level, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Lv.$level',
              style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12,
                color: selected ? Colors.white : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: theme.colorScheme.primary)),
        ),
      ),
    );
  }
}
