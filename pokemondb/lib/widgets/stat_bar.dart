import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 255,
  });

  Color get _barColor {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _statNames[label] ?? label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value / maxValue,
                minHeight: 14,
                backgroundColor: const Color(0xFFE8E8E8),
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
