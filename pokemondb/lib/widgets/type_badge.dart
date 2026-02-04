import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/type_colors.dart';

class TypeBadge extends StatefulWidget {
  final String type;
  final double fontSize;
  final bool large;
  final bool navigable;

  const TypeBadge({
    super.key,
    required this.type,
    this.fontSize = 12,
    this.large = false,
    this.navigable = false,
  });

  @override
  State<TypeBadge> createState() => _TypeBadgeState();
}

class _TypeBadgeState extends State<TypeBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = TypeColors.getColor(widget.type);
    final textColor = TypeColors.getTextColor(widget.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badge = MouseRegion(
      onEnter: widget.navigable ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.navigable ? (_) => setState(() => _hovered = false) : null,
      cursor: widget.navigable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.navigable
            ? () => context.go('/?type=${widget.type}')
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.large ? 18 : 12,
            vertical: widget.large ? 7 : 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                Color.lerp(color, isDark ? Colors.white : Colors.black, 0.15)!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _hovered
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                : [BoxShadow(color: color.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.type[0].toUpperCase() + widget.type.substring(1),
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              if (widget.navigable && _hovered) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: widget.fontSize, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.navigable) {
      return Tooltip(
        message: 'View all ${widget.type[0].toUpperCase()}${widget.type.substring(1)} Pokemon',
        child: badge,
      );
    }
    return badge;
  }
}
