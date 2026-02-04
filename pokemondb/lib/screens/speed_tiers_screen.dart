import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';

/// Speed tier comparison tool.
/// "Will my Garchomp outspeed their Dragapult with this spread?"
class SpeedTiersScreen extends StatefulWidget {
  const SpeedTiersScreen({super.key});

  @override
  State<SpeedTiersScreen> createState() => _SpeedTiersScreenState();
}

class _SpeedTiersScreenState extends State<SpeedTiersScreen> {
  List<_SpeedEntry> _entries = [];
  bool _loading = false;
  int _level = 50;
  bool _showAll = false; // show common competitive pokemon

  // Custom add
  List<PokemonBasic> _searchResults = [];
  final Set<int> _addedIds = {};

  static const Map<String, Map<String, double>> _natures = {
    'Jolly': {'speed': 1.1, 'special-attack': 0.9},
    'Timid': {'speed': 1.1, 'attack': 0.9},
    'Adamant': {'attack': 1.1, 'special-attack': 0.9},
    'Modest': {'special-attack': 1.1, 'attack': 0.9},
    'Bold': {'defense': 1.1, 'attack': 0.9},
    'Brave': {'attack': 1.1, 'speed': 0.9},
    'Quiet': {'special-attack': 1.1, 'speed': 0.9},
    'Relaxed': {'defense': 1.1, 'speed': 0.9},
    'Sassy': {'special-defense': 1.1, 'speed': 0.9},
  };

  @override
  void initState() {
    super.initState();
    _loadTeamEntries().then((_) {
      // Also add active Pokemon if not already on team
      final active = AppState().activePokemon;
      if (active != null && !_addedIds.contains(active.id) && !AppState().team.contains(active.id)) {
        _addPokemon(PokemonBasic(id: active.id, name: active.name, url: ''));
      }
    });
  }

  int _calcSpeed(int base, int level, int ev, int iv, double natureMod) {
    return (((((2 * base + iv + (ev ~/ 4)) * level) ~/ 100) + 5) * natureMod).floor();
  }

