import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/type_colors.dart';
import '../services/app_state.dart';

// Discrete card layout modes for consistent UX
enum CardLayout {
  tiny,      // 0.0-0.25: Icon grid, just sprite
  compact,   // 0.25-0.5: Small horizontal card, sprite + name + types
  standard,  // 0.5-0.75: Medium vertical card, more details
  large,     // 0.75-0.9: Large vertical card
  showcase,  // 0.9-1.0: Pokemon card style
}

// Map scale value to discrete card layout
CardLayout _getCardLayout(double scale) {
  if (scale < 0.25) return CardLayout.tiny;
  if (scale < 0.5) return CardLayout.compact;
  if (scale < 0.75) return CardLayout.standard;
  if (scale < 0.9) return CardLayout.large;
  return CardLayout.showcase;
}

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

    // Discrete card layout modes - simple and predictable
    final CardLayout cardLayout = _getCardLayout(scale);

    // Mode-specific flags
    final bool showTinyDots = cardLayout == CardLayout.tiny;
    final bool showSmallPills = cardLayout == CardLayout.compact;
    final bool showCompactBadges = cardLayout == CardLayout.standard || cardLayout == CardLayout.large;
    final bool showIdBadge = cardLayout != CardLayout.tiny;
    final bool showNameBox = cardLayout != CardLayout.tiny;
    final bool useTinyText = cardLayout == CardLayout.tiny;
    final bool useCompactText = cardLayout == CardLayout.compact;
    final bool useHorizontalLayout = cardLayout == CardLayout.compact;
    final bool useShowcaseLayout = cardLayout == CardLayout.showcase;

    final cardWidget = MouseRegion(
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
              // At tiny size: no background/border - just the sprite
              color: scale < 0.15
                  ? Colors.transparent
                  : isDark ? const Color(0xFF1E1E2A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              // Pokemon card-style gold border for showcase, no border at tiny/small
              border: scale < 0.3
                  ? null // No border at tiny/small sizes - maximize sprite space
                  : Border.all(
                      color: useShowcaseLayout
                          ? const Color(0xFFD4AF37) // Gold border for giant cards
                          : _hovered
                              ? _primaryColor.withOpacity(0.5)
                              : isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.grey.shade200,
                      width: useShowcaseLayout ? 3 : (_hovered ? 1.5 : 0.5),  // Thinner borders
                    ),
              // No shadow at tiny size - just floating sprites
              boxShadow: scale < 0.15
                  ? null
                  : _hovered
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
              child: useHorizontalLayout
                  ? _buildHorizontalCard(context, theme, isDark, scale)
                  : Stack(
                fit: StackFit.expand,
                children: [
                  // Type-colored background - fades in as scale increases (0.1 → 0.3)
                  // At tiniest sizes (< 0.1), pure white/neutral for icon clarity
                  if (scale >= 0.08)
                    if (_secondaryColor != null)
                      // Dual type - smooth diagonal gradient blend
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primaryColor.withOpacity(scale < 0.3 ? (scale - 0.08) / 0.22 * 0.8 : 1.0),
                              Color.lerp(_primaryColor, _secondaryColor!, 0.5)!.withOpacity(scale < 0.3 ? (scale - 0.08) / 0.22 * 0.8 : 1.0),
                              _secondaryColor!.withOpacity(scale < 0.3 ? (scale - 0.08) / 0.22 * 0.8 : 1.0),
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
                              _primaryColor.withOpacity(scale < 0.3 ? (scale - 0.08) / 0.22 * 0.6 : 0.7),
                              _primaryColor.withOpacity(scale < 0.3 ? (scale - 0.08) / 0.22 * 0.8 : 1.0),
                              _primaryColor.withOpacity(scale < 0.3 ? (scale - 0.08) / 0.22 * 0.7 : 0.9),
                            ],
                          ),
                        ),
                      ),
                  // Soft glow behind Pokemon - only for larger cards
                  if (scale >= 0.3)
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

                  // Showcase: Artwork frame (like real cards) - larger without stats section
                  if (useShowcaseLayout)
                    Positioned(
                      top: 60,
                      left: 12,
                      right: 12,
                      bottom: 65, // More space for artwork
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

                  // Pokemon image - normalized sizing with minimal padding
                  Padding(
                    padding: scale < 0.2
                        ? const EdgeInsets.all(2) // Tiny padding to prevent clipping
                        : scale < 0.4
                            ? const EdgeInsets.all(6)  // Small padding
                            : scale < 0.6
                                ? const EdgeInsets.all(8)  // Medium padding
                                : useShowcaseLayout
                                    ? const EdgeInsets.fromLTRB(24, 72, 24, 75) // Showcase artwork
                                    : const EdgeInsets.all(14),  // Standard padding
                    child: Hero(
                      tag: 'pokemon-sprite-${widget.pokemon.id}',
                      child: Container(
                        // Normalize sprite sizes with drop shadow for better visibility
                        decoration: BoxDecoration(
                          // Subtle drop shadow to make sprites pop
                          boxShadow: scale >= 0.2 ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: scale < 0.4 ? 4 : 8,
                              offset: Offset(0, scale < 0.4 ? 2 : 3),
                            ),
                          ] : null,
                        ),
                        child: Image.network(
                          // Always use official artwork - scales better than sprites
                          widget.pokemon.imageUrl,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          isAntiAlias: true,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.catching_pokemon,
                            size: useTinyText ? 20 : useCompactText ? 40 : 60,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Name - progressive sizing (hidden in tiny mode and showcase layout)
                  if (showNameBox && !useShowcaseLayout && !showTinyDots)
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
                  // Removed boring stats section - artwork gets full space now!

                  // Showcase: Pokemon card-style bottom info section
                  // Showcase: Compact info footer with stats grid and abilities
                  if (useShowcaseLayout && widget.bst != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8DC), // Cream color
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Types horizontal
                            if (widget.types != null && widget.types!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6,
                                  children: widget.types!.map((type) {
                                    return TypeBadge(type: type, size: BadgeSize.small);
                                  }).toList(),
                                ),
                              ),
                            // Stats grid: 2 rows × 3 columns
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatCell('HP', '45'),
                                      _buildStatCell('ATK', '49'),
                                      _buildStatCell('DEF', '49'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatCell('SPA', '65'),
                                      _buildStatCell('SPD', '65'),
                                      _buildStatCell('SPE', '45'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Abilities horizontal
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 4),
                              child: Text(
                                'Overgrow • Chlorophyll',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // ID number
                            Text(
                              widget.pokemon.idString,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Type indicators - progressive: dots → pills → badges (hidden in tiny mode - just pure sprites)
                  if (widget.types != null && widget.types!.isNotEmpty && scale >= 0.15)
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
              ),  // End of Stack
            ),  // End of ClipRRect
          ),  // End of AnimatedContainer
        ),
      ),
    );

    // Add tooltip for tiny cards - shows name on hover
    if (showTinyDots || useTinyText) {
      return Tooltip(
        message: widget.pokemon.displayName,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 200),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildStatCell(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, ThemeData theme, bool isDark, double scale) {
    // Horizontal card layout: sprite on left, info on right
    return Container(
      decoration: BoxDecoration(
        gradient: _secondaryColor != null
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _primaryColor.withOpacity(0.9),
                  _secondaryColor!.withOpacity(0.9),
                ],
              )
            : LinearGradient(
                colors: [_primaryColor.withOpacity(0.9), _primaryColor.withOpacity(0.9)],
              ),
      ),
      child: Row(
        children: [
          // Left: Pokemon sprite (40% width)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Hero(
                tag: 'pokemon-sprite-${widget.pokemon.id}',
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.network(
                    // Always use official artwork
                    widget.pokemon.imageUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    isAntiAlias: true,
                  ),
                ),
              ),
            ),
          ),
          // Right: Pokemon info (60% width)
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    widget.pokemon.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: scale < 0.4 ? 11 : 14,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Types
                  if (widget.types != null && widget.types!.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: widget.types!.map((type) {
                        return TypeBadge(
                          type: type,
                          size: scale < 0.4 ? BadgeSize.tiny : BadgeSize.small,
                        );
                      }).toList(),
                    ),
                  // ID
                  if (scale >= 0.35)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '#${widget.pokemon.id.toString().padLeft(4, '0')}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
