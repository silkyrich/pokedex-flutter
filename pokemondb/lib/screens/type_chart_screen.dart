import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/type_colors.dart';

class TypeChartScreen extends StatelessWidget {
  const TypeChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type Chart',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The table below shows the effectiveness of each type. '
                  'Rows are the attacking type, columns are the defending type.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLegend(theme),
                const SizedBox(height: 8),
                Text(
                  'Tap any type label to filter Pokemon. Tap effectiveness cells to explore that matchup.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildChart(context, theme),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem(const Color(0xFF22C55E), '2x', 'Super effective', isDark),
        _legendItem(const Color(0xFFEF4444), '1/2x', 'Not very effective', isDark),
        _legendItem(const Color(0xFF333333), '0x', 'No effect', isDark),
        _legendItem(isDark ? const Color(0xFF2A2A35) : const Color(0xFFF0F0F0), '1x', 'Normal', isDark),
      ],
    );
  }

  Widget _legendItem(Color color, String symbol, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            symbol,
            style: TextStyle(
              color: color == const Color(0xFFF0F0F0) || (isDark && color == const Color(0xFF2A2A35))
                  ? Colors.grey
                  : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : const Color(0xFF666666))),
      ],
    );
  }

  Widget _buildChart(BuildContext context, ThemeData theme) {
    const types = TypeChart.types;
    const eff = TypeChart.effectiveness;
    const cellSize = 40.0;
    final isDark = theme.brightness == Brightness.dark;

    return DataTable(
      headingRowHeight: cellSize,
      dataRowMinHeight: cellSize,
      dataRowMaxHeight: cellSize,
      horizontalMargin: 6,
      columnSpacing: 2,
      headingRowColor: WidgetStateProperty.all(
        isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF8F8F8),
      ),
      columns: [
        DataColumn(
          label: SizedBox(
            width: 76,
            child: Text(
              'ATK / DEF',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ),
        ...types.map((t) => DataColumn(
              label: SizedBox(
                width: cellSize,
                child: Center(
                  child: _TypeLabel(type: t, onTap: () => context.go('/?type=$t')),
                ),
              ),
            )),
      ],
      rows: List.generate(types.length, (row) {
        return DataRow(cells: [
          DataCell(SizedBox(
            width: 76,
            child: _TypeLabel(type: types[row], onTap: () => context.go('/?type=${types[row]}')),
          )),
          ...List.generate(types.length, (col) {
            final val = eff[row][col];
            return DataCell(Center(child: _EffCell(
              value: val,
              onTap: val != 1.0 ? () => context.go('/types/${types[row]}/vs/${types[col]}') : null,
            )));
          }),
        ]);
      }),
    );
  }
}

class _TypeLabel extends StatefulWidget {
  final String type;
  final VoidCallback onTap;

  const _TypeLabel({required this.type, required this.onTap});

  @override
  State<_TypeLabel> createState() => _TypeLabelState();
}

class _TypeLabelState extends State<_TypeLabel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: 'View ${widget.type[0].toUpperCase()}${widget.type.substring(1)} Pokemon',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TypeColors.getColor(widget.type),
                  Color.lerp(TypeColors.getColor(widget.type), Colors.black, 0.15)!,
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: _hovered
                  ? [BoxShadow(color: TypeColors.getColor(widget.type).withOpacity(0.4), blurRadius: 6)]
                  : null,
            ),
            child: Text(
              widget.type.substring(0, 3).toUpperCase(),
              style: TextStyle(
                color: TypeColors.getTextColor(widget.type),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EffCell extends StatefulWidget {
  final double value;
  final VoidCallback? onTap;

  const _EffCell({required this.value, this.onTap});

  @override
  State<_EffCell> createState() => _EffCellState();
}

class _EffCellState extends State<_EffCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    String text;

    if (widget.value == 0) {
      bg = isDark ? const Color(0xFF333340) : const Color(0xFF333333);
      fg = Colors.white;
      text = '0';
    } else if (widget.value == 0.5) {
      bg = isDark ? const Color(0xFF7F2520) : const Color(0xFFEF4444);
      fg = Colors.white;
      text = '1/2';
    } else if (widget.value == 2) {
      bg = isDark ? const Color(0xFF166534) : const Color(0xFF22C55E);
      fg = Colors.white;
      text = '2';
    } else {
      bg = Colors.transparent;
      fg = Colors.transparent;
      text = '';
    }

    final cell = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: _hovered && widget.onTap != null
            ? [BoxShadow(color: bg.withOpacity(0.5), blurRadius: 6)]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Tooltip(
            message: 'View matchup details',
            child: cell,
          ),
        ),
      );
    }
    return cell;
  }
}
