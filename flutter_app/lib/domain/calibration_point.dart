/// Par genérico (x, y) de calibração.
///
/// Para sensores resistivos (NTC, RTD): x = T(°C), y = R(Ω).
/// Para termopares: x = T(°C), y = E(mV).
class CalibrationPoint {
  const CalibrationPoint({required this.x, required this.y});
  final double x;
  final double y;

  CalibrationPoint copyWith({double? x, double? y}) =>
      CalibrationPoint(x: x ?? this.x, y: y ?? this.y);
}
