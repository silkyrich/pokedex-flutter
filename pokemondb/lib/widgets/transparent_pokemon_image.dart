import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../utils/image_processor.dart';

/// Displays a Pokemon image with its background removed and transparent
/// margins trimmed, producing a clean icon-like appearance.
///
/// Falls back to the original network image while processing or on failure.
class TransparentPokemonImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const TransparentPokemonImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    this.errorBuilder,
  });

  @override
  State<TransparentPokemonImage> createState() =>
      _TransparentPokemonImageState();
}

class _TransparentPokemonImageState extends State<TransparentPokemonImage> {
  Uint8List? _processedBytes;
  bool _hasError = false;
  String? _loadedUrl;

  @override
  void initState() {
    super.initState();
    _loadAndProcess();
  }

  @override
  void didUpdateWidget(TransparentPokemonImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadAndProcess();
    }
  }

  Future<void> _loadAndProcess() async {
    final url = widget.imageUrl;
    _loadedUrl = url;

    final result = await ImageProcessor.getProcessedImage(url);

    if (!mounted || _loadedUrl != url) return;

    setState(() {
      _processedBytes = result;
      _hasError = result == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show processed image if available
    if (_processedBytes != null) {
      return Image.memory(
        _processedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: widget.filterQuality,
        isAntiAlias: widget.isAntiAlias,
        errorBuilder: widget.errorBuilder,
      );
    }

    // Fallback: show original network image while processing or on error
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      isAntiAlias: widget.isAntiAlias,
      errorBuilder: widget.errorBuilder,
    );
  }
}
