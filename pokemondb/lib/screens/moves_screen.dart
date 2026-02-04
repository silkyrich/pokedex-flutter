import 'package:flutter/material.dart';
import '../models/move.dart';
import '../services/pokeapi_service.dart';
import '../widgets/app_header.dart';
import '../widgets/type_badge.dart';

class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  final List<_MoveListItem> _moves = [];
  bool _loading = true;
  String _sortBy = 'name';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadMoves();
  }

  Future<void> _loadMoves() async {
    try {
      // Load the first 100 moves for a reasonable initial set
      final futures = <Future<MoveDetail>>[];
      for (int i = 1; i <= 165; i++) {
        futures.add(PokeApiService.getMoveDetail(i.toString()));
      }

      final results = await Future.wait(futures.map((f) => f.catchError((_) => MoveDetail(id: 0, name: ''))));
      final valid = results.where((m) => m.id > 0).toList();

      if (mounted) {
        setState(() {
          _moves.addAll(valid.map((m) => _MoveListItem(
                id: m.id,
                name: m.displayName,
                rawName: m.name,
                type: m.type ?? '',
                power: m.power,
                accuracy: m.accuracy,
                pp: m.pp,
                damageClass: m.damageClass ?? '',
              )));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_MoveListItem> get _filteredMoves {
    var list = _moves.toList();
    if (_filterType != 'all') {
      list = list.where((m) => m.type == _filterType).toList();
    }
    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => a.rawName.compareTo(b.rawName));
        break;
      case 'power':
        list.sort((a, b) => (b.power ?? 0).compareTo(a.power ?? 0));
        break;
      case 'accuracy':
        list.sort((a, b) => (b.accuracy ?? 0).compareTo(a.accuracy ?? 0));
        break;
      case 'pp':
        list.sort((a, b) => (b.pp ?? 0).compareTo(a.pp ?? 0));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMoves;

    return Scaffold(
      appBar: const AppHeader(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF3B5BA7)),
                  SizedBox(height: 16),
                  Text('Loading moves...', style: TextStyle(color: Color(0xFF666666))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pokémon Moves',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A list of all Pokémon moves with their power, accuracy, and PP.',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Filters
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildDropdown(
                            'Sort by:',
                            _sortBy,
                            {'name': 'Name', 'power': 'Power', 'accuracy': 'Accuracy', 'pp': 'PP'},
                            (v) => setState(() => _sortBy = v!),
                          ),
                          _buildDropdown(
                            'Type:',
                            _filterType,
                            {
                              'all': 'All',
                              'normal': 'Normal', 'fire': 'Fire', 'water': 'Water',
                              'electric': 'Electric', 'grass': 'Grass', 'ice': 'Ice',
                              'fighting': 'Fighting', 'poison': 'Poison', 'ground': 'Ground',
                              'flying': 'Flying', 'psychic': 'Psychic', 'bug': 'Bug',
                              'rock': 'Rock', 'ghost': 'Ghost', 'dragon': 'Dragon',
                              'dark': 'Dark', 'steel': 'Steel', 'fairy': 'Fairy',
                            },
                            (v) => setState(() => _filterType = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Moves table
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF3B5BA7)),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Cat.')),
                              DataColumn(label: Text('Power'), numeric: true),
                              DataColumn(label: Text('Acc.'), numeric: true),
                              DataColumn(label: Text('PP'), numeric: true),
                            ],
                            rows: filtered.map((m) {
                              return DataRow(cells: [
                                DataCell(Text(
                                  m.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3B5BA7),
                                  ),
                                )),
                                DataCell(m.type.isNotEmpty ? TypeBadge(type: m.type) : const Text('—')),
                                DataCell(_CategoryIcon(category: m.damageClass)),
                                DataCell(Text(m.power?.toString() ?? '—')),
                                DataCell(Text(m.accuracy != null ? '${m.accuracy}%' : '—')),
                                DataCell(Text(m.pp?.toString() ?? '—')),
                              ]);
                            }).toList(),
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

  Widget _buildDropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFCCCCCC)),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: items.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _MoveListItem {
  final int id;
  final String name;
  final String rawName;
  final String type;
  final int? power;
  final int? accuracy;
  final int? pp;
  final String damageClass;

  _MoveListItem({
    required this.id,
    required this.name,
    required this.rawName,
    required this.type,
    this.power,
    this.accuracy,
    this.pp,
    required this.damageClass,
  });
}

class _CategoryIcon extends StatelessWidget {
  final String category;

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (category) {
      case 'physical':
        icon = Icons.sports_mma;
        color = const Color(0xFFC92112);
        break;
      case 'special':
        icon = Icons.auto_awesome;
        color = const Color(0xFF4F5870);
        break;
      case 'status':
        icon = Icons.shield;
        color = const Color(0xFF8C888C);
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    return Tooltip(
      message: category.isNotEmpty ? category[0].toUpperCase() + category.substring(1) : '',
      child: Icon(icon, size: 18, color: color),
    );
  }
}
