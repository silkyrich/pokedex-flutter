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
      duration: const Duration(milliseconds: 900),
      vsync: this,
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
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _barColor(int value) {
    if (value < 30) return const Color(0xFFF34444);
    if (value < 60) return const Color(0xFFFF7F0F);
    if (value < 90) return const Color(0xFFFFDD57);
    if (value < 120) return const Color(0xFFA0E515);
    if (value < 150) return const Color(0xFF23CD5E);
    return const Color(0xFF00C2B8);
  }

  static const Map<String, String> _statNames = {
    'hp': 'HP',
    'attack': 'Attack',
    'defense': 'Defense',
    'special-attack': 'Sp. Atk',
    'special-defense': 'Sp. Def',
    'speed': 'Speed',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _barColor(widget.value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _statNames[widget.label] ?? widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF555555),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) => Text(
                '${(widget.value * _animation.value).round()}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (widget.value / widget.maxValue) * _animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.7),
                            color,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
