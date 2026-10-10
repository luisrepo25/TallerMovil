import '../domain/catalogos.dart';

/// De dónde salen los catálogos. La implementación real es SQLite
/// ([CatalogosLocalSource]); las pruebas usan datos en memoria.
abstract interface class CatalogosStore {
  Future<Catalogos> leer();
}

/// Catálogos descargados, disponibles sin conexión.
class CatalogosRepository {
  CatalogosRepository(this._store);

  final CatalogosStore _store;

  Future<Catalogos> leer() => _store.leer();
}
