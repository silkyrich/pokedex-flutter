import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/type_colors.dart';
import '../services/app_state.dart';

class PokemonCard extends StatefulWidget {
  final PokemonBasic pokemon;
  final List<String>? types;
  final VoidCallback onTap;

  const PokemonCard({
    super.key,
    required this.pokemon,
    this.types,
    required this.onTap,
  });

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    if (widget.types != null && widget.types!.isNotEmpty) {
      return TypeColors.getColor(widget.types!.first);
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _controller.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? _primaryColor.withOpacity(0.5)
                    : isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.shade200,
                width: _hovered ? 2 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full card type gradient background
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          _primaryColor.withOpacity(isDark ? 0.12 : 0.06),
                          _primaryColor.withOpacity(isDark ? 0.18 : 0.1),
                        ],
                      ),
                    ),
                  ),
                  // Pokemon image - fills entire card
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Hero(
                      tag: 'pokemon-sprite-${widget.pokemon.id}',
                      child: Image.network(
                        AppState().useArtwork
                            ? widget.pokemon.imageUrl
                            : widget.pokemon.spriteUrl,
                        fit: BoxFit.contain,
                        filterQuality: AppState().useArtwork
                            ? FilterQuality.high
                            : FilterQuality.none,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.catching_pokemon,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  // ID badge - top left corner
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.pokemon.idString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Name and types - bottom overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.pokemon.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.types != null) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: widget.types!.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: TypeColors.getColor(t),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    t[0].toUpperCase() + t.substring(1),
                                    style: TextStyle(
                                      color: TypeColors.getTextColor(t),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
