import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../utils/type_colors.dart';

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

class _PokemonCardState extends State<PokemonCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Color _primaryColor() {
    if (widget.types != null && widget.types!.isNotEmpty) {
      return TypeColors.getColor(widget.types!.first);
    }
    return const Color(0xFF3B5BA7);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = _primaryColor();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _hovered
                    ? [
                        primary.withOpacity(isDark ? 0.25 : 0.12),
                        primary.withOpacity(isDark ? 0.10 : 0.04),
                      ]
                    : [
                        isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      ],
              ),
              border: Border.all(
                color: _hovered
                    ? primary.withOpacity(0.6)
                    : isDark
                        ? Colors.grey.shade800
                        : const Color(0xFFE0E0E0),
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // Decorative pokéball watermark
                Positioned(
                  right: -20,
                  top: -20,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hovered ? 0.08 : 0.03,
                    child: Icon(
                      Icons.catching_pokemon,
                      size: 90,
                      color: primary,
                    ),
                  ),
                ),
                // Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.pokemon.idString,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade500 : const Color(0xFF999999),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
                      child: Image.network(
                        widget.pokemon.spriteUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => SizedBox(
                          width: 80,
                          height: 80,
                          child: Icon(Icons.catching_pokemon, size: 40,
                              color: isDark ? Colors.grey.shade600 : Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.pokemon.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.types != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.types!.map((t) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TypeColors.getColor(t),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: TypeColors.getColor(t).withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              t[0].toUpperCase() + t.substring(1),
                              style: TextStyle(
                                color: TypeColors.getTextColor(t),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
