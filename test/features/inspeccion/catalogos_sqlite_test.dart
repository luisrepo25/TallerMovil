import 'package:app_movil_uubr/core/database/app_database.dart';
import 'package:app_movil_uubr/features/inspeccion/data/catalogos_local_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/datos_descarga.dart';

void main() {
  late AppDatabase base;

  setUp(() => base = baseEnMemoria());
  tearDown(() => base.cerrar());

  test('los catálogos descargados se leen igual que se guardaron', () async {
    final servicio = crearDescarga(
      base,
      servidorDescarga(campanias: [], predios: []),
    );

    await servicio.descargar();
    final catalogos = await CatalogosLocalSource(base).leer();

    expect(catalogos.estadosExtintor.map((e) => e.nombre), [
      'Vigente',
      'Vencido',
      'No posee',
    ]);
    expect(catalogos.infraccion(2)!.pesoSeveridad, 2.5);
    expect(catalogos.material(2)!.poderCalorifico, 25.0);
    expect(catalogos.material(2)!.coeficientePeligrosidad, 1.5);
  });
}