  Future<void> _loadTeamEntries() async {
    final teamIds = AppState().team;
    if (teamIds.isEmpty) return;

    setState(() => _loading = true);
    final entries = <_SpeedEntry>[];

    for (final id in teamIds) {
      try {
        final detail = await PokeApiService.getPokemonDetail(id);
        final baseSpeed = detail.stats['speed'] ?? 0;

        // Add multiple common speed configurations
        entries.add(_SpeedEntry(
          pokemon: detail,
          label: '${detail.displayName} (Max Speed)',
          speed: _calcSpeed(baseSpeed, _level, 252, 31, 1.1),
          config: '+Spe 252 EVs',
          isTeam: true,
        ));
        entries.add(_SpeedEntry(
          pokemon: detail,
          label: '${detail.displayName} (Neutral)',
          speed: _calcSpeed(baseSpeed, _level, 0, 31, 1.0),
          config: 'No EVs',
          isTeam: true,
        ));
      } catch (_) {}
    }

    entries.sort((a, b) => b.speed.compareTo(a.speed));
    if (mounted) setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _addPokemon(PokemonBasic basic) async {
    setState(() { _searchResults = []; _addedIds.add(basic.id); });
    try {
      final detail = await PokeApiService.getPokemonDetail(basic.id);
      final baseSpeed = detail.stats['speed'] ?? 0;

      final newEntries = List<_SpeedEntry>.from(_entries);
      newEntries.add(_SpeedEntry(
        pokemon: detail,
        label: '${detail.displayName} (Max Speed)',
        speed: _calcSpeed(baseSpeed, _level, 252, 31, 1.1),
        config: '+Spe 252 EVs',
        isTeam: false,
      ));
      newEntries.add(_SpeedEntry(
        pokemon: detail,
        label: '${detail.displayName} (Neutral)',
        speed: _calcSpeed(baseSpeed, _level, 0, 31, 1.0),
        config: 'No EVs',
        isTeam: false,
      ));
      newEntries.add(_SpeedEntry(
        pokemon: detail,
        label: '${detail.displayName} (Min Speed)',
        speed: _calcSpeed(baseSpeed, _level, 0, 0, 0.9),
        config: '-Spe 0 IVs',
        isTeam: false,
      ));

      newEntries.sort((a, b) => b.speed.compareTo(a.speed));
      if (mounted) setState(() => _entries = newEntries);
    } catch (_) {}
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

  Future<void> _loadCommonPokemon() async {
    setState(() => _loading = true);
    // Common competitive Pokemon IDs
    final commonIds = [6, 9, 25, 38, 59, 65, 94, 130, 131, 143, 149, 150,
        248, 373, 376, 386, 445, 448, 450, 472, 530, 598, 609, 635,
        658, 681, 700, 715, 778, 812, 849, 887, 892, 898, 905, 1000];

    final newEntries = List<_SpeedEntry>.from(_entries);

    for (final id in commonIds) {
      if (_addedIds.contains(id)) continue;
      try {
        final detail = await PokeApiService.getPokemonDetail(id);
        final baseSpeed = detail.stats['speed'] ?? 0;
        _addedIds.add(id);

        newEntries.add(_SpeedEntry(
          pokemon: detail,
          label: '${detail.displayName} (Max)',
          speed: _calcSpeed(baseSpeed, _level, 252, 31, 1.1),
          config: '+Spe 252',
          isTeam: false,
        ));
      } catch (_) {}
    }

    newEntries.sort((a, b) => b.speed.compareTo(a.speed));
    if (mounted) setState(() { _entries = newEntries; _loading = false; _showAll = true; });
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
                Text('Speed Tiers', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Compare speed stats with EV/IV/nature configurations. See who outspeeds whom.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 24),
                // Controls
                _buildControls(theme, isDark),
                const SizedBox(height: 20),
                // Add pokemon
                _buildAddPokemon(theme, isDark),
                const SizedBox(height: 20),
                // Speed list
                _buildSpeedList(theme, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text('Level:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(width: 12),
            ...([1, 50, 100].map((l) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _level = l);
                  _recalculate();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _level == l ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Lv.$l', style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12,
                      color: _level == l ? Colors.white : theme.colorScheme.primary,
                    )),
                  ),
                ),
              ),
            ))),
            const Spacer(),
            if (!_showAll)
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _loadCommonPokemon,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Common'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPokemon(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Add a Pokemon to compare...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
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
                      leading: Image.network(p.spriteUrl, width: 28, height: 28,
                          errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 20)),
                      title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      onTap: () => _addPokemon(p),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedList(ThemeData theme, bool isDark) {
    if (_loading && _entries.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
    }

    if (_entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.speed_rounded, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                const SizedBox(height: 16),
                Text('No Pokemon to compare', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Add Pokemon to your team or search above to compare speed tiers.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
              ],
            ),
          ),
        ),
      );
    }

    // Find max speed for bar scaling
    final maxSpeed = _entries.map((e) => e.speed).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Speed Rankings (Level $_level)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (_loading) ...[
                  const SizedBox(width: 12),
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text('Higher speed moves first in battle (ties broken by random)',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
            const SizedBox(height: 16),
            ...List.generate(_entries.length, (i) {
              final entry = _entries[i];
              final prevSpeed = i > 0 ? _entries[i - 1].speed : null;
              final showDivider = prevSpeed != null && prevSpeed != entry.speed;
              final color = TypeColors.getColor(entry.pokemon.types.first.name);

              return Column(
                children: [
                  if (showDivider && (prevSpeed! - entry.speed) > 5)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${prevSpeed - entry.speed} gap',
                              style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: entry.isTeam
                          ? color.withOpacity(isDark ? 0.08 : 0.04)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: entry.isTeam ? Border.all(color: color.withOpacity(0.15)) : null,
                    ),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12,
                              color: entry.isTeam ? color : theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                        // Sprite
                        GestureDetector(
                          onTap: () => context.go('/pokemon/${entry.pokemon.id}'),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Image.network(
                              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${entry.pokemon.id}.png',
                              width: 32, height: 32,
                              errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Name
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.pokemon.displayName,
                                style: TextStyle(
                                  fontWeight: entry.isTeam ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                  color: entry.isTeam ? color : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(entry.config, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                            ],
                          ),
                        ),
                        // Speed bar
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 10,
                              child: Stack(
                                children: [
                                  Container(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100),
                                  FractionallySizedBox(
                                    widthFactor: (entry.speed / maxSpeed).clamp(0, 1),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Speed value
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${entry.speed}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14,
                              color: entry.isTeam ? color : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _recalculate() {
    final newEntries = <_SpeedEntry>[];
    for (final e in _entries) {
      final baseSpeed = e.pokemon.stats['speed'] ?? 0;
      int speed;
      if (e.config.contains('+Spe')) {
        speed = _calcSpeed(baseSpeed, _level, 252, 31, 1.1);
      } else if (e.config.contains('-Spe')) {
        speed = _calcSpeed(baseSpeed, _level, 0, 0, 0.9);
      } else {
        speed = _calcSpeed(baseSpeed, _level, 0, 31, 1.0);
      }
      newEntries.add(_SpeedEntry(
        pokemon: e.pokemon,
        label: e.label,
        speed: speed,
        config: e.config,
        isTeam: e.isTeam,
      ));
    }
    newEntries.sort((a, b) => b.speed.compareTo(a.speed));
    setState(() => _entries = newEntries);
  }
}

class _SpeedEntry {
  final PokemonDetail pokemon;
  final String label;
  final int speed;
  final String config;
  final bool isTeam;

  _SpeedEntry({
    required this.pokemon,
    required this.label,
    required this.speed,
    required this.config,
    required this.isTeam,
  });
}
