import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';
import '../math/linear_algebra.dart';

/// Sensor RTD (ex.: Pt100). Pontos: x = T(°C), y = R(Ω).
///
/// Regras adotadas neste módulo:
/// - Para T >= 0 °C: R(T) = R0 · (1 + A·T + B·T²)
/// - Para T < 0 °C:  R(T) = R0 · (1 + A·T + B·T² + C·(T-100)·T³)
///
/// Ajuste dos coeficientes:
/// - Pontos somente negativos -> ajusta A, B e C.
/// - Pontos mistos ou somente não negativos -> ajusta apenas A e B.
///   Nesses casos, para T < 0 °C usa-se C fixo padrão IEC.
class RtdSensor extends SensorModel {
  RtdSensor({this.r0 = 100.0, this.alpha = 0.0038459});

  static const double _iecC = -4.183e-12;

  final double r0;
  final double alpha;

  @override
  String get id => 'rtd';
  @override
  String get displayName => 'RTD (Pt100/Pt1000)';
  @override
  String get unitX => '°C';
  @override
  String get unitY => 'Ω';
  @override
  int get minPoints => 3;
  @override
  int get maxPoints => 8;

  @override
  List<CalibrationPoint> get defaultPoints => const [
    CalibrationPoint(x: -200, y: 18.52008),
    CalibrationPoint(x: -100, y: 60.25584),
    CalibrationPoint(x: 0, y: 100.0),
    CalibrationPoint(x: 100, y: 138.5055),
    CalibrationPoint(x: 250, y: 194.098125),
    CalibrationPoint(x: 400, y: 247.092),
    CalibrationPoint(x: 650, y: 329.640125),
    CalibrationPoint(x: 850, y: 390.481125),
  ];

  @override
  (double, double) defaultRange() => (-200, 850);

  @override
  CalibrationResult compute(List<CalibrationPoint> points) {
    if (points.length < 3) {
      throw ArgumentError('RTD exige no mínimo 3 pontos.');
    }
    if (points.any((p) => p.y <= 0)) {
      throw ArgumentError('Resistência deve ser > 0.');
    }

    final hasNegative = points.any((p) => p.x < 0);
    final hasNonNegative = points.any((p) => p.x >= 0);
    final negativeOnly = hasNegative && !hasNonNegative;

    final x = <List<double>>[];
    final y = <double>[];
    for (final p in points) {
      final t = p.x;
      final target = p.y / r0 - 1.0;
      y.add(target);
      x.add(negativeOnly ? [t, t * t, (t - 100.0) * t * t * t] : [t, t * t]);
    }

    final coeffs = LinearAlgebra.leastSquares(x, y);
    final resultCoefficients = <String, double>{
      'R0': r0,
      'α': alpha,
      'A': coeffs[0],
      'B': coeffs[1],
    };
    if (negativeOnly) {
      resultCoefficients['C'] = coeffs[2];
    }

    return CalibrationResult(
      modelId: id,
      coefficients: resultCoefficients,
      notes: _buildNotes(negativeOnly: negativeOnly, hasNegative: hasNegative),
    );
  }

  String _buildNotes({required bool negativeOnly, required bool hasNegative}) {
    if (negativeOnly) {
      return 'Somente temperaturas negativas: o programa ajustou A, B e C. '
          'Callendar–Van Dusen: T ≥ 0 °C -> R(T) = R0·(1 + A·T + B·T²); '
          'T < 0 °C -> R(T) = R0·(1 + A·T + B·T² + C·(T−100)·T³). '
          'Linear/α: R(T) = R0·(1 + α·T).';
    }
    if (hasNegative) {
      return 'Temperaturas mistas: o programa ajustou apenas A e B. '
          'Para T < 0 °C, a curva Callendar–Van Dusen usa C fixo IEC = -4.183×10^-12. '
          'Callendar–Van Dusen: T ≥ 0 °C -> R(T) = R0·(1 + A·T + B·T²); '
          'T < 0 °C -> R(T) = R0·(1 + A·T + B·T² + C·(T−100)·T³). '
          'Linear/α: R(T) = R0·(1 + α·T).';
    }
    return 'Somente temperaturas em T ≥ 0 °C: o programa ajustou A e B. '
        'Callendar–Van Dusen: R(T) = R0·(1 + A·T + B·T²). '
        'Linear/α: R(T) = R0·(1 + α·T).';
  }

  @override
  double yFromX(CalibrationResult result, double tC) {
    return _rtdR(result, tC);
  }

  @override
  double xFromY(CalibrationResult result, double resistance) {
    final target = resistance;
    final guess = (target / r0 - 1.0) / alpha;

    return LinearAlgebra.newton(
      f: (t) => _rtdR(result, t) - target,
      df: (t) => _rtdDerivative(result, t),
      x0: guess,
    );
  }

  double _rtdR(CalibrationResult result, double tC) {
    final r0 = result.coefficients['R0']!;
    final a = result.coefficients['A']!;
    final b = result.coefficients['B']!;
    if (tC >= 0) {
      return r0 * (1 + a * tC + b * tC * tC);
    }

    final c = result.coefficients['C'] ?? _iecC;
    final extra = c * (tC - 100.0) * tC * tC * tC;
    return r0 * (1 + a * tC + b * tC * tC + extra);
  }

  double _rtdDerivative(CalibrationResult result, double tC) {
    final r0 = result.coefficients['R0']!;
    final a = result.coefficients['A']!;
    final b = result.coefficients['B']!;
    if (tC >= 0) {
      return r0 * (a + 2 * b * tC);
    }

    final c = result.coefficients['C'] ?? _iecC;
    final dExtra = c * (4 * tC * tC * tC - 300 * tC * tC);
    return r0 * (a + 2 * b * tC + dExtra);
  }

  double _alphaR(CalibrationResult result, double tC) {
    final r0 = result.coefficients['R0']!;
    final alpha = result.coefficients['α']!;
    return r0 * (1 + alpha * tC);
  }

  @override
  List<ModelCurve> curves(CalibrationResult result) => [
    ModelCurve(
      label: 'Callendar–Van Dusen',
      evaluate: (x) => yFromX(result, x),
    ),
    ModelCurve(label: 'Linear / α', evaluate: (x) => _alphaR(result, x)),
  ];
}
