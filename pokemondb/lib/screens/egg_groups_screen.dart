import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EggGroupsScreen extends StatelessWidget {
  const EggGroupsScreen({super.key});

  // All egg groups from PokeAPI
  static const List<Map<String, String>> _eggGroups = [
    {'id': '1', 'name': 'monster', 'display': 'Monster', 'desc': 'Large, reptilian Pokemon'},
    {'id': '2', 'name': 'water1', 'display': 'Water 1', 'desc': 'Amphibious Pokemon'},
    {'id': '3', 'name': 'bug', 'display': 'Bug', 'desc': 'Insect-like Pokemon'},
    {'id': '4', 'name': 'flying', 'display': 'Flying', 'desc': 'Avian Pokemon'},
    {'id': '5', 'name': 'ground', 'display': 'Field', 'desc': 'Land-based mammals'},
    {'id': '6', 'name': 'fairy', 'display': 'Fairy', 'desc': 'Magical Pokemon'},
    {'id': '7', 'name': 'plant', 'display': 'Grass', 'desc': 'Plant-based Pokemon'},
    {'id': '8', 'name': 'humanshape', 'display': 'Human-Like', 'desc': 'Bipedal Pokemon'},
    {'id': '9', 'name': 'water3', 'display': 'Water 3', 'desc': 'Invertebrate Pokemon'},
    {'id': '10', 'name': 'mineral', 'display': 'Mineral', 'desc': 'Inorganic Pokemon'},
    {'id': '11', 'name': 'indeterminate', 'display': 'Amorphous', 'desc': 'Gaseous/amorphous Pokemon'},
    {'id': '12', 'name': 'water2', 'display': 'Water 2', 'desc': 'Fish-like Pokemon'},
    {'id': '13', 'name': 'ditto', 'display': 'Ditto', 'desc': 'Only Ditto'},
    {'id': '14', 'name': 'dragon', 'display': 'Dragon', 'desc': 'Dragon Pokemon'},
    {'id': '15', 'name': 'no-eggs', 'display': 'Undiscovered', 'desc': 'Cannot breed'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Egg Groups'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 1000
                    ? 3
                    : screenWidth > 700
                        ? 2
                        : 1,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = _eggGroups[index];
                  return _EggGroupCard(
                    name: group['name']!,
                    displayName: group['display']!,
                    description: group['desc']!,
                  );
                },
                childCount: _eggGroups.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EggGroupCard extends StatefulWidget {
  final String name;
  final String displayName;
  final String description;

  const _EggGroupCard({
    required this.name,
    required this.displayName,
    required this.description,
  });

  @override
  State<_EggGroupCard> createState() => _EggGroupCardState();
}

class _EggGroupCardState extends State<_EggGroupCard> {
  bool _hovered = false;

  IconData get _icon {
    switch (widget.name) {
      case 'monster':
        return Icons.pets;
      case 'water1':
      case 'water2':
      case 'water3':
        return Icons.water_drop;
      case 'bug':
        return Icons.bug_report;
      case 'flying':
        return Icons.flight;
      case 'ground':
        return Icons.terrain;
      case 'fairy':
        return Icons.auto_awesome;
      case 'plant':
        return Icons.eco;
      case 'humanshape':
        return Icons.person;
      case 'mineral':
        return Icons.diamond;
      case 'indeterminate':
        return Icons.cloud;
      case 'ditto':
        return Icons.transform;
      case 'dragon':
        return Icons.whatshot;
      case 'no-eggs':
        return Icons.block;
      default:
        return Icons.catching_pokemon;
    }
  }

  Color get _color {
    switch (widget.name) {
      case 'monster':
        return const Color(0xFF8B4513);
      case 'water1':
      case 'water2':
      case 'water3':
        return const Color(0xFF4A90E2);
      case 'bug':
        return const Color(0xFF8BC34A);
      case 'flying':
        return const Color(0xFF81D4FA);
      case 'ground':
        return const Color(0xFFA0826D);
      case 'fairy':
        return const Color(0xFFEC407A);
      case 'plant':
        return const Color(0xFF4CAF50);
      case 'humanshape':
        return const Color(0xFF9C27B0);
      case 'mineral':
        return const Color(0xFF607D8B);
      case 'indeterminate':
        return const Color(0xFF9E9E9E);
      case 'ditto':
        return const Color(0xFFE91E63);
      case 'dragon':
        return const Color(0xFF7C3AED);
      case 'no-eggs':
        return const Color(0xFF757575);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/egg-groups/${widget.name}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? _color : theme.dividerColor,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, color: _color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
