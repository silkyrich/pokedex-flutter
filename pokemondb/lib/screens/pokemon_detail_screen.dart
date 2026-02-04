import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/type_badge.dart';
import '../widgets/stat_bar.dart';
import '../utils/type_colors.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailScreen({super.key, required this.pokemonId});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  PokemonDetail? _pokemon;
  PokemonSpecies? _species;
  List<EvolutionInfo>? _evolutions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(PokemonDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.pokemonId != widget.pokemonId) _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });

    try {
      final results = await Future.wait([
        PokeApiService.getPokemonDetail(widget.pokemonId),
        PokeApiService.getPokemonSpecies(widget.pokemonId),
      ]);

      final detail = results[0] as PokemonDetail;
      final species = results[1] as PokemonSpecies;

      List<EvolutionInfo>? evolutions;
      if (species.evolutionChainId != null) {
        try {
          evolutions = await PokeApiService.getEvolutionChain(species.evolutionChainId!);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _pokemon = detail;
          _species = species;
          _evolutions = evolutions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Failed to load Pokémon #${widget.pokemonId}'),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = _pokemon!;
    final isWide = MediaQuery.of(context).size.width > 800;
    final colorScheme = Theme.of(context).colorScheme;
    final appState = AppState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nav + actions
              Row(
                children: [
                  if (widget.pokemonId > 1)
                    TextButton.icon(
                      onPressed: () => context.go('/pokemon/${widget.pokemonId - 1}'),
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: Text('#${widget.pokemonId - 1}'),
                    ),
                  const Spacer(),
                  // Favorite button
                  ListenableBuilder(
                    listenable: appState,
                    builder: (context, _) => IconButton(
                      icon: Icon(
                        appState.isFavorite(widget.pokemonId) ? Icons.favorite : Icons.favorite_border,
                        color: appState.isFavorite(widget.pokemonId) ? Colors.red : null,
                      ),
                      tooltip: appState.isFavorite(widget.pokemonId) ? 'Remove from favorites' : 'Add to favorites',
                      onPressed: () => appState.toggleFavorite(widget.pokemonId),
                    ),
                  ),
                  // Team button
                  ListenableBuilder(
                    listenable: appState,
                    builder: (context, _) => IconButton(
                      icon: Icon(
                        appState.isOnTeam(widget.pokemonId) ? Icons.groups : Icons.group_add_outlined,
                        color: appState.isOnTeam(widget.pokemonId) ? colorScheme.primary : null,
                      ),
                      tooltip: appState.isOnTeam(widget.pokemonId) ? 'Remove from team' : 'Add to team',
                      onPressed: () {
                        if (!appState.isOnTeam(widget.pokemonId) && appState.teamFull) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Team is full (max 6)'), duration: Duration(seconds: 2)),
                          );
                          return;
                        }
                        appState.toggleTeamMember(widget.pokemonId);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => context.go('/pokemon/${widget.pokemonId + 1}'),
                    icon: const SizedBox.shrink(),
                    label: Row(children: [
                      Text('#${widget.pokemonId + 1}'),
                      const Icon(Icons.chevron_right, size: 18),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(p.displayName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(p.idString, style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Main layout
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildImageSection(p)),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildInfoSection(p)),
                  ],
                )
              else
                Column(children: [
                  _buildImageSection(p),
                  const SizedBox(height: 16),
                  _buildInfoSection(p),
                ]),
              const SizedBox(height: 24),
              _buildStatsSection(p),
              const SizedBox(height: 24),
              if (_evolutions != null && _evolutions!.length > 1) ...[
                _buildEvolutionSection(),
                const SizedBox(height: 24),
              ],
              _buildTypeDefensesSection(p),
              const SizedBox(height: 24),
              _buildMovesSection(p),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(PokemonDetail p) {
    final primaryType = p.types.first.name;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TypeColors.getColor(primaryType).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Hero(
          tag: 'pokemon-${p.id}',
          child: Image.network(
            p.imageUrl,
            width: 250,
            height: 250,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 120, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(PokemonDetail p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_species?.flavorText != null) ...[
              Text(_species!.flavorText!, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 16),
            ],
            _infoTable([
              if (_species?.genus != null) ['Species', _species!.genus!],
              ['Height', '${p.heightInMeters} m (${(p.heightInMeters * 3.281).toStringAsFixed(1)} ft)'],
              ['Weight', '${p.weightInKg} kg (${(p.weightInKg * 2.205).toStringAsFixed(1)} lbs)'],
              ['Abilities', p.abilities.map((a) => '${a.displayName}${a.isHidden ? ' (hidden)' : ''}').join(', ')],
            ]),
            const SizedBox(height: 12),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: p.types.map((t) => TypeBadge(type: t.name, large: true, fontSize: 14)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTable(List<List<String>> rows) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: rows.map((row) => TableRow(children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 8),
          child: Text(row[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(row[1], style: const TextStyle(fontSize: 14)),
        ),
      ])).toList(),
    );
  }

  Widget _buildStatsSection(PokemonDetail p) {
    final statOrder = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    final total = p.stats.values.fold<int>(0, (a, b) => a + b);

    return _sectionCard('Base Stats', Column(children: [
      ...statOrder.map((s) => StatBar(label: s, value: p.stats[s] ?? 0)),
      const Divider(height: 20),
      Row(children: [
        const SizedBox(width: 80, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        SizedBox(width: 40, child: Text('$total', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
      ]),
    ]));
  }

  Widget _buildEvolutionSection() {
    return _sectionCard('Evolution Chain', Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < _evolutions!.length; i++) ...[
          if (i > 0)
            Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.arrow_forward, color: Colors.grey),
              if (_evolutions![i].displayTrigger.isNotEmpty)
                Text(_evolutions![i].displayTrigger, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          _EvolutionTile(
            evo: _evolutions![i],
            isCurrentPokemon: _evolutions![i].id == widget.pokemonId,
            onTap: () => context.go('/pokemon/${_evolutions![i].id}'),
          ),
        ],
      ],
    ));
  }

  Widget _buildTypeDefensesSection(PokemonDetail p) {
    final typeNames = p.types.map((t) => t.name).toList();
    final Map<String, double> defenses = {};
    for (final attackType in TypeChart.types) {
      double mult = 1;
      for (final defType in typeNames) {
        mult *= TypeChart.getEffectiveness(attackType, defType);
      }
      defenses[attackType] = mult;
    }

    final weak = defenses.entries.where((e) => e.value > 1).toList()..sort((a, b) => b.value.compareTo(a.value));
    final resist = defenses.entries.where((e) => e.value > 0 && e.value < 1).toList()..sort((a, b) => a.value.compareTo(b.value));
    final immune = defenses.entries.where((e) => e.value == 0).toList();

    return _sectionCard('Type Defenses', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('The effectiveness of each type on ${_pokemon!.displayName}.', style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        if (weak.isNotEmpty) _defenseGroup('Weak to:', weak),
        if (resist.isNotEmpty) _defenseGroup('Resistant to:', resist),
        if (immune.isNotEmpty) _defenseGroup('Immune to:', immune),
      ],
    ));
  }

  Widget _defenseGroup(String label, List<MapEntry<String, double>> entries) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: entries.map((e) => _DefenseBadge(type: e.key, multiplier: e.value)).toList()),
      ]),
    );
  }

  Widget _buildMovesSection(PokemonDetail p) {
    final levelMoves = p.moves.where((m) => m.learnMethod == 'level-up').toList()
      ..sort((a, b) => a.levelLearnedAt.compareTo(b.levelLearnedAt));
    final tmMoves = p.moves.where((m) => m.learnMethod == 'machine').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final eggMoves = p.moves.where((m) => m.learnMethod == 'egg').toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return _sectionCard('Moves', DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: 'Level Up (${levelMoves.length})'),
            Tab(text: 'TM/HM (${tmMoves.length})'),
            Tab(text: 'Egg (${eggMoves.length})'),
          ],
        ),
        SizedBox(
          height: (levelMoves.length.clamp(1, 20) * 40.0) + 50,
          child: TabBarView(children: [
            _moveList(levelMoves, showLevel: true),
            _moveList(tmMoves),
            _moveList(eggMoves),
          ]),
        ),
      ]),
    ));
  }

  Widget _moveList(List<PokemonMove> moves, {bool showLevel = false}) {
    if (moves.isEmpty) return const Center(child: Text('No moves', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      shrinkWrap: true,
      itemCount: moves.length.clamp(0, 20),
      itemBuilder: (context, index) {
        final m = moves[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [
            if (showLevel)
              SizedBox(width: 44, child: Text(
                m.levelLearnedAt > 0 ? 'Lv${m.levelLearnedAt}' : '—',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )),
            Expanded(child: Text(m.displayName, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary, fontSize: 14))),
          ]),
        );
      },
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}

