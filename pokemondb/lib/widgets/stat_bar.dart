import 'package:flutter/material.dart';

class StatBar extends StatefulWidget {
  final String label;
  final int value;
  final int maxValue;
  final bool animate;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 255,
    this.animate = true,
  });

  @override
  State<StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<StatBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(StatBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const Map<String, String> _statNames = {
    'hp': 'HP',
    'attack': 'Attack',
    'defense': 'Defense',
    'special-attack': 'Sp. Atk',
    'special-defense': 'Sp. Def',
    'speed': 'Speed',
  };

  Color get _barColor {
    if (widget.value < 30) return const Color(0xFFEF4444);
    if (widget.value < 60) return const Color(0xFFF97316);
    if (widget.value < 90) return const Color(0xFFEAB308);
    if (widget.value < 120) return const Color(0xFF84CC16);
    if (widget.value < 150) return const Color(0xFF22C55E);
    return const Color(0xFF06B6D4);
  }

  Color get _barEndColor {
    if (widget.value < 30) return const Color(0xFFF87171);
    if (widget.value < 60) return const Color(0xFFFBBF24);
    if (widget.value < 90) return const Color(0xFFFDE047);
    if (widget.value < 120) return const Color(0xFFA3E635);
    if (widget.value < 150) return const Color(0xFF4ADE80);
    return const Color(0xFF22D3EE);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              _statNames[widget.label] ?? widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${widget.value}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _BarAnimation(
              animation: _animation,
              value: widget.value,
              maxValue: widget.maxValue,
              barColor: _barColor,
              barEndColor: _barEndColor,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarAnimation extends AnimatedWidget {
  final int value;
  final int maxValue;
  final Color barColor;
  final Color barEndColor;
  final bool isDark;

  const _BarAnimation({
    required Animation<double> animation,
    required this.value,
    required this.maxValue,
    required this.barColor,
    required this.barEndColor,
    required this.isDark,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    final fraction = (value / maxValue) * anim.value;

    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0, 1).toDouble(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [barColor, barEndColor]),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: barColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
