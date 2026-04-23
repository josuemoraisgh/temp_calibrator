import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';
import '../math/num_utils.dart';
import 'theme/app_palette.dart';
import 'widgets/calibration_chart.dart';
import 'widgets/section_card.dart';

class SensorCalibrationPage extends StatefulWidget {
  const SensorCalibrationPage({super.key, required this.sensor});
  final SensorModel sensor;

  @override
  State<SensorCalibrationPage> createState() => _SensorCalibrationPageState();
}

class _SensorCalibrationPageState extends State<SensorCalibrationPage> {
  late List<CalibrationPoint> _points;
  late List<TextEditingController> _xCtrls;
  late List<TextEditingController> _yCtrls;

  CalibrationResult? _result;
  String? _error;

  final _calcXCtrl = TextEditingController();
  final _calcYCtrl = TextEditingController();
  String _calcYOut = '—';
  String _calcXOut = '—';

  late TextEditingController _xMinCtrl;
  late TextEditingController _xMaxCtrl;

  Color get _accent => AppPalette.forSensorId(widget.sensor.id);

  @override
  void initState() {
    super.initState();
    _resetPoints();
    final r = widget.sensor.defaultRange();
    _xMinCtrl = TextEditingController(text: _fmt(r.$1));
    _xMaxCtrl = TextEditingController(text: _fmt(r.$2));
    _autoCompute();
  }

  void _resetPoints() {
    _points = List.of(widget.sensor.defaultPoints);
    _xCtrls =
        _points.map((p) => TextEditingController(text: _fmt(p.x))).toList();
    _yCtrls =
        _points.map((p) => TextEditingController(text: _fmt(p.y))).toList();
    _calcXCtrl.text = _fmt(_points.first.x);
    _calcYCtrl.text = _fmt(_points.first.y);
  }

