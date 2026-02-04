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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: TypeColors.getColor(type),
        borderRadius: BorderRadius.circular(4),
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
