import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/move.dart';
import '../services/pokeapi_service.dart';
import '../widgets/type_badge.dart';
import '../utils/type_colors.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredMoves;

    return Scaffold(
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('Loading moves...', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pokemon Moves',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A list of all Pokemon moves with their power, accuracy, and PP.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Filters
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildDropdown('Sort by', _sortBy, {
                            'name': 'Name', 'power': 'Power', 'accuracy': 'Accuracy', 'pp': 'PP',
                          }, (v) => setState(() => _sortBy = v!), theme, isDark),
                          _buildDropdown('Type', _filterType, {
                            'all': 'All Types',
                            ...{for (final t in TypeChart.types) t: t[0].toUpperCase() + t.substring(1)},
                          }, (v) => setState(() => _filterType = v!), theme, isDark),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filtered.length} moves',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Moves table
                      Card(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                isDark
                                    ? theme.colorScheme.primary.withOpacity(0.15)
                                    : theme.colorScheme.primary.withOpacity(0.06),
                              ),
                              headingTextStyle: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              dividerThickness: 0.5,
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
                                  DataCell(
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => context.go('/moves/${m.rawName}'),
                                        child: Text(
                                          m.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                            decoration: TextDecoration.underline,
                                            decorationColor: theme.colorScheme.primary.withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(m.type.isNotEmpty ? TypeBadge(type: m.type, navigable: true) : const Text('—')),
                                  DataCell(_CategoryIcon(category: m.damageClass)),
                                  DataCell(Text(
                                    m.power?.toString() ?? '—',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: m.power != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.3),
                                    ),
                                  )),
                                  DataCell(Text(
                                    m.accuracy != null ? '${m.accuracy}%' : '—',
                                    style: TextStyle(
                                      color: m.accuracy != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.3),
                                    ),
                                  )),
                                  DataCell(Text(
                                    m.pp?.toString() ?? '—',
                                    style: TextStyle(
                                      color: m.pp != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.3),
                                    ),
                                  )),
                                ]);
                              }).toList(),
                            ),
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
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            isDense: true,
            borderRadius: BorderRadius.circular(12),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: category.isNotEmpty ? category[0].toUpperCase() + category.substring(1) : '',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