class _EvolutionTile extends StatelessWidget {
  final EvolutionInfo evo;
  final bool isCurrentPokemon;
  final VoidCallback onTap;

  const _EvolutionTile({required this.evo, required this.isCurrentPokemon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentPokemon ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isCurrentPokemon ? Border.all(color: colorScheme.primary) : null,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.network(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${evo.id}.png',
              width: 68, height: 68,
              errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 40),
            ),
            Text(
              evo.name[0].toUpperCase() + evo.name.substring(1),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DefenseBadge extends StatelessWidget {
  final String type;
  final double multiplier;

  const _DefenseBadge({required this.type, required this.multiplier});

  String get _label {
    if (multiplier == 0) return '0×';
    if (multiplier == 0.25) return '¼×';
    if (multiplier == 0.5) return '½×';
    if (multiplier == 2) return '2×';
    if (multiplier == 4) return '4×';
    return '${multiplier}×';
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: TypeColors.getColor(type),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
        ),
        child: Text(type[0].toUpperCase() + type.substring(1),
          style: TextStyle(color: TypeColors.getTextColor(type), fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: multiplier > 1 ? Colors.red.shade50 : multiplier == 0 ? Colors.grey.shade200 : Colors.green.shade50,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
        ),
        child: Text(_label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    ]);
  }
}
