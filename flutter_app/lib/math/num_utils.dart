/// Converte strings com vírgula/ponto decimal e separadores de milhar.
double normFloat(String s) {
  final t = s.trim();
  if (t.isEmpty) {
    throw const FormatException('Número vazio.');
  }
  String cleaned;
  if (t.contains(',') && t.contains('.')) {
    cleaned = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (t.contains(',')) {
    cleaned = t.replaceAll(',', '.');
  } else {
    cleaned = t;
  }
  final v = double.tryParse(cleaned);
  if (v == null) {
    throw FormatException('Número inválido: "$s"');
  }
  return v;
}

const double kZeroC = 273.15;
double cToK(double c) => c + kZeroC;
double kToC(double k) => k - kZeroC;
