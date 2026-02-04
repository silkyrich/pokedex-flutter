import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
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

  Future<void> _loadData() async {
    try {
      final detail = await PokeApiService.getPokemonDetail(widget.pokemonId);
      final species = await PokeApiService.getPokemonSpecies(widget.pokemonId);

      List<EvolutionInfo>? evolutions;
      if (species.evolutionChainId != null) {
        evolutions = await PokeApiService.getEvolutionChain(species.evolutionChainId!);
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
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B5BA7)))
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = _pokemon!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation
              Row(
                children: [
                  if (widget.pokemonId > 1)
                    TextButton.icon(
                      onPressed: () => context.go('/pokemon/${widget.pokemonId - 1}'),
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: Text('${widget.pokemonId - 1}'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B5BA7)),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go('/pokemon/${widget.pokemonId + 1}'),
                    icon: const SizedBox.shrink(),
                    label: Row(
                      children: [
                        Text('${widget.pokemonId + 1}'),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B5BA7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                p.displayName,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                p.idString,
                style: const TextStyle(fontSize: 16, color: Color(0xFF999999), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Main content
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
                Column(
                  children: [
                    _buildImageSection(p),
                    const SizedBox(height: 16),
                    _buildInfoSection(p),
                  ],
                ),
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
        child: Image.network(
          p.imageUrl,
          width: 250,
          height: 250,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.catching_pokemon,
            size: 120,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(PokemonDetail p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_species?.flavorText != null) ...[
            Text(
              _species!.flavorText!,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF444444)),
            ),
            const SizedBox(height: 16),
          ],
          _infoTable([
            if (_species?.genus != null) ['Species', _species!.genus!],
            ['Height', '${p.heightInMeters} m (${(p.heightInMeters * 3.281).toStringAsFixed(1)} ft)'],
            ['Weight', '${p.weightInKg} kg (${(p.weightInKg * 2.205).toStringAsFixed(1)} lbs)'],
            [
              'Abilities',
              p.abilities.map((a) => '${a.displayName}${a.isHidden ? ' (hidden)' : ''}').join(', '),
            ],
          ]),
          const SizedBox(height: 12),
          const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF555555))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: p.types.map((t) => TypeBadge(type: t.name, large: true, fontSize: 14)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoTable(List<List<String>> rows) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: rows.map((row) {
        return TableRow(children: [
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Text(
              row[0],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF555555)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(row[1], style: const TextStyle(fontSize: 14)),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildStatsSection(PokemonDetail p) {
    final statOrder = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    final total = p.stats.values.fold<int>(0, (a, b) => a + b);

    return _sectionCard(
      'Base Stats',
      Column(
        children: [
          ...statOrder.map((s) => StatBar(label: s, value: p.stats[s] ?? 0)),
          const Divider(height: 20),
          Row(
            children: [
              const SizedBox(
                width: 80,
                child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$total',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionSection() {
    return _sectionCard(
      'Evolution Chain',
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < _evolutions!.length; i++) ...[
            if (i > 0)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward, color: Color(0xFF999999)),
                  if (_evolutions![i].minLevel != null)
                    Text(
                      'Lv. ${_evolutions![i].minLevel}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                    ),
                ],
              ),
            _EvolutionTile(
              evo: _evolutions![i],
              isCurrentPokemon: _evolutions![i].id == widget.pokemonId,
              onTap: () => context.go('/pokemon/${_evolutions![i].id}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeDefensesSection(PokemonDetail p) {
    final typeNames = p.types.map((t) => t.name).toList();

    // Calculate combined effectiveness
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

    return _sectionCard(
      'Type Defenses',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The effectiveness of each type on ${_pokemon!.displayName}.',
            style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (weak.isNotEmpty) ...[
            const Text('Weak to:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: weak.map((e) {
                return _DefenseBadge(type: e.key, multiplier: e.value);
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (resist.isNotEmpty) ...[
            const Text('Resistant to:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: resist.map((e) {
                return _DefenseBadge(type: e.key, multiplier: e.value);
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (immune.isNotEmpty) ...[
            const Text('Immune to:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: immune.map((e) {
                return _DefenseBadge(type: e.key, multiplier: e.value);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMovesSection(PokemonDetail p) {
    final levelMoves = p.moves.where((m) => m.learnMethod == 'level-up').toList()
      ..sort((a, b) => a.levelLearnedAt.compareTo(b.levelLearnedAt));
    final tmMoves = p.moves.where((m) => m.learnMethod == 'machine').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final eggMoves = p.moves.where((m) => m.learnMethod == 'egg').toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return _sectionCard(
      'Moves',
      DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFF3B5BA7),
              unselectedLabelColor: Color(0xFF999999),
              indicatorColor: Color(0xFF3B5BA7),
              tabs: [
                Tab(text: 'Level Up'),
                Tab(text: 'TM/HM'),
                Tab(text: 'Egg'),
              ],
            ),
            SizedBox(
              height: (levelMoves.length.clamp(1, 15) * 40.0) + 50,
              child: TabBarView(
                children: [
                  _moveList(levelMoves, showLevel: true),
                  _moveList(tmMoves),
                  _moveList(eggMoves),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moveList(List<PokemonMove> moves, {bool showLevel = false}) {
    if (moves.isEmpty) {
      return const Center(child: Text('No moves', style: TextStyle(color: Color(0xFF999999))));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: moves.length.clamp(0, 15),
      itemBuilder: (context, index) {
        final m = moves[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              if (showLevel)
                SizedBox(
                  width: 40,
                  child: Text(
                    m.levelLearnedAt > 0 ? 'Lv${m.levelLearnedAt}' : '—',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
              Expanded(
                child: Text(
                  m.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B5BA7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EvolutionTile extends StatelessWidget {
  final EvolutionInfo evo;
  final bool isCurrentPokemon;
  final VoidCallback onTap;

  const _EvolutionTile({
    required this.evo,
    required this.isCurrentPokemon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentPokemon ? const Color(0xFFE8EDF5) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isCurrentPokemon ? Border.all(color: const Color(0xFF3B5BA7)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${evo.id}.png',
                width: 68,
                height: 68,
                errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 40),
              ),
              Text(
                evo.name[0].toUpperCase() + evo.name.substring(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF3B5BA7),
                ),
              ),
            ],
          ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: TypeColors.getColor(type),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
          ),
          child: Text(
            type[0].toUpperCase() + type.substring(1),
            style: TextStyle(
              color: TypeColors.getTextColor(type),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: multiplier > 1
                ? const Color(0xFFFFDDDD)
                : multiplier == 0
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFFDDFFDD),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
          ),
          child: Text(
            _label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
