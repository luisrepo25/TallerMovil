import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:flutter_test/flutter_test.dart';

ActaLocal actaNueva() => ActaLocal(
  uuidLocal: 'uuid-1',
  predioId: 10,
  campaniaId: 1,
  fechaInspeccion: DateTime.utc(2026, 10, 9, 15, 30),
);

void main() {
  group('edición de materiales', () {
    test('agregar un material nuevo lo suma a la lista', () {
      final acta = actaNueva().conMaterial(1, 300).conMaterial(2, 150);

      expect(acta.materiales.map((m) => (m.materialId, m.pesoKg)), [
        (1, 300.0),
        (2, 150.0),
      ]);
    });

    test(
      'agregar un material que ya estaba cambia su peso y conserva su lugar (no lo duplica)',
      () {
        final acta = actaNueva()
            .conMaterial(1, 300)
            .conMaterial(2, 150)
            .conMaterial(1, 400);

        expect(acta.materiales, hasLength(2));
        expect(acta.materiales.first.materialId, 1);
        expect(acta.materiales.first.pesoKg, 400);
      },
    );

    test('quitar un material', () {
      final acta = actaNueva()
          .conMaterial(1, 300)
          .conMaterial(2, 150)
          .sinMaterial(1);

      expect(acta.materiales.map((m) => m.materialId), [2]);
    });

    test('editar no modifica el acta original (es inmutable)', () {
      final original = actaNueva();
      original.conMaterial(1, 300);

      expect(original.materiales, isEmpty);
    });
  });

  group('edición de infracciones', () {
    test('agrega, actualiza el detalle sin duplicar, y quita', () {
      var acta = actaNueva().conInfraccion(1, '  Sin carga  ');
      expect(
        acta.infracciones.single.descripcion,
        'Sin carga',
        reason: 'se recorta el espacio',
      );

      acta = acta
          .conInfraccion(1, 'Extintor del pasillo vencido')
          .conInfraccion(2, '');
      expect(acta.infracciones, hasLength(2));
      expect(
        acta.infracciones.first.descripcion,
        'Extintor del pasillo vencido',
      );

      acta = acta.sinInfraccion(1);
      expect(acta.infracciones.map((i) => i.tipoInfraccionId), [2]);
    });
  });
}
