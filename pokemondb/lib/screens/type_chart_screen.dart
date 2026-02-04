import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../utils/type_colors.dart';

class TypeChartScreen extends StatelessWidget {
  const TypeChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type Chart',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The table below shows the effectiveness of each type. '
                  'Rows are the attacking type, columns are the defending type. '
                  '2× = super effective, ½× = not very effective, 0× = no effect.',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildLegend(),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildChart(),
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

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem(const Color(0xFF5DAE5B), '2×', 'Super effective'),
        _legendItem(const Color(0xFFFF6961), '½×', 'Not very effective'),
        _legendItem(const Color(0xFF333333), '0×', 'No effect'),
        _legendItem(const Color(0xFFF0F0F0), '1×', 'Normal'),
      ],
    );
  }

  Widget _legendItem(Color color, String symbol, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            symbol,
            style: TextStyle(
              color: color == const Color(0xFFF0F0F0) ? Colors.grey : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }

  Widget _buildChart() {
    const types = TypeChart.types;
    const eff = TypeChart.effectiveness;
    const cellSize = 38.0;

    return DataTable(
      headingRowHeight: cellSize,
      dataRowMinHeight: cellSize,
      dataRowMaxHeight: cellSize,
      horizontalMargin: 4,
      columnSpacing: 0,
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F8F8)),
      columns: [
        const DataColumn(
          label: SizedBox(
            width: 70,
            child: Text('ATK ↓ / DEF →', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ),
        ...types.map((t) => DataColumn(
              label: SizedBox(
                width: cellSize,
                child: Center(
                  child: _TypeLabel(type: t),
                ),
              ),
            )),
      ],
      rows: List.generate(types.length, (row) {
        return DataRow(cells: [
          DataCell(SizedBox(
            width: 70,
            child: _TypeLabel(type: types[row]),
          )),
          ...List.generate(types.length, (col) {
            final val = eff[row][col];
            return DataCell(Center(child: _EffCell(value: val)));
          }),
        ]);
      }),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  final String type;

  const _TypeLabel({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: TypeColors.getColor(type),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        type.substring(0, 3).toUpperCase(),
        style: TextStyle(
          color: TypeColors.getTextColor(type),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EffCell extends StatelessWidget {
  final double value;

  const _EffCell({required this.value});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    if (value == 0) {
      bg = const Color(0xFF333333);
      fg = Colors.white;
      text = '0';
    } else if (value == 0.5) {
      bg = const Color(0xFFFF6961);
      fg = Colors.white;
      text = '½';
    } else if (value == 2) {
      bg = const Color(0xFF5DAE5B);
      fg = Colors.white;
      text = '2';
    } else {
      bg = Colors.transparent;
      fg = Colors.transparent;
      text = '';
    }

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
