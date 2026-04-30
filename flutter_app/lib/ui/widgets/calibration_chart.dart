import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/calibration_point.dart';
import '../../domain/sensor_model.dart';
import '../theme/app_palette.dart';

class CalibrationChart extends StatelessWidget {
  const CalibrationChart({
    super.key,
    required this.sensor,
    required this.result,
    required this.points,
    required this.xMin,
    required this.xMax,
    required this.accentColor,
  });

  final SensorModel sensor;
  final CalibrationResult? result;
  final List<CalibrationPoint> points;
  final double xMin;
  final double xMax;
  final Color accentColor;

  static const List<Color> _curvePalette = [
    Color(0xFF1E40AF), // indigo-800
    Color(0xFFDC2626), // red-600
    Color(0xFF14B8A6), // teal-500
    Color(0xFFD97706), // amber-600
  ];

  @override
  Widget build(BuildContext context) {
    final hi = xMax > xMin ? xMax : xMin + 1;
    final curves = result == null
        ? const <ModelCurve>[]
        : sensor.curves(result!);

    final curveLines = <_CurveData>[];
    for (var i = 0; i < curves.length; i++) {
      final c = curves[i];
      final color = curves.length == 1
          ? accentColor
          : _curvePalette[i % _curvePalette.length];
      const n = 140;
      final dx = (hi - xMin) / (n - 1);
      final spots = <FlSpot>[];
      for (var k = 0; k < n; k++) {
        final t = xMin + k * dx;
        try {
          final y = c.evaluate(t);
          if (y.isFinite) spots.add(FlSpot(t, y));
        } catch (_) {}
      }
      if (spots.isNotEmpty) {
        curveLines.add(_CurveData(label: c.label, color: color, spots: spots));
      }
    }

    final dataDots = points.map((p) => FlSpot(p.x, p.y)).toList();

    final allY = <double>[
      for (final c in curveLines) ...c.spots.map((s) => s.y),
      ...dataDots.map((s) => s.y),
    ];
    double? minY;
    double? maxY;
    if (allY.isNotEmpty) {
      minY = allY.reduce((a, b) => a < b ? a : b);
      maxY = allY.reduce((a, b) => a > b ? a : b);
      final pad = ((maxY - minY).abs()) * 0.08 + 1e-9;
      minY -= pad;
      maxY += pad;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (curveLines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 6,
                      children: [
                        for (final c in curveLines)
                          _LegendChip(color: c.color, label: c.label),
                        if (dataDots.isNotEmpty)
                          const _LegendChip(
                            color: AppPalette.textPrimary,
                            label: 'Pontos',
                            isDot: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sensor.displayName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: xMin,
                maxX: hi,
                minY: minY,
                maxY: maxY,
                backgroundColor: Colors.white,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFEAEEF3), strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Color(0xFFEAEEF3), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    axisNameSize: 36,
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Temperatura (${sensor.unitX})',
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: _bottomLabel,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameSize: 42,
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _yAxisTitle(sensor),
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            color: AppPalette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: _leftLabel,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Color(0xFFCBD5E1)),
                    bottom: BorderSide(color: Color(0xFFCBD5E1)),
                    top: BorderSide(color: Color(0x00000000)),
                    right: BorderSide(color: Color(0x00000000)),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppPalette.textPrimary,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        '${s.x.toStringAsFixed(2)} ${sensor.unitX}\n'
                        '${s.y.toStringAsFixed(3)} ${sensor.unitY}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  for (var i = 0; i < curveLines.length; i++)
                    LineChartBarData(
                      spots: curveLines[i].spots,
                      isCurved: false,
                      color: curveLines[i].color,
                      barWidth: 2.4,
                      dashArray: i == 0 ? null : [6, 4],
                      dotData: const FlDotData(show: false),
                      belowBarData: i == 0 && curveLines.length == 1
                          ? BarAreaData(
                              show: true,
                              color: curveLines[i].color.withValues(
                                alpha: 0.07,
                              ),
                            )
                          : BarAreaData(show: false),
                    ),
                  if (dataDots.isNotEmpty)
                    LineChartBarData(
                      spots: dataDots,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 2.4,
                          strokeColor: AppPalette.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurveData {
  _CurveData({required this.label, required this.color, required this.spots});
  final String label;
  final Color color;
  final List<FlSpot> spots;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    this.isDot = false,
  });
  final Color color;
  final String label;
  final bool isDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDot ? 10 : 18,
          height: isDot ? 10 : 3,
          decoration: BoxDecoration(
            color: isDot ? Colors.white : color,
            border: isDot ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(isDot ? 999 : 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

Widget _leftLabel(double value, TitleMeta meta) {
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Text(
      _fmt(value),
      style: const TextStyle(color: AppPalette.textSecondary, fontSize: 11),
      textAlign: TextAlign.right,
    ),
  );
}

Widget _bottomLabel(double value, TitleMeta meta) {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      _fmt(value),
      style: const TextStyle(color: AppPalette.textSecondary, fontSize: 11),
    ),
  );
}

String _fmt(double v) {
  final a = v.abs();
  if (a >= 10000) return v.toStringAsExponential(1);
  if (a >= 100) return v.toStringAsFixed(0);
  if (a >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

String _yAxisTitle(SensorModel sensor) {
  if (sensor.unitY == 'mV') return 'Tensão (${sensor.unitY})';
  return 'Resistência (${sensor.unitY})';
}
