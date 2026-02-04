import 'package:flutter/material.dart';
import '../utils/type_colors.dart';

class TypeBadge extends StatelessWidget {
  final String type;
  final double fontSize;
  final bool large;

  const TypeBadge({
    super.key,
    required this.type,
    this.fontSize = 12,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TypeColors.getColor(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 18 : 12,
        vertical: large ? 7 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            Color.lerp(color, Colors.white, 0.15)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(
          color: TypeColors.getTextColor(type),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
