import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/move.dart';
import '../services/pokeapi_service.dart';
import '../widgets/type_badge.dart';
import '../widgets/pokemon_image.dart';
import '../utils/type_colors.dart';

class MoveDetailScreen extends StatefulWidget {
  final String moveName;

  const MoveDetailScreen({super.key, required this.moveName});

  @override
  State<MoveDetailScreen> createState() => _MoveDetailScreenState();
}

class _MoveDetailScreenState extends State<MoveDetailScreen> {
  MoveDetail? _move;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMove();
  }

  @override
  void didUpdateWidget(MoveDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.moveName != widget.moveName) _loadMove();
  }

  Future<void> _loadMove() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final move = await PokeApiService.getMoveDetail(widget.moveName);
      if (mounted) setState(() { _move = move; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary)),
              const SizedBox(height: 20),
              Text('Loading move...', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }

    if (_error != null || _move == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text('Failed to load move', style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadMove,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(body: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    final m = _move!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = m.type != null ? TypeColors.getColor(m.type!) : theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final pokemonGridCols = screenWidth > 1000 ? 6 : screenWidth > 700 ? 4 : 3;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  typeColor.withOpacity(isDark ? 0.2 : 0.12),
                  typeColor.withOpacity(isDark ? 0.05 : 0.02),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back to moves
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => context.go('/moves'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chevron_left_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                Text(
                                  'All Moves',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Move name
                      Text(
                        m.displayName,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Type and category
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (m.type != null)
                            TypeBadge(type: m.type!, large: true, fontSize: 14, navigable: true),
                          if (m.damageClass != null)
                            _CategoryChip(category: m.damageClass!),
                        ],
                      ),
                      if (m.flavorText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          m.flavorText!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Stats and Pokemon list
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Move stats card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Move Data',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _statRow('Power', m.power?.toString() ?? '—', theme, bold: m.power != null),
                            _statRow('Accuracy', m.accuracy != null ? '${m.accuracy}%' : '—', theme, bold: m.accuracy != null),
                            _statRow('PP', m.pp?.toString() ?? '—', theme, bold: m.pp != null),
                            _statRow('Category', m.damageClass != null ? m.damageClass![0].toUpperCase() + m.damageClass!.substring(1) : '—', theme),
                            if (m.effectText != null)
                              _statRow('Effect', m.effectText!, theme),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Pokemon that learn this move
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Pokemon That Learn This Move',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${m.learnedByPokemon.length}',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (m.learnedByPokemon.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No Pokemon learn this move.',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: pokemonGridCols,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: m.learnedByPokemon.length,
                                itemBuilder: (context, index) {
                                  final ref = m.learnedByPokemon[index];
                                  return _PokemonRefCard(
                                    ref: ref,
                                    isDark: isDark,
                                    onTap: () => context.go('/pokemon/${ref.id}'),
                                  );
                                },
                              ),
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
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, ThemeData theme, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            category[0].toUpperCase() + category.substring(1),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _PokemonRefCard extends StatefulWidget {
  final MovePokemonRef ref;
  final bool isDark;
  final VoidCallback onTap;

  const _PokemonRefCard({required this.ref, required this.isDark, required this.onTap});

  @override
  State<_PokemonRefCard> createState() => _PokemonRefCardState();
}

class _PokemonRefCardState extends State<_PokemonRefCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered
                ? theme.colorScheme.primary.withOpacity(widget.isDark ? 0.1 : 0.05)
                : widget.isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : widget.isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PokemonImage(
                imageUrl: widget.ref.spriteUrl,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                fallbackIconSize: 32,
                fallbackIconColor: theme.colorScheme.onSurface.withOpacity(0.15),
              ),
              const SizedBox(height: 4),
              Text(
                widget.ref.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.ref.idString,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
