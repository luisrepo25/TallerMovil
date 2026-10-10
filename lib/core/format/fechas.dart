/// Formato de fechas en español, sin depender de `intl`.
class Fechas {
  Fechas._();

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// `2026-10-09` -> `09 oct 2026`
  static String corta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')} ${_meses[f.month - 1]} ${f.year}';

  static String rango(DateTime inicio, DateTime fin) =>
      '${corta(inicio)} – ${corta(fin)}';

  /// Tiempo transcurrido en lenguaje natural: "hace 5 min", "hace 2 h", "hace 3 días".
  static String haceCuanto(DateTime f, {DateTime? ahora}) {
    final diferencia = (ahora ?? DateTime.now()).difference(f);
    if (diferencia.inMinutes < 1) return 'hace un momento';
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
    final dias = diferencia.inDays;
    return 'hace $dias ${dias == 1 ? 'día' : 'días'}';
  }
}
