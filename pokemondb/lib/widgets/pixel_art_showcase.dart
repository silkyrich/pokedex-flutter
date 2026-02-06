import 'package:flutter/material.dart';
import 'pokemon_image.dart';

/// Display modes for pixel art rendering.
enum PixelDisplayMode {
  /// Sharp nearest-neighbour — each pixel is a crisp square.
  crisp('Crisp', FilterQuality.none),

  /// Smooth bilinear interpolation — softer, blended look.
  smooth('Smooth', FilterQuality.medium),

  /// High quality bicubic — maximum smoothing.
  hq('HQ', FilterQuality.high);

  final String label;
  final FilterQuality quality;
  const PixelDisplayMode(this.label, this.quality);
}

/// A showcase container for Pokemon pixel sprites.
///
/// Renders the sprite at integer scale factors (1x–4x) with selectable
/// filtering modes so the pixel art can be appreciated at any zoom level.
class PixelArtShowcase extends StatefulWidget {
  final int pokemonId;
  final Color typeColor;
  final bool isDark;

  const PixelArtShowcase({
    super.key,
    required this.pokemonId,
    required this.typeColor,
    required this.isDark,
  });

  @override
  State<PixelArtShowcase> createState() => _PixelArtShowcaseState();
}

class _PixelArtShowcaseState extends State<PixelArtShowcase> {
  int _scale = 2; // Default 2x (192×192)
  PixelDisplayMode _mode = PixelDisplayMode.crisp;

  static const int _nativeSize = 96;
  static const List<int> _scales = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final displaySize = (_nativeSize * _scale).toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.typeColor.withOpacity(widget.isDark ? 0.1 : 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sprite at selected scale
          Container(
            width: displaySize,
            height: displaySize,
            decoration: BoxDecoration(
              // Checkerboard-style subtle background to show transparency
              color: widget.typeColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PokemonImage.sprite(
              widget.pokemonId,
              width: displaySize,
              height: displaySize,
              filterQuality: _mode.quality,
              fallbackIconSize: displaySize * 0.5,
              fallbackIconColor: widget.typeColor.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 10),
          // Controls row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scale selector
              ..._scales.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _ChipButton(
                      label: '${s}x',
                      selected: _scale == s,
                      color: widget.typeColor,
                      onTap: () => setState(() => _scale = s),
                    ),
                  )),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 20,
                color: widget.typeColor.withOpacity(0.15),
              ),
              const SizedBox(width: 8),
              // Display mode selector
              ...PixelDisplayMode.values.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _ChipButton(
                      label: m.label,
                      selected: _mode == m,
                      color: widget.typeColor,
                      onTap: () => setState(() => _mode = m),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withOpacity(0.4) : color.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
