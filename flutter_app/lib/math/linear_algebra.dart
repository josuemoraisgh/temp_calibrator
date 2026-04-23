import 'dart:math' as math;

/// Álgebra linear mínima e auto-contida (sem dependências externas).
/// Usada para resolver sistemas determinados (NTC 3 pts) e LSQ (RTD/TC).
class LinearAlgebra {
  /// Resolve A·x = b por eliminação de Gauss com pivotamento parcial.
  /// A é quadrada n x n. Retorna x de tamanho n.
  static List<double> solve(List<List<double>> a, List<double> b) {
    final n = a.length;
    if (n == 0 || a[0].length != n || b.length != n) {
      throw ArgumentError('Dimensões inválidas para solve.');
    }
    // cópias mutáveis
    final m = List.generate(n, (i) => List<double>.from(a[i]));
    final v = List<double>.from(b);

    for (var k = 0; k < n; k++) {
      // pivô parcial
      var maxRow = k;
      var maxVal = m[k][k].abs();
      for (var i = k + 1; i < n; i++) {
        if (m[i][k].abs() > maxVal) {
          maxVal = m[i][k].abs();
          maxRow = i;
        }
      }
      if (maxVal < 1e-15) {
        throw StateError('Matriz singular (pivô ~ 0).');
      }
      if (maxRow != k) {
        final tmp = m[k];
        m[k] = m[maxRow];
        m[maxRow] = tmp;
        final tb = v[k];
        v[k] = v[maxRow];
        v[maxRow] = tb;
      }
      // eliminação
      for (var i = k + 1; i < n; i++) {
        final f = m[i][k] / m[k][k];
        for (var j = k; j < n; j++) {
          m[i][j] -= f * m[k][j];
        }
        v[i] -= f * v[k];
      }
    }
    // back-substitution
    final x = List<double>.filled(n, 0);
    for (var i = n - 1; i >= 0; i--) {
      var s = v[i];
      for (var j = i + 1; j < n; j++) {
        s -= m[i][j] * x[j];
      }
      x[i] = s / m[i][i];
    }
    return x;
  }

  /// Mínimos quadrados: minimiza ||X·c - y||² resolvendo
  /// (Xᵀ X) c = Xᵀ y.
  static List<double> leastSquares(List<List<double>> x, List<double> y) {
    final m = x.length;
    if (m == 0) throw ArgumentError('Sem amostras.');
    final n = x[0].length;
    if (y.length != m) throw ArgumentError('Dimensões inconsistentes.');

    final xtX = List.generate(n, (_) => List<double>.filled(n, 0));
    final xtY = List<double>.filled(n, 0);
    for (var i = 0; i < m; i++) {
      for (var j = 0; j < n; j++) {
        xtY[j] += x[i][j] * y[i];
        for (var k = 0; k < n; k++) {
          xtX[j][k] += x[i][j] * x[i][k];
        }
      }
    }
    return solve(xtX, xtY);
  }

  /// Avalia polinômio c0 + c1·x + c2·x² + ... + cn·xⁿ.
  static double polyEval(List<double> coeffs, double x) {
    var s = 0.0;
    var p = 1.0;
    for (final c in coeffs) {
      s += c * p;
      p *= x;
    }
    return s;
  }

  /// Derivada do polinômio acima: c1 + 2 c2 x + 3 c3 x² + ...
  static double polyDerivEval(List<double> coeffs, double x) {
    var s = 0.0;
    var p = 1.0;
    for (var i = 1; i < coeffs.length; i++) {
      s += i * coeffs[i] * p;
      p *= x;
    }
    return s;
  }

  /// Newton-Raphson para achar raiz de f(x)=0 dado f e f'.
  static double newton({
    required double Function(double) f,
    required double Function(double) df,
    double x0 = 1.0,
    int maxIter = 80,
    double tol = 1e-9,
  }) {
    var x = x0;
    for (var i = 0; i < maxIter; i++) {
      final fx = f(x);
      final dfx = df(x);
      final step = dfx.abs() < 1e-18 ? fx * 1e-6 : fx / dfx;
      final xn = x - step;
      if ((xn - x).abs() < tol * math.max(1.0, xn.abs())) {
        return xn;
      }
      x = xn;
    }
    return x;
  }
}
