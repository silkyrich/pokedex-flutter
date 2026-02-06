import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../utils/image_processor.dart';

const _spriteBase =
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';

/// Unified widget for displaying Pokemon images throughout the app.
///
/// Handles:
/// - Transparent background processing (when enabled in settings)
/// - Default Pokeball error/fallback icon
/// - Artwork vs sprite URL generation from a Pokemon ID
///
/// Use [PokemonImage] everywhere instead of raw [Image.network] for
/// Pokemon artwork/sprites.
class PokemonImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  final double fallbackIconSize;
  final Color? fallbackIconColor;

  const PokemonImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    this.fallbackIconSize = 40,
    this.fallbackIconColor,
  });

  /// Build from a Pokemon ID using the official artwork URL.
  PokemonImage.artwork(
    int id, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    this.fallbackIconSize = 40,
    this.fallbackIconColor,
  }) : imageUrl = '$_spriteBase/other/official-artwork/$id.png';

  /// Build from a Pokemon ID using the small pixel sprite URL.
  PokemonImage.sprite(
    int id, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.none,
    this.isAntiAlias = false,
    this.fallbackIconSize = 24,
    this.fallbackIconColor,
  }) : imageUrl = '$_spriteBase/$id.png';

  @override
  State<PokemonImage> createState() => _PokemonImageState();
}

class _PokemonImageState extends State<PokemonImage> {
  Uint8List? _processedBytes;
  String? _loadedUrl;

  /// Only process artwork images — sprites are already tight pixel art.
  bool get _shouldProcess =>
      AppState().transparentBackgrounds &&
      widget.imageUrl.contains('official-artwork');

  @override
  void initState() {
    super.initState();
    if (_shouldProcess) _loadAndProcess();
  }

  @override
  void didUpdateWidget(PokemonImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _processedBytes = null;
      if (_shouldProcess) _loadAndProcess();
    }
  }

  Future<void> _loadAndProcess() async {
    final url = widget.imageUrl;
    _loadedUrl = url;

    final result = await ImageProcessor.getProcessedImage(url);

    if (!mounted || _loadedUrl != url) return;

    setState(() {
      _processedBytes = result;
    });
  }

  Widget _fallbackIcon() => Icon(
        Icons.catching_pokemon,
        size: widget.fallbackIconSize,
        color: widget.fallbackIconColor ?? Colors.white.withOpacity(0.3),
      );

  @override
  Widget build(BuildContext context) {
    if (_shouldProcess && _processedBytes != null) {
      return Image.memory(
        _processedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: widget.filterQuality,
        isAntiAlias: widget.isAntiAlias,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }

    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      isAntiAlias: widget.isAntiAlias,
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }
}
