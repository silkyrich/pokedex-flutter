import 'package:flutter/material.dart';
import '../models/pokemon.dart';

/// Displays Pokemon artwork or sprites with automatic border trimming.
///
/// Applies ClipRect + Transform.scale to trim the 22px transparent border
/// from PokeAPI official artwork (475→431px). This makes Pokemon appear
/// larger and removes excess whitespace while preserving relative sizes.
class PokemonImage extends StatelessWidget {
  final PokemonBasic pokemon;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useSprite; // true = pixel sprite, false = official artwork
  final bool shiny; // Future: support shiny variants
  final FilterQuality filterQuality;

  const PokemonImage({
    super.key,
    required this.pokemon,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.useSprite = false,
    this.shiny = false,
    this.filterQuality = FilterQuality.medium,
  });

  /// Scale factor for artwork trim (475/431 ≈ 1.102)
  /// PokeAPI artwork is 475x475px with 22px border on all edges
  static const double _artworkTrimScale = 475 / 431;

  String get _imageUrl {
    // TODO: Add shiny sprite support when needed
    // if (shiny) return 'https://raw.githubusercontent.com/.../shiny/${pokemon.id}.png';
    return useSprite ? pokemon.spriteUrl : pokemon.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      _imageUrl,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      isAntiAlias: true,
      errorBuilder: (_, __, ___) => Icon(
        Icons.catching_pokemon,
        size: (width ?? height ?? 60) * 0.5,
        color: Colors.white.withOpacity(0.3),
      ),
    );

    // Only apply trim to official artwork (not sprites)
    if (!useSprite) {
      image = ClipRect(
        child: Transform.scale(
          scale: _artworkTrimScale,
          child: image,
        ),
      );
    }

    return image;
  }
}
