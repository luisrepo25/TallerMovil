import 'package:app_movil_uubr/core/format/fechas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ahora = DateTime(2026, 10, 9, 12);

  test('formato corto en español', () {
    expect(Fechas.corta(DateTime(2026, 10, 9)), '09 oct 2026');
    expect(
      Fechas.rango(DateTime(2026, 1, 1), DateTime(2026, 12, 31)),
      '01 ene 2026 – 31 dic 2026',
    );
  });

  test('tiempo transcurrido en lenguaje natural', () {
    String hace(Duration d) =>
        Fechas.haceCuanto(ahora.subtract(d), ahora: ahora);

    expect(hace(const Duration(seconds: 20)), 'hace un momento');
    expect(hace(const Duration(minutes: 5)), 'hace 5 min');
    expect(hace(const Duration(hours: 3)), 'hace 3 h');
    expect(hace(const Duration(days: 1)), 'hace 1 día');
    expect(hace(const Duration(days: 4)), 'hace 4 días');
  });
}
