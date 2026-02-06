import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';
import '../widgets/pokemon_image.dart';

/// Nuzlocke tracker with route encounters, death log, and rules.
class NuzlockeScreen extends StatefulWidget {
  const NuzlockeScreen({super.key});

  @override
  State<NuzlockeScreen> createState() => _NuzlockeScreenState();
}

class _NuzlockeScreenState extends State<NuzlockeScreen> {
  final List<_NuzlockeEncounter> _encounters = [];
  final List<_NuzlockeEncounter> _graveyard = [];
  String _runName = 'My Nuzlocke';
  bool _isEditing = false;
  int _badges = 0;

  // Rules toggles
  bool _ruleFirstEncounter = true;
  bool _ruleFaintDeath = true;
  bool _ruleNickname = true;
  bool _ruleDuplicateClause = true;
  bool _ruleShinyClause = false;
  bool _ruleSetMode = true;
  bool _ruleNoItems = false;
  bool _ruleLevelCap = false;

  // Add encounter dialog
  String _routeName = '';
  String _pokemonSearch = '';
  List<PokemonBasic> _searchResults = [];
  PokemonBasic? _selectedPokemon;
  PokemonDetail? _selectedDetail;
  String _nickname = '';
  bool _loadingPokemon = false;

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

  Future<void> _selectPokemon(PokemonBasic pokemon) async {
    setState(() { _selectedPokemon = pokemon; _searchResults = []; _loadingPokemon = true; });
    try {
      final detail = await PokeApiService.getPokemonDetail(pokemon.id);
      if (mounted) setState(() { _selectedDetail = detail; _loadingPokemon = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPokemon = false);
    }
  }

  void _addEncounter() {
    if (_selectedPokemon == null || _routeName.isEmpty) return;
    setState(() {
      _encounters.add(_NuzlockeEncounter(
        route: _routeName,
        pokemon: _selectedPokemon!,
        detail: _selectedDetail,
        nickname: _nickname.isNotEmpty ? _nickname : _selectedPokemon!.displayName,
        isAlive: true,
        caughtAt: DateTime.now(),
      ));
      _routeName = '';
      _nickname = '';
      _selectedPokemon = null;
      _selectedDetail = null;
      _pokemonSearch = '';
    });
    Navigator.of(context).pop();
  }

  void _markDead(_NuzlockeEncounter encounter) {
    setState(() {
      encounter.isAlive = false;
      encounter.deathRoute = 'Unknown';
      _graveyard.add(encounter);
    });
  }

  void _showAddDialog() {
    _routeName = '';
    _nickname = '';
    _selectedPokemon = null;
    _selectedDetail = null;
    _pokemonSearch = '';
    _searchResults = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Encounter', style: TextStyle(fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Route / Area Name', isDense: true, prefixIcon: Icon(Icons.map_outlined, size: 20)),
                      onChanged: (v) { _routeName = v; setDialogState(() {}); },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Search Pokemon', isDense: true, prefixIcon: Icon(Icons.search_rounded, size: 20)),
                      onChanged: (v) {
                        _pokemonSearch = v;
                        _search(v).then((_) => setDialogState(() {}));
                      },
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (_, i) {
                            final p = _searchResults[i];
                            return ListTile(
                              dense: true,
                              leading: PokemonImage(imageUrl: p.spriteUrl, width: 28, height: 28, fallbackIconSize: 20),
                              title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              onTap: () {
                                _selectPokemon(p).then((_) => setDialogState(() {}));
                              },
                            );
                          },
                        ),
                      ),
                    if (_selectedPokemon != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          PokemonImage(imageUrl: _selectedPokemon!.spriteUrl, width: 48, height: 48, fallbackIconSize: 32),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedPokemon!.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (_selectedDetail != null)
                                Wrap(
                                  spacing: 4,
                                  children: _selectedDetail!.types.map((t) => TypeBadge(type: t.name, fontSize: 9)).toList(),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nickname (optional)', isDense: true, prefixIcon: Icon(Icons.edit_outlined, size: 20)),
                      onChanged: (v) { _nickname = v; setDialogState(() {}); },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: _selectedPokemon != null && _routeName.isNotEmpty ? _addEncounter : null,
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final alive = _encounters.where((e) => e.isAlive).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nuzlocke Tracker', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text('Track encounters, deaths, and rules for your Nuzlocke run.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Encounter'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Summary bar
                _buildSummaryBar(theme, isDark, alive.length),
                const SizedBox(height: 20),
                // Rules
                _buildRulesCard(theme, isDark),
                const SizedBox(height: 20),
                // Badges
                _buildBadgesCard(theme, isDark),
                const SizedBox(height: 20),
                // Active party
                if (alive.isNotEmpty) ...[
                  _buildPartySection('Party (${alive.length})', alive, theme, isDark, isAlive: true),
                  const SizedBox(height: 20),
                ],
                // Graveyard
                if (_graveyard.isNotEmpty) ...[
                  _buildPartySection('Graveyard (${_graveyard.length})', _graveyard, theme, isDark, isAlive: false),
                  const SizedBox(height: 20),
                ],
                if (_encounters.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), shape: BoxShape.circle),
                            child: Icon(Icons.catching_pokemon_outlined, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                          ),
                          const SizedBox(height: 24),
                          Text('No encounters yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Add your first route encounter to start tracking.',
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                        ],
                      ),
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

  Widget _buildSummaryBar(ThemeData theme, bool isDark, int aliveCount) {
    return Row(
      children: [
        _SummaryTile(icon: Icons.catching_pokemon, label: 'Caught', value: '${_encounters.length}', color: theme.colorScheme.primary, isDark: isDark),
        const SizedBox(width: 12),
        _SummaryTile(icon: Icons.favorite, label: 'Alive', value: '$aliveCount', color: const Color(0xFF22C55E), isDark: isDark),
        const SizedBox(width: 12),
        _SummaryTile(icon: Icons.dangerous_outlined, label: 'Dead', value: '${_graveyard.length}', color: const Color(0xFFEF4444), isDark: isDark),
        const SizedBox(width: 12),
        _SummaryTile(icon: Icons.military_tech_rounded, label: 'Badges', value: '$_badges', color: Colors.amber, isDark: isDark),
      ],
    );
  }

  Widget _buildRulesCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Rules', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                _RuleChip(label: 'First encounter only', enabled: _ruleFirstEncounter, onToggle: (v) => setState(() => _ruleFirstEncounter = v)),
                _RuleChip(label: 'Faint = death', enabled: _ruleFaintDeath, onToggle: (v) => setState(() => _ruleFaintDeath = v)),
                _RuleChip(label: 'Must nickname', enabled: _ruleNickname, onToggle: (v) => setState(() => _ruleNickname = v)),
                _RuleChip(label: 'Duplicate clause', enabled: _ruleDuplicateClause, onToggle: (v) => setState(() => _ruleDuplicateClause = v)),
                _RuleChip(label: 'Shiny clause', enabled: _ruleShinyClause, onToggle: (v) => setState(() => _ruleShinyClause = v)),
                _RuleChip(label: 'Set mode', enabled: _ruleSetMode, onToggle: (v) => setState(() => _ruleSetMode = v)),
                _RuleChip(label: 'No items in battle', enabled: _ruleNoItems, onToggle: (v) => setState(() => _ruleNoItems = v)),
                _RuleChip(label: 'Level cap', enabled: _ruleLevelCap, onToggle: (v) => setState(() => _ruleLevelCap = v)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.military_tech_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Text('Badges', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(8, (i) {
                final earned = i < _badges;
                return GestureDetector(
                  onTap: () => setState(() => _badges = earned ? i : i + 1),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 36, height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: earned ? Colors.amber : isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                        border: Border.all(
                          color: earned ? Colors.amber.shade700 : isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: earned ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8)] : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13,
                            color: earned ? Colors.amber.shade900 : theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartySection(String title, List<_NuzlockeEncounter> encounters, ThemeData theme, bool isDark, {required bool isAlive}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAlive ? Icons.favorite : Icons.dangerous_outlined,
                  color: isAlive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...encounters.map((e) => _EncounterTile(
              encounter: e,
              theme: theme,
              isDark: isDark,
              isAlive: isAlive,
              onDeath: isAlive ? () => _markDead(e) : null,
              onTap: () => context.go('/pokemon/${e.pokemon.id}'),
            )),
          ],
        ),
      ),
    );
  }
}