  String _fmt(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toStringAsFixed(0);
    }
    return v.toString();
  }

  String _fmtCoeff(double v) {
    final a = v.abs();
    if (a == 0) return '0';
    if (a < 1e-3 || a >= 1e6) return v.toStringAsExponential(6);
    return v.toStringAsPrecision(8);
  }

  @override
  void dispose() {
    for (final c in _xCtrls) {
      c.dispose();
    }
    for (final c in _yCtrls) {
      c.dispose();
    }
    _calcXCtrl.dispose();
    _calcYCtrl.dispose();
    _xMinCtrl.dispose();
    _xMaxCtrl.dispose();
    super.dispose();
  }

  List<CalibrationPoint> _readPoints() {
    return List.generate(_xCtrls.length, (i) {
      return CalibrationPoint(
        x: normFloat(_xCtrls[i].text),
        y: normFloat(_yCtrls[i].text),
      );
    });
  }

  void _autoCompute() {
    try {
      final pts = _readPoints();
      final r = widget.sensor.compute(pts);
      setState(() {
        _points = pts;
        _result = r;
        _error = null;
      });
    } catch (_) {/* silencioso */}
  }

  void _onCompute() {
    try {
      final pts = _readPoints();
      final r = widget.sensor.compute(pts);
      setState(() {
        _points = pts;
        _result = r;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _onReset() {
    setState(() {
      for (final c in _xCtrls) {
        c.dispose();
      }
      for (final c in _yCtrls) {
        c.dispose();
      }
      _resetPoints();
      _result = null;
      _error = null;
      _calcYOut = '—';
      _calcXOut = '—';
      final r = widget.sensor.defaultRange();
      _xMinCtrl.text = _fmt(r.$1);
      _xMaxCtrl.text = _fmt(r.$2);
    });
    _autoCompute();
  }

  void _addPoint() {
    if (_xCtrls.length >= widget.sensor.maxPoints) return;
    setState(() {
      _xCtrls.add(TextEditingController(text: '0'));
      _yCtrls.add(TextEditingController(text: '0'));
    });
  }

  void _removePoint(int i) {
    if (_xCtrls.length <= widget.sensor.minPoints) return;
    setState(() {
      _xCtrls.removeAt(i).dispose();
      _yCtrls.removeAt(i).dispose();
    });
  }

  void _calcYFromX() {
    if (_result == null) {
      _onCompute();
      if (_result == null) return;
    }
    try {
      final v = normFloat(_calcXCtrl.text);
      final y = widget.sensor.yFromX(_result!, v);
      setState(() => _calcYOut =
          '${y.toStringAsFixed(widget.sensor.unitY == 'mV' ? 4 : 3)} ${widget.sensor.unitY}');
    } catch (e) {
      setState(() => _calcYOut = 'erro');
    }
  }

  void _calcXFromY() {
    if (_result == null) {
      _onCompute();
      if (_result == null) return;
    }
    try {
      final v = normFloat(_calcYCtrl.text);
      final x = widget.sensor.xFromY(_result!, v);
      setState(
          () => _calcXOut = '${x.toStringAsFixed(3)} ${widget.sensor.unitX}');
    } catch (e) {
      setState(() => _calcXOut = 'erro');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sensor;
    final isWide = MediaQuery.sizeOf(context).width > 1100;

    final inputs = SectionCard(
      title: 'PONTOS DE CALIBRAÇÃO',
      icon: Icons.scatter_plot,
      accent: _accent,
      trailing: s.maxPoints > s.minPoints
          ? IconButton(
              tooltip: 'Adicionar ponto',
              onPressed: _xCtrls.length < s.maxPoints ? _addPoint : null,
              icon: const Icon(Icons.add_circle_outline),
              color: _accent,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _xCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumField(
                      controller: _xCtrls[i],
                      label: 'T (${s.unitX})',
                      onSubmitted: (_) => _onCompute(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumField(
                      controller: _yCtrls[i],
                      label: s.unitY == 'mV' ? 'E (mV)' : 'R (${s.unitY})',
                      onSubmitted: (_) => _onCompute(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover',
                    onPressed: _xCtrls.length > s.minPoints
                        ? () => _removePoint(i)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _onCompute,
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Calcular'),
                style: FilledButton.styleFrom(backgroundColor: _accent),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _onReset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPalette.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppPalette.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 18, color: AppPalette.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: AppPalette.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final coeffsCard = SectionCard(
      title: 'COEFICIENTES',
      icon: Icons.functions,
      accent: _accent,
      child: _result == null
          ? const Text(
              'Preencha os pontos e clique em Calcular.',
              style: TextStyle(color: AppPalette.textSecondary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in _result!.coefficients.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppPalette.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _fmtCoeff(entry.value),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_result!.notes.isNotEmpty) ...[
                  const Divider(height: 18),
                  Text(
                    _result!.notes,
                    style: const TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
    );

    Widget calcRow({
      required String hint,
      required TextEditingController ctrl,
      required VoidCallback onCompute,
      required String output,
    }) {
      return Row(
        children: [
          Expanded(
            child: _NumField(
              controller: ctrl,
              label: hint,
              onSubmitted: (_) => onCompute(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onCompute,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              minimumSize: const Size(48, 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Icon(Icons.arrow_forward_rounded, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 46,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppPalette.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.border),
              ),
              child: SelectableText(
                output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                  color: AppPalette.textPrimary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final calcCard = SectionCard(
      title: 'CALCULADORA',
      icon: Icons.swap_horiz_rounded,
      accent: _accent,
      child: Column(
        children: [
          calcRow(
            hint: '${s.unitX} → ${s.unitY}',
            ctrl: _calcXCtrl,
            onCompute: _calcYFromX,
            output: _calcYOut,
          ),
          const SizedBox(height: 10),
          calcRow(
            hint: '${s.unitY} → ${s.unitX}',
            ctrl: _calcYCtrl,
            onCompute: _calcXFromY,
            output: _calcXOut,
          ),
        ],
      ),
    );

    final rangeCard = SectionCard(
      title: 'FAIXA DO GRÁFICO (${s.unitX})',
      icon: Icons.straighten,
      accent: _accent,
      child: Row(
        children: [
          Expanded(
            child: _NumField(
              controller: _xMinCtrl,
              label: 'mínimo',
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumField(
              controller: _xMaxCtrl,
              label: 'máximo',
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => setState(() {}),
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );

    double xMin, xMax;
    try {
      xMin = normFloat(_xMinCtrl.text);
      xMax = normFloat(_xMaxCtrl.text);
    } catch (_) {
      final r = s.defaultRange();
      xMin = r.$1;
      xMax = r.$2;
    }

    final chart = SectionCard(
      title: '${s.unitY} × ${s.unitX}',
      icon: Icons.show_chart,
      accent: _accent,
      child: SizedBox(
        height: 420,
        child: CalibrationChart(
          sensor: s,
          result: _result,
          points: _points,
          xMin: xMin,
          xMax: xMax,
          accentColor: _accent,
        ),
      ),
    );

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        inputs,
        const SizedBox(height: 14),
        coeffsCard,
        const SizedBox(height: 14),
        calcCard,
        const SizedBox(height: 14),
        rangeCard,
      ],
    );

    final body = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 480, child: left),
              const SizedBox(width: 18),
              Expanded(child: chart),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 14), chart],
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: body,
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9eE\.\,\-\+]')),
      ],
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
