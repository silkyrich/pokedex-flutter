import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/type_colors.dart';
import '../services/app_state.dart';

class PokemonCard extends StatefulWidget {
  final PokemonBasic pokemon;
  final List<String>? types;
  final VoidCallback onTap;
  final int? bst; // Base Stat Total for showcase cards

  const PokemonCard({
    super.key,
    required this.pokemon,
    this.types,
    required this.onTap,
    this.bst,
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
    final scale = AppState().cardScale;

    // Progressive information density for continuous zoom
    final bool showTinyDots = scale < 0.2;  // Just colored dots for types
    final bool showSmallPills = scale >= 0.2 && scale < 0.35;  // Tiny type pills
    final bool showCompactBadges = scale >= 0.35 && scale < 0.5;  // Compact badges
    final bool showIdBadge = scale >= 0.35;  // ID appears at medium sizes
    final bool showNameBox = scale >= 0.15;  // Name in box (vs overlay)
    final bool useTinyText = scale < 0.2;  // Very small text for tiny icons
    final bool useCompactText = scale < 0.5;  // Compact text for small/medium
    final bool useShowcaseLayout = scale >= 0.8;  // Pokemon card-like layout for huge cards

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
              borderRadius: BorderRadius.circular(20),
              // Pokemon card-style gold border for showcase
              border: Border.all(
                color: useShowcaseLayout
                    ? const Color(0xFFD4AF37) // Gold border for giant cards
                    : _hovered
                        ? _primaryColor.withOpacity(0.5)
                        : isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.shade200,
                width: useShowcaseLayout ? 4 : (_hovered ? 2 : 1),
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
                  // Soft glow behind Pokemon - subtle and elegant
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.04),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pokemon card-style header for showcase layout
                  if (useShowcaseLayout && widget.bst != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(19),
                            topRight: Radius.circular(19),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Name - Pokemon card style
                            Expanded(
                              child: Text(
                                widget.pokemon.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // HP (using BST as proxy)
                            Tooltip(
                              message: 'Base Stat Total: ${widget.bst}\nCombined power of all stats',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              waitDuration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade900,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'HP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.bst}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Showcase: Artwork frame (like real cards)
                  if (useShowcaseLayout)
                    Positioned(
                      top: 60,
                      left: 12,
                      right: 12,
                      bottom: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFAF0), // Light cream for artwork area
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                  // Pokemon image - fills entire card with Hero animation
                  Padding(
                    padding: useTinyText
                        ? const EdgeInsets.all(4)
                        : useCompactText
                            ? const EdgeInsets.all(8)
                            : useShowcaseLayout
                                ? const EdgeInsets.fromLTRB(24, 72, 24, 170)
                                : const EdgeInsets.all(16),
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
                          size: useTinyText ? 20 : useCompactText ? 40 : 60,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  // Name - progressive sizing from tiny to large (hidden in showcase layout)
                  if (showNameBox && !useShowcaseLayout)
                    Positioned(
                      top: useTinyText ? 2 : useCompactText ? 4 : 8,
                      left: useTinyText ? 2 : useCompactText ? 4 : 8,
                      right: showIdBadge ? (useTinyText ? 20 : useCompactText ? 40 : 50) : (useTinyText ? 2 : 4),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: useTinyText ? 3 : useCompactText ? 6 : 10,
                          vertical: useTinyText ? 1 : useCompactText ? 3 : 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(useTinyText ? 0.6 : 0.75),
                              Colors.black.withOpacity(useTinyText ? 0.5 : 0.65),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(useTinyText ? 4 : useCompactText ? 6 : 10),
                          border: Border.all(
                            color: Colors.white.withOpacity(useTinyText ? 0.3 : 0.5),
                            width: useTinyText ? 0.5 : 2,
                          ),
                          boxShadow: useTinyText ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.pokemon.displayName,
                          style: TextStyle(
                            fontWeight: useTinyText ? FontWeight.w700 : FontWeight.w800,
                            fontSize: useTinyText ? 7 : useCompactText ? 10 : 13,
                            color: Colors.white,
                            letterSpacing: useTinyText ? 0.1 : 0.3,
                            height: useTinyText ? 1.2 : 1.0,
                            shadows: useTinyText ? null : const [
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
                  // ID badge - appears at medium sizes and up (hidden in showcase layout)
                  if (showIdBadge && !useShowcaseLayout)
                    Positioned(
                      top: useCompactText ? 4 : 8,
                      right: useCompactText ? 4 : 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: useCompactText ? 4 : 5,
                          vertical: useCompactText ? 1 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(useCompactText ? 4 : 5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.pokemon.idString,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: useCompactText ? 6 : 8,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  // Showcase: Info section (like moves section on real cards)
                  if (useShowcaseLayout && widget.bst != null)
                    Positioned(
                      bottom: 65,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8DC), // Cream color like real cards
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Power indicator (styled like an attack)
                            Row(
                              children: [
                                // Type energy icon
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // "Attack" name
                                Expanded(
                                  child: Text(
                                    'Base Power',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                // Damage number
                                Text(
                                  '${widget.bst}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Description (like attack description)
                            Text(
                              'Total of all base stats combined.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Showcase: Decorative line separator (like real cards)
                  if (useShowcaseLayout)
                    Positioned(
                      bottom: 52,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor.withOpacity(0.3),
                              _primaryColor.withOpacity(0.8),
                              _secondaryColor?.withOpacity(0.8) ?? _primaryColor.withOpacity(0.8),
                              (_secondaryColor ?? _primaryColor).withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // Showcase: Pokemon card-style bottom info section
                  if (useShowcaseLayout)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8DC), // Cream color like real cards
                          border: const Border(
                            top: BorderSide(
                              color: Color(0xFFD4AF37),
                              width: 2,
                            ),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Pokedex number - styled like card number
                            Text(
                              widget.pokemon.idString,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            // Types will appear here via the existing type badges section
                          ],
                        ),
                      ),
                    ),

                  // Type indicators - progressive: dots → pills → badges
                  if (widget.types != null && widget.types!.isNotEmpty)
                    Positioned(
                      bottom: useShowcaseLayout ? 16 : useTinyText ? 2 : useCompactText ? 4 : 8,
                      left: useShowcaseLayout ? null : (useTinyText ? 2 : useCompactText ? 4 : 8),
                      right: useShowcaseLayout ? 16 : (useTinyText ? 2 : useCompactText ? 4 : 8),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: showTinyDots ? 2 : showSmallPills ? 2 : useCompactText ? 3 : 6,
                        runSpacing: showTinyDots ? 2 : showSmallPills ? 2 : useCompactText ? 2 : 4,
                        children: widget.types!.map((t) {
                          final typeColor = TypeColors.getColor(t);

                          // Tiny mode: Just colored dots
                          if (showTinyDots) {
                            return Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 0.5,
                                ),
                              ),
                            );
                          }

                          // Small mode: Tiny type pills with text
                          if (showSmallPills) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                t[0].toUpperCase() + t.substring(1),
                                style: TextStyle(
                                  color: TypeColors.getTextColor(t),
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                            );
                          }

                          // Medium/Large/Showcase mode: Full badges with gradients and shadows
                          final badge = Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: useShowcaseLayout ? 16 : showCompactBadges ? 6 : useCompactText ? 7 : 12,
                              vertical: useShowcaseLayout ? 8 : showCompactBadges ? 2 : useCompactText ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  typeColor.withOpacity(0.95),
                                  typeColor.withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(useShowcaseLayout ? 16 : showCompactBadges ? 6 : useCompactText ? 8 : 14),
                              border: Border.all(
                                color: Colors.white.withOpacity(useShowcaseLayout ? 0.6 : showCompactBadges ? 0.3 : 0.4),
                                width: useShowcaseLayout ? 3 : showCompactBadges ? 1 : useCompactText ? 1 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor.withOpacity(useShowcaseLayout ? 0.5 : showCompactBadges ? 0.2 : 0.4),
                                  blurRadius: useShowcaseLayout ? 12 : showCompactBadges ? 3 : useCompactText ? 6 : 10,
                                  spreadRadius: useShowcaseLayout ? 1 : 0,
                                ),
                              ],
                            ),
                            child: Text(
                              t[0].toUpperCase() + t.substring(1),
                              style: TextStyle(
                                color: TypeColors.getTextColor(t),
                                fontSize: useShowcaseLayout ? 14 : showCompactBadges ? 8 : useCompactText ? 9 : 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: useShowcaseLayout ? 0.8 : showCompactBadges ? 0.3 : useCompactText ? 0.4 : 0.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          );

                          // Add tooltip for medium/large/showcase cards
                          if (!showTinyDots && !showSmallPills) {
                            return Tooltip(
                              message: '${t[0].toUpperCase() + t.substring(1)} type',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              waitDuration: const Duration(milliseconds: 300),
                              child: badge,
                            );
                          }
                          return badge;
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
