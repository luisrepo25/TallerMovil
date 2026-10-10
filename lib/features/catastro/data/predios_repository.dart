import '../../../core/geo/geo.dart';
import '../../campanias/domain/campania.dart';
import '../domain/predio.dart';
import 'predios_local_source.dart';

/// Predios disponibles sin conexión.
class PrediosRepository {
  PrediosRepository(this._local);

  final PrediosLocalSource _local;

  Future<List<Predio>> listar() => _local.listar();

  /// Predios cuyo contorno toca la zona de la campaña. Es una ayuda para el inspector;
  /// el backend valida de nuevo (ST_Intersects) cuando el acta se sincroniza.
  /// Una campaña sin zona no tiene predios.
  Future<List<Predio>> enZona(Campania campania) async {
    return filtrarEnZona(await _local.listar(), campania);
  }

  static List<Predio> filtrarEnZona(List<Predio> predios, Campania campania) {
    if (!campania.tieneZona) return const [];
    final zona = campania.anillo;
    return predios
        .where((p) => Geo.poligonosSeIntersectan(p.anillo, zona))
        .toList();
  }
}
