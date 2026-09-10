import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  /// Inter llega por <link> en web/index.html. Si no carga, el fallback
  /// resuelve a la tipografia de interfaz del sistema.
  static const String fontFamily = 'Inter';

  static const List<String> fontFamilyFallback = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 38 / 30,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 34 / 26,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 30 / 22,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 26 / 18,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 22 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 18 / 12,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 22 / 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 18 / 13,
    color: AppColors.textPrimary,
  );
}

extension CareTextStyleX on TextStyle {
  /// Cifras de ancho fijo: horas de agenda, contadores y metricas no bailan
  /// cuando cambia el valor.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
