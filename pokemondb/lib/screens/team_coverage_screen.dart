import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_state.dart';
import '../services/pokeapi_service.dart';
import '../models/pokemon.dart';
import '../utils/type_colors.dart';
import '../widgets/type_badge.dart';

class TeamCoverageScreen extends StatefulWidget {
  const TeamCoverageScreen({super.key});

  @override
  State<TeamCoverageScreen> createState() => _TeamCoverageScreenState();
}

class _TeamCoverageScreenState extends State<TeamCoverageScreen> {
  List<PokemonDetail> _teamPokemon = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    setState(() => _loading = true);
    final teamIds = AppState().team;

    if (teamIds.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final details = await Future.wait(
        teamIds.map((id) => PokeApiService.getPokemonDetail(id)),
      );
      if (mounted) {
        setState(() {
          _teamPokemon = details.cast<PokemonDetail>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, CoverageInfo> _calculateCoverage() {
    final coverage = <String, CoverageInfo>{};

    // Initialize all types
    for (final type in TypeChart.types) {
      coverage[type] = CoverageInfo(type: type);
    }

    // Calculate offensive coverage (what types can we hit super-effectively?)
    for (final pokemon in _teamPokemon) {
      for (final pokemonType in pokemon.types) {
        final effectiveness = TypeChart.getOffensiveMatchups(pokemonType.name);
        for (final entry in effectiveness.entries) {
          if (entry.value > 1.0) { // Super effective
            coverage[entry.key]!.offensiveHits.add(_PokemonTypeRef(
              pokemonId: pokemon.id,
              pokemonName: pokemon.displayName,
              attackingType: pokemonType.name,
              effectiveness: entry.value,
            ));
          }
        }
      }
    }

    // Calculate defensive weaknesses (what types is our team weak to?)
    for (final pokemon in _teamPokemon) {
      final typeNames = pokemon.types.map((t) => t.name).toList();
      final defenses = TypeChart.getDefensiveMatchups(typeNames);

      for (final entry in defenses.entries) {
        if (entry.value > 1.0) { // Weak to this type
          coverage[entry.key]!.teamWeaknesses.add(_PokemonTypeRef(
            pokemonId: pokemon.id,
            pokemonName: pokemon.displayName,
            attackingType: entry.key,
            effectiveness: entry.value,
          ));
        }
      }
    }

    return coverage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState();

    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_teamPokemon.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.1),
              ),
              const SizedBox(height: 20),
              Text(
                'No Team Members',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add Pokemon to your team to see coverage analysis.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.catching_pokemon, size: 18),
                label: const Text('Browse Pokédex'),
              ),
            ],
          ),
        ),
      );
    }

    final coverage = _calculateCoverage();
    final offensiveGaps = coverage.entries
        .where((e) => e.value.offensiveHits.isEmpty)
        .map((e) => e.key)
        .toList();

    final teamWeaknesses = coverage.entries
        .where((e) => e.value.teamWeaknesses.isNotEmpty)
        .toList()
      ..sort((a, b) => b.value.teamWeaknesses.length.compareTo(a.value.teamWeaknesses.length));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Team Coverage Analysis',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analyze your team\'s offensive coverage and defensive weaknesses.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),

                // Team members
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Team (${_teamPokemon.length}/6)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _teamPokemon.map((p) {
                            return _TeamMemberChip(
                              pokemon: p,
                              onRemove: () {
                                appState.toggleTeamMember(p.id);
                                _loadTeam();
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Offensive coverage gaps
                if (offensiveGaps.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Coverage Gaps',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your team has no super-effective coverage against these types:',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: offensiveGaps.map((type) {
                              return TypeBadge(type: type, navigable: true);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Team weaknesses
                if (teamWeaknesses.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.red, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Team Weaknesses',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These types threaten multiple team members:',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...teamWeaknesses.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TypeBadge(type: entry.key, navigable: true),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Threatens ${entry.value.teamWeaknesses.length} team member${entry.value.teamWeaknesses.length > 1 ? 's' : ''}: ${entry.value.teamWeaknesses.map((r) => r.pokemonName).join(', ')}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoverageInfo {
  final String type;
  final List<_PokemonTypeRef> offensiveHits = [];
  final List<_PokemonTypeRef> teamWeaknesses = [];

  CoverageInfo({required this.type});
}

class _PokemonTypeRef {
  final int pokemonId;
  final String pokemonName;
  final String attackingType;
  final double effectiveness;

  _PokemonTypeRef({
    required this.pokemonId,
    required this.pokemonName,
    required this.attackingType,
    required this.effectiveness,
  });
}

class _TeamMemberChip extends StatelessWidget {
  final PokemonDetail pokemon;
  final VoidCallback onRemove;

  const _TeamMemberChip({required this.pokemon, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryType = pokemon.types.isNotEmpty ? pokemon.types.first.name : 'normal';
    final color = TypeColors.getColor(primaryType);

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            pokemon.spriteUrl,
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pokemon.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: pokemon.types.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TypeBadge(type: t.name, fontSize: 10),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRemove,
            tooltip: 'Remove from team',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// Type chart data
class TypeChart {
  static const List<String> types = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice',
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
  ];

  static Map<String, double> getOffensiveMatchups(String attackingType) {
    // Returns what types this attacking type is super effective against
    final matchups = <String, double>{};
    for (final defendingType in types) {
      matchups[defendingType] = _getEffectiveness(attackingType, [defendingType]);
    }
    return matchups;
  }

  static Map<String, double> getDefensiveMatchups(List<String> defendingTypes) {
    // Returns what types this Pokemon is weak to
    final matchups = <String, double>{};
    for (final attackingType in types) {
      matchups[attackingType] = _getEffectiveness(attackingType, defendingTypes);
    }
    return matchups;
  }

  static double _getEffectiveness(String attackingType, List<String> defendingTypes) {
    double effectiveness = 1.0;
    for (final defendingType in defendingTypes) {
      effectiveness *= _getSingleMatchup(attackingType, defendingType);
    }
    return effectiveness;
  }

  static double _getSingleMatchup(String attacking, String defending) {
    // Simplified type chart - you can expand this with full Pokemon type effectiveness
    const superEffective = <String, List<String>>{
      'fire': ['grass', 'ice', 'bug', 'steel'],
      'water': ['fire', 'ground', 'rock'],
      'electric': ['water', 'flying'],
      'grass': ['water', 'ground', 'rock'],
      'ice': ['grass', 'ground', 'flying', 'dragon'],
      'fighting': ['normal', 'ice', 'rock', 'dark', 'steel'],
      'poison': ['grass', 'fairy'],
      'ground': ['fire', 'electric', 'poison', 'rock', 'steel'],
      'flying': ['grass', 'fighting', 'bug'],
      'psychic': ['fighting', 'poison'],
      'bug': ['grass', 'psychic', 'dark'],
      'rock': ['fire', 'ice', 'flying', 'bug'],
      'ghost': ['psychic', 'ghost'],
      'dragon': ['dragon'],
      'dark': ['psychic', 'ghost'],
      'steel': ['ice', 'rock', 'fairy'],
      'fairy': ['fighting', 'dragon', 'dark'],
    };

    const notVeryEffective = <String, List<String>>{
      'fire': ['fire', 'water', 'rock', 'dragon'],
      'water': ['water', 'grass', 'dragon'],
      'electric': ['electric', 'grass', 'dragon'],
      'grass': ['fire', 'grass', 'poison', 'flying', 'bug', 'dragon', 'steel'],
      'ice': ['fire', 'water', 'ice', 'steel'],
      'fighting': ['poison', 'flying', 'psychic', 'bug', 'fairy'],
      'poison': ['poison', 'ground', 'rock', 'ghost'],
      'ground': ['grass', 'bug'],
      'flying': ['electric', 'rock', 'steel'],
      'psychic': ['psychic', 'steel'],
      'bug': ['fire', 'fighting', 'poison', 'flying', 'ghost', 'steel', 'fairy'],
      'rock': ['fighting', 'ground', 'steel'],
      'ghost': ['dark'],
      'dragon': ['steel'],
      'dark': ['fighting', 'dark', 'fairy'],
      'steel': ['fire', 'water', 'electric', 'steel'],
      'fairy': ['fire', 'poison', 'steel'],
    };

    const noEffect = <String, List<String>>{
      'normal': ['ghost'],
      'electric': ['ground'],
      'fighting': ['ghost'],
      'poison': ['steel'],
      'ground': ['flying'],
      'psychic': ['dark'],
      'ghost': ['normal'],
      'dragon': ['fairy'],
    };

    if (noEffect[attacking]?.contains(defending) ?? false) return 0.0;
    if (superEffective[attacking]?.contains(defending) ?? false) return 2.0;
    if (notVeryEffective[attacking]?.contains(defending) ?? false) return 0.5;
    return 1.0;
  }
}
