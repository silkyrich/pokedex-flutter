import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/app_state.dart';
import '../services/pokeapi_service.dart';
import '../widgets/app_header.dart';
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
    final appState = AppState();
    final teamIds = appState.team;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: const AppHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('My Team', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${teamIds.length}/6', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
                    if (teamIds.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => appState.clearTeam(),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (teamIds.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: Column(
                        children: [
                          Icon(Icons.groups_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text('No team members yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Tap the team icon on any Pokémon detail page to build your team.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Team members
                  ...teamIds.map((id) {
                    final detail = _details[id];
                    if (detail == null) {
                      return Card(
                        child: ListTile(
                          leading: const CircularProgressIndicator(),
                          title: Text('Pokémon #$id'),
                        ),
                      );
                    }
                    return _TeamMemberCard(
                      pokemon: detail,
                      isWide: isWide,
                      onTap: () => context.go('/pokemon/$id'),
                      onRemove: () => appState.toggleTeamMember(id),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Team summary
                  if (teamIds.length >= 2)
                    _buildTeamSummary(teamIds),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSummary(List<int> teamIds) {
    // Calculate type coverage
    final Set<String> allTypes = {};
    final Map<String, int> weaknesses = {};
    final Map<String, int> resistances = {};

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
        if (mult < 1 && mult > 0) resistances[attackType] = (resistances[attackType] ?? 0) + 1;
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
            Text('Team Analysis', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Types covered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: coverageTypes.map((t) => TypeBadge(type: t)).toList(),
            ),
            if (uncoveredTypes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Types not covered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: uncoveredTypes.map((t) => Opacity(opacity: 0.5, child: TypeBadge(type: t))).toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Team weaknesses (members weak to):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (weaknesses.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                .take(8)
                .map((e) => Chip(
                  label: Text('${e.key[0].toUpperCase()}${e.key.substring(1)} (${e.value})', style: const TextStyle(fontSize: 12)),
                  backgroundColor: TypeColors.getColor(e.key).withOpacity(0.2),
                  visualDensity: VisualDensity.compact,
                ))
                .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final PokemonDetail pokemon;
  final bool isWide;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _TeamMemberCard({
    required this.pokemon,
    required this.isWide,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isWide ? _wideLayout(context) : _narrowLayout(context),
        ),
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    final statOrder = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    return Row(
      children: [
        // Sprite
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: TypeColors.getColor(pokemon.types.first.name).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.network(pokemon.imageUrl, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 40)),
        ),
        const SizedBox(width: 16),
        // Name + types
        SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pokemon.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(pokemon.idString, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, children: pokemon.types.map((t) => TypeBadge(type: t.name, fontSize: 10)).toList()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Mini stats
        Expanded(
          child: Column(
            children: statOrder.map((s) => StatBar(label: s, value: pokemon.stats[s] ?? 0)).toList(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: onRemove,
          tooltip: 'Remove from team',
        ),
      ],
    );
  }

  Widget _narrowLayout(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: TypeColors.getColor(pokemon.types.first.name).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.network(
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pokemon.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Wrap(spacing: 4, children: pokemon.types.map((t) => TypeBadge(type: t.name, fontSize: 10)).toList()),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: onRemove,
          tooltip: 'Remove from team',
        ),
      ],
    );
  }
}
