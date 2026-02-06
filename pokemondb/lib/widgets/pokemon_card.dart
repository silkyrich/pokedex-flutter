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

  Color? get _secondaryColor {
    if (widget.types != null && widget.types!.length > 1) {
      return TypeColors.getColor(widget.types![1]);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardScale = AppState().cardScale;
    // Determine information density based on card size
    final bool showIdBadge = cardScale >= 0.3; // Hide ID at very small sizes
    final bool useCompactText = cardScale < 0.4; // Use smaller text for sprites
    final bool showFullTypeBadges = cardScale >= 0.35; // Simplify type badges when very small

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
              borderRadius: BorderRadius.circular(20), // Softer, more joyful corners
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
              borderRadius: BorderRadius.circular(19), // Match outer radius
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Smooth blended type-colored background
                  if (_secondaryColor != null)
                    // Dual type - smooth diagonal gradient blend
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor,
                            Color.lerp(_primaryColor, _secondaryColor!, 0.5)!,
                            _secondaryColor!,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    )
                  else
                    // Single type - smooth radial gradient
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            _primaryColor.withOpacity(0.7),
                            _primaryColor,
                            _primaryColor.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  // Soft glow behind Pokemon
                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pokemon image - fills entire card with Hero animation
                  Padding(
                    padding: EdgeInsets.all(useCompactText ? 8 : 16),
                    child: Hero(
                      tag: 'pokemon-sprite-${widget.pokemon.id}',
                      child: Image.network(
                        AppState().usePixelSprites
                            ? widget.pokemon.spriteUrl
                            : widget.pokemon.imageUrl,
                        fit: BoxFit.contain,
                        filterQuality: AppState().usePixelSprites
                            ? FilterQuality.none
                            : FilterQuality.high,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.catching_pokemon,
                          size: useCompactText ? 40 : 60,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  // Name in top-left with type-colored background
                  Positioned(
                    top: useCompactText ? 4 : 8,
                    left: useCompactText ? 4 : 8,
                    right: showIdBadge ? (useCompactText ? 40 : 50) : 4, // Leave space for ID badge if shown
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: useCompactText ? 6 : 10,
                        vertical: useCompactText ? 3 : 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7), // Stronger background for better contrast
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(useCompactText ? 6 : 10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        widget.pokemon.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800, // Bolder
                          fontSize: useCompactText ? 10 : 13, // Slightly larger
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // ID badge - top right corner (hidden at very small sizes)
                  if (showIdBadge)
                    Positioned(
                      top: useCompactText ? 4 : 8,
                      right: useCompactText ? 4 : 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: useCompactText ? 4 : 5,
                          vertical: useCompactText ? 1 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2), // More subtle
                          borderRadius: BorderRadius.circular(useCompactText ? 4 : 5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.pokemon.idString,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5), // More discrete
                            fontSize: useCompactText ? 6 : 8, // Smaller
                            fontWeight: FontWeight.w500, // Less heavy
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  // Type badges - bottom with blended type colors (adaptive sizing)
                  if (widget.types != null && widget.types!.isNotEmpty)
                    Positioned(
                      bottom: useCompactText ? 4 : 8,
                      left: useCompactText ? 4 : 8,
                      right: useCompactText ? 4 : 8,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: useCompactText ? 3 : 6,
                        runSpacing: useCompactText ? 2 : 4,
                        children: widget.types!.map((t) {
                          final typeColor = TypeColors.getColor(t);
                          // At very small sizes, show just colored dots
                          if (!showFullTypeBadges) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            );
                          }
                          // Full badges for larger sizes
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: useCompactText ? 7 : 12, // Slightly larger
                              vertical: useCompactText ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  typeColor.withOpacity(0.9), // More solid
                                  typeColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(useCompactText ? 8 : 14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4), // Stronger border
                                width: useCompactText ? 1 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor.withOpacity(0.4),
                                  blurRadius: useCompactText ? 6 : 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              t[0].toUpperCase() + t.substring(1),
                              style: TextStyle(
                                color: TypeColors.getTextColor(t),
                                fontSize: useCompactText ? 9 : 11, // Slightly larger text
                                fontWeight: FontWeight.w800,
                                letterSpacing: useCompactText ? 0.4 : 0.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
