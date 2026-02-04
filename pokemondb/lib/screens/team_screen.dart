import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/app_state.dart';
import '../services/pokeapi_service.dart';
import '../widgets/type_badge.dart';
import '../widgets/stat_bar.dart';
import '../utils/type_colors.dart';

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

  Widget _buildTeamSummary(List<int> teamIds, ThemeData theme, bool isDark) {
    final Set<String> allTypes = {};
    final Map<String, int> weaknesses = {};

    for (final id in teamIds) {
      final d = _details[id];
      if (d == null) continue;

      final typeNames = d.types.map((t) => t.name).toList();
      allTypes.addAll(typeNames);

      for (final attackType in TypeChart.types) {
        double mult = 1;
        for (final defType in typeNames) {
          mult *= TypeChart.getEffectiveness(attackType, defType);
        }
        if (mult > 1) weaknesses[attackType] = (weaknesses[attackType] ?? 0) + 1;
      }
    }

    final coverageTypes = allTypes.toList()..sort();
    final uncoveredTypes = TypeChart.types.where((t) => !coverageTypes.contains(t)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Analysis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            Text('Types covered', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: coverageTypes.map((t) => TypeBadge(type: t, navigable: true)).toList(),
            ),
            if (uncoveredTypes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Types not covered', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: uncoveredTypes.map((t) => Opacity(opacity: 0.4, child: TypeBadge(type: t, navigable: true))).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text('Team weaknesses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (weaknesses.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                .take(8)
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? TypeColors.getColor(e.key) : TypeColors.getColor(e.key),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ))
                .toList(),
            ),
          ],
        ),
      ),
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
          child: Image.network(widget.pokemon.imageUrl, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 36)),
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
          child: Image.network(
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${widget.pokemon.id}.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 28),
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
