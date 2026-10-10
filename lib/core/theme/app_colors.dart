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
