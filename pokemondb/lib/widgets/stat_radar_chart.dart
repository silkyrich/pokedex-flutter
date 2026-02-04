import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A beautiful radar/spider chart for Pokémon stats with the Pokémon sprite
/// displayed in the center. Supports animated transitions and optional
/// comparison overlays for team views.
class StatRadarChart extends StatefulWidget {
  final Map<String, int> stats;
  final String? imageUrl;
  final Color? fillColor;
  final Color? borderColor;
  final Map<String, int>? comparisonStats;
  final Color? comparisonColor;
  final double size;

  const StatRadarChart({
    super.key,
    required this.stats,
    this.imageUrl,
    this.fillColor,
    this.borderColor,
    this.comparisonStats,
    this.comparisonColor,
    this.size = 280,
  });

  @override
  State<StatRadarChart> createState() => _StatRadarChartState();
}

class _StatRadarChartState extends State<StatRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void didUpdateWidget(StatRadarChart old) {
    super.didUpdateWidget(old);
    if (old.stats != widget.stats) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<String> _statOrder = [
    'hp', 'attack', 'defense', 'speed', 'special-defense', 'special-attack',
  ];

  static const Map<String, String> _statLabels = {
    'hp': 'HP',
    'attack': 'ATK',
    'defense': 'DEF',
    'special-attack': 'SpA',
    'special-defense': 'SpD',
    'speed': 'SPD',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = widget.fillColor ??
        (isDark ? const Color(0xFF4FC3F7) : const Color(0xFF3B5BA7));
    final borderColor = widget.borderColor ?? fillColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RadarChartPainter(
              stats: widget.stats,
              statOrder: _statOrder,
              statLabels: _statLabels,
              animationValue: _animation.value,
              fillColor: fillColor.withOpacity(0.25),
              borderColor: borderColor,
              gridColor: isDark ? Colors.white24 : Colors.grey.shade300,
              labelColor: isDark ? Colors.white70 : Colors.grey.shade700,
              comparisonStats: widget.comparisonStats,
              comparisonColor: widget.comparisonColor,
            ),
            child: widget.imageUrl != null
                ? Center(
                    child: Opacity(
                      opacity: 0.3 + (_animation.value * 0.15),
                      child: Image.network(
                        widget.imageUrl!,
                        width: widget.size * 0.32,
                        height: widget.size * 0.32,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.catching_pokemon,
                          size: widget.size * 0.18,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, int> stats;
  final List<String> statOrder;
  final Map<String, String> statLabels;
  final double animationValue;
  final Color fillColor;
  final Color borderColor;
  final Color gridColor;
  final Color labelColor;
  final Map<String, int>? comparisonStats;
  final Color? comparisonColor;

  _RadarChartPainter({
    required this.stats,
    required this.statOrder,
    required this.statLabels,
    required this.animationValue,
    required this.fillColor,
    required this.borderColor,
    required this.gridColor,
    required this.labelColor,
    this.comparisonStats,
    this.comparisonColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.35;
    final sides = statOrder.length;
    final angleStep = (2 * math.pi) / sides;
    // Rotate so HP is at the top
    const startAngle = -math.pi / 2;

    // Draw grid rings
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 5; ring++) {
      final r = maxRadius * ring / 5;
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = startAngle + angleStep * (i % sides);
        final p = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw grid spokes
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final end = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    // Draw stat values
    _drawStatPolygon(
      canvas, center, maxRadius, sides, angleStep, startAngle,
      stats, fillColor, borderColor, animationValue,
    );

    // Draw comparison overlay if present
    if (comparisonStats != null && comparisonColor != null) {
      _drawStatPolygon(
        canvas, center, maxRadius, sides, angleStep, startAngle,
        comparisonStats!, comparisonColor!.withOpacity(0.15),
        comparisonColor!, animationValue,
      );
    }

    // Draw labels with values
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = maxRadius + 22;
      final labelPos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final statKey = statOrder[i];
      final label = statLabels[statKey] ?? statKey;
      final value = stats[statKey] ?? 0;

      // Draw label
      final labelSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final labelTp = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      // Draw value beneath label
      final valueSpan = TextSpan(
        text: '$value',
        style: TextStyle(
          color: labelColor.withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      final valueTp = TextPainter(
        text: valueSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      final totalHeight = labelTp.height + valueTp.height + 1;
      labelTp.paint(canvas, Offset(
        labelPos.dx - labelTp.width / 2,
        labelPos.dy - totalHeight / 2,
      ));
      valueTp.paint(canvas, Offset(
        labelPos.dx - valueTp.width / 2,
        labelPos.dy - totalHeight / 2 + labelTp.height + 1,
      ));
    }
  }

  void _drawStatPolygon(
    Canvas canvas, Offset center, double maxRadius,
    int sides, double angleStep, double startAngle,
    Map<String, int> statValues, Color fill, Color border,
    double anim,
  ) {
    final path = Path();
    for (int i = 0; i <= sides; i++) {
      final statKey = statOrder[i % sides];
      final value = (statValues[statKey] ?? 0).clamp(0, 255);
      final ratio = (value / 255.0) * anim;
      final angle = startAngle + angleStep * (i % sides);
      final p = Offset(
        center.dx + maxRadius * ratio * math.cos(angle),
        center.dy + maxRadius * ratio * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    // Fill
    canvas.drawPath(path, Paint()
      ..color = fill
      ..style = PaintingStyle.fill);

    // Border
    canvas.drawPath(path, Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    // Dots at vertices
    for (int i = 0; i < sides; i++) {
      final statKey = statOrder[i];
      final value = (statValues[statKey] ?? 0).clamp(0, 255);
      final ratio = (value / 255.0) * anim;
      final angle = startAngle + angleStep * i;
      final p = Offset(
        center.dx + maxRadius * ratio * math.cos(angle),
        center.dy + maxRadius * ratio * math.sin(angle),
      );
      canvas.drawCircle(p, 4, Paint()..color = border);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) {
    return old.animationValue != animationValue ||
        old.stats != stats ||
        old.comparisonStats != comparisonStats;
  }
}