class _NuzlockeEncounter {
  final String route;
  final PokemonBasic pokemon;
  final PokemonDetail? detail;
  final String nickname;
  bool isAlive;
  String? deathRoute;
  final DateTime caughtAt;

  _NuzlockeEncounter({
    required this.route,
    required this.pokemon,
    this.detail,
    required this.nickname,
    required this.isAlive,
    this.deathRoute,
    required this.caughtAt,
  });
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _SummaryTile({required this.icon, required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
            Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  const _RuleChip({required this.label, required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onToggle(!enabled),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enabled ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: enabled ? theme.colorScheme.primary : theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12,
                color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncounterTile extends StatelessWidget {
  final _NuzlockeEncounter encounter;
  final ThemeData theme;
  final bool isDark;
  final bool isAlive;
  final VoidCallback? onDeath;
  final VoidCallback onTap;

  const _EncounterTile({
    required this.encounter, required this.theme, required this.isDark,
    required this.isAlive, this.onDeath, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = encounter.detail != null
        ? TypeColors.getColor(encounter.detail!.types.first.name)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isAlive
            ? typeColor.withOpacity(isDark ? 0.06 : 0.03)
            : (isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAlive ? typeColor.withOpacity(0.15) : theme.dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Left color bar
                Container(
                  width: 4, height: 48,
                  decoration: BoxDecoration(
                    color: isAlive ? typeColor : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                // Sprite
                Opacity(
                  opacity: isAlive ? 1.0 : 0.4,
                  child: Image.network(
                    encounter.pokemon.spriteUrl, width: 40, height: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 28),
                    color: isAlive ? null : Colors.grey,
                    colorBlendMode: isAlive ? null : BlendMode.saturation,
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
                            encounter.nickname,
                            style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14,
                              color: isAlive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                              decoration: isAlive ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          if (encounter.nickname != encounter.pokemon.displayName) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${encounter.pokemon.displayName})',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.map_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(encounter.route, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          if (encounter.detail != null) ...[
                            const SizedBox(width: 8),
                            ...encounter.detail!.types.map((t) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: TypeBadge(type: t.name, fontSize: 9),
                            )),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAlive && onDeath != null)
                  IconButton(
                    icon: Icon(Icons.dangerous_outlined, size: 20, color: Colors.red.withOpacity(0.6)),
                    tooltip: 'Mark as dead',
                    onPressed: () => _confirmDeath(context),
                  ),
                if (!isAlive)
                  Icon(Icons.close_rounded, size: 20, color: Colors.red.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeath(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('RIP ${encounter.nickname}', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text('${encounter.nickname} has fallen in battle. Mark as dead?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onDeath?.call();
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Death'),
          ),
        ],
      ),
    );
  }
}
