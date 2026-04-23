import 'dart:math' as math;

import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';
import '../math/linear_algebra.dart';
import '../math/num_utils.dart';

/// Sensor NTC. Pontos: x = T(°C), y = R(Ω).
///
/// Modelo Steinhart–Hart: 1/T(K) = A + B·ln R + C·(ln R)³
/// (3 pares R–T → sistema 3x3 determinado).
class NtcSensor implements SensorModel {
  @override
  String get id => 'ntc';
  @override
  String get displayName => 'NTC (Termistor)';
  @override
  String get unitX => '°C';
  @override
  String get unitY => 'Ω';
  @override
  int get minPoints => 3;
  @override
  int get maxPoints => 3;

  @override
  List<CalibrationPoint> get defaultPoints => const [
        CalibrationPoint(x: 5, y: 25000),
        CalibrationPoint(x: 25, y: 10000),
        CalibrationPoint(x: 45, y: 4000),
      ];

  @override
  (double, double) defaultRange() => (0, 60);

  @override
  CalibrationResult compute(List<CalibrationPoint> points) {
    if (points.length != 3) {
      throw ArgumentError('NTC exige 3 pontos.');
    }
    if (points.any((p) => p.y <= 0)) {
      throw ArgumentError('Resistência deve ser > 0.');
    }
    // Steinhart–Hart
    final m = <List<double>>[];
    final b = <double>[];
    for (final p in points) {
      final lnR = math.log(p.y);
      m.add([1.0, lnR, lnR * lnR * lnR]);
      b.add(1.0 / cToK(p.x));
    }
    final sh = LinearAlgebra.solve(m, b);

    // Beta / R25 a partir dos dois primeiros pontos
    final p1 = points[0], p2 = points[1];
    final t1k = cToK(p1.x), t2k = cToK(p2.x);
    final beta = math.log(p1.y / p2.y) / (1 / t1k - 1 / t2k);
    const t25k = 298.15;
    var sum = 0.0;
    for (final p in points) {
      final tk = cToK(p.x);
      sum += p.y * math.exp(-beta * (1 / tk - 1 / t25k));
    }
    final r25 = sum / points.length;

    return CalibrationResult(
      modelId: id,
      coefficients: {
        'A': sh[0],
        'B': sh[1],
        'C': sh[2],
        'β': beta,
        'R25': r25,
      },
      notes: 'A,B,C em 1/K; β em K; R25 em Ω.',
    );
  }

  @override
  double yFromX(CalibrationResult r, double tC) {
    final a = r.coefficients['A']!;
    final b = r.coefficients['B']!;
    final c = r.coefficients['C']!;
    final y = 1.0 / cToK(tC);
    // Resolve A + B·u + C·u³ = y por Newton (u = ln R)
    final u = LinearAlgebra.newton(
      f: (u) => a + b * u + c * u * u * u - y,
      df: (u) => b + 3 * c * u * u,
      x0: math.log(10000),
    );
    return math.exp(u);
  }

  @override
  double xFromY(CalibrationResult r, double resistance) {
    if (resistance <= 0) throw ArgumentError('R deve ser > 0.');
    final a = r.coefficients['A']!;
    final b = r.coefficients['B']!;
    final c = r.coefficients['C']!;
    final lnR = math.log(resistance);
    final invT = a + b * lnR + c * lnR * lnR * lnR;
    if (invT <= 0) {
      throw StateError('Resultado inválido (1/T ≤ 0).');
    }
    return kToC(1.0 / invT);
  }

  /// Avalia o modelo β: R(T) = R25 · exp(β · (1/T − 1/T25)).
  double _betaR(CalibrationResult r, double tC) {
    final beta = r.coefficients['β']!;
    final r25 = r.coefficients['R25']!;
    const t25k = 298.15;
    final tk = cToK(tC);
    return r25 * math.exp(beta * (1 / tk - 1 / t25k));
  }

  @override
  List<ModelCurve> curves(CalibrationResult r) => [
        ModelCurve(label: 'Steinhart–Hart', evaluate: (x) => yFromX(r, x)),
        ModelCurve(label: 'β / R25', evaluate: (x) => _betaR(r, x)),
      ];
}
