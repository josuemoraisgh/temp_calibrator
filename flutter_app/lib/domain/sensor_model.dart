import 'calibration_point.dart';

/// Resultado de uma calibração: coeficientes nomeados + metadados.
class CalibrationResult {
  const CalibrationResult({
    required this.coefficients,
    required this.modelId,
    this.notes = '',
  });

  /// Mapa nome -> valor (ex.: {'A': 1.2e-3, 'B': 2.4e-4, 'C': 9.1e-8}).
  final Map<String, double> coefficients;
  final String modelId;
  final String notes;

  bool get isValid => coefficients.values.every((v) => v.isFinite);
}

/// Contrato SOLID (ISP + DIP) para qualquer sensor calibrável.
///
/// Cada sensor implementa:
///   * compute      -> ajusta coeficientes a partir dos pontos.
///   * yFromX / xFromY -> conversão direta/inversa.
///   * minPoints    -> mínimo de pontos exigidos.
///   * unitX/unitY  -> rótulos para a UI (sem acoplamento com Flutter).
abstract class SensorModel {
  String get id;
  String get displayName;
  String get unitX; // ex.: '°C'
  String get unitY; // ex.: 'Ω' ou 'mV'
  int get minPoints;
  int get maxPoints;

  /// Pontos default sugeridos para inicializar a UI.
  List<CalibrationPoint> get defaultPoints;

  CalibrationResult compute(List<CalibrationPoint> points);

  /// Dado X (temperatura), retorna Y (R ou mV).
  double yFromX(CalibrationResult result, double x);

  /// Dado Y, retorna X.
  double xFromY(CalibrationResult result, double y);

  /// Faixa default para o gráfico (em X).
  (double, double) defaultRange();

  /// Curvas a desenhar no gráfico. Default: uma curva "Modelo" usando yFromX.
  /// Sensores com múltiplos modelos (ex.: NTC com S–H e β) sobrescrevem.
  List<ModelCurve> curves(CalibrationResult result) => [
        ModelCurve(label: 'Modelo', evaluate: (x) => yFromX(result, x)),
      ];
}

/// Uma curva nomeada (label) e sua função de avaliação y = f(x).
class ModelCurve {
  const ModelCurve({required this.label, required this.evaluate});
  final String label;
  final double Function(double x) evaluate;
}
