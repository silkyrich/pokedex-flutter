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

class _PokemonCardState extends State<PokemonCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? const Color(0xFF3B5BA7) : const Color(0xFFE0E0E0),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.pokemon.idString,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Image.network(
                widget.pokemon.spriteUrl,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(Icons.catching_pokemon, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.pokemon.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF3B5BA7),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: TypeColors.getColor(t),
                        borderRadius: BorderRadius.circular(3),
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
        ),
      ),
    );
  }
}
