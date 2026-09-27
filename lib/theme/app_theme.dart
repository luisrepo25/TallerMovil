import 'package:flutter/material.dart';

/// Paleta institucional del proyecto: Azul Marino / Gris Tecnico como base
/// sobria, con Rojo de Seguridad reservado para acciones y alertas. Los
/// colores de riesgo (Bajo/Medio/Critico) son semanticos del dominio y se
/// mantienen fijos en ambos clientes (web y movil).
class AppColors {
  AppColors._();

  static const Color azulMarino = Color(0xFF14213D);
  static const Color azulMarinoSuave = Color(0xFF1F3357);
  static const Color grisTecnico = Color(0xFF5C6773);
  static const Color grisClaro = Color(0xFFF4F5F7);
  static const Color rojoSeguridad = Color(0xFFD7263D);

  static const Color riesgoBajo = Color(0xFF2E7D32);
  static const Color riesgoMedio = Color(0xFFF9A825);
  static const Color riesgoCritico = rojoSeguridad;

  static Color riesgoColor(String cluster) {
    switch (cluster) {
      case 'Bajo':
        return riesgoBajo;
      case 'Medio':
        return riesgoMedio;
      case 'Critico':
        return riesgoCritico;
      default:
        return grisTecnico;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.azulMarino,
      brightness: Brightness.light,
      primary: AppColors.azulMarino,
      secondary: AppColors.grisTecnico,
      error: AppColors.rojoSeguridad,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.grisClaro,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azulMarino,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grisTecnico.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grisTecnico.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.azulMarino, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rojoSeguridad, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rojoSeguridad, width: 1.6),
        ),
        labelStyle: TextStyle(color: AppColors.grisTecnico.withValues(alpha: 0.9)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.azulMarino,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ).copyWith(elevation: const WidgetStatePropertyAll(0)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.grisTecnico.withValues(alpha: 0.12)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.azulMarino),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.azulMarino),
      ),
    );
  }
}
