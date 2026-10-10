import '../domain/campania.dart';
import 'campanias_local_source.dart';

/// Campañas asignadas al inspector, siempre leídas de la base local.
class CampaniasRepository {
  CampaniasRepository(this._local);

  final CampaniasLocalSource _local;

  Future<List<Campania>> listar() => _local.listar();

  Future<Campania?> obtener(int id) => _local.obtener(id);
}
