import 'package:flutter/material.dart';

/// Paleta da aplicação — inspirada em apps acadêmicos LASEC/UFU.
/// Tema claro, contraste alto, acentos em índigo/teal.
class AppPalette {
  AppPalette._();

  // Brand
  static const Color brandPrimary = Color(0xFF1E40AF); // indigo-800
  static const Color brandSecondary = Color(0xFF0EA5E9); // sky-500
  static const Color brandAccent = Color(0xFF14B8A6); // teal-500

  // Neutros
  static const Color background = Color(0xFFF6F8FB); // off-white frio
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF2F7);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE5E7EB);

  // Texto
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF94A3B8); // slate-400

  // Estado
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  // Cores por categoria de sensor
  static const Color ntcColor = Color(0xFF2563EB); // blue-600
  static const Color rtdColor = Color(0xFF0891B2); // cyan-600
  static const Color tcColor = Color(0xFFE11D48); // rose-600

  // Gradientes
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
  );

  static Color forSensorId(String id) {
    if (id == 'ntc') return ntcColor;
    if (id == 'rtd') return rtdColor;
    return tcColor;
  }
}
