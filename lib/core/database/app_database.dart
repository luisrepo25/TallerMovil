import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migraciones.dart';

/// Base de datos local (SQLite): **fuente de verdad de la app** (offline-first).
/// La UI lee de aquí; la red solo la mantiene al día (ver `lib/sync`).
/// El esquema versión por versión está en `migraciones.dart`.
class AppDatabase {
  AppDatabase({this.ruta, DatabaseFactory? factory}) : _factory = factory;

  /// Ruta del archivo; `inMemoryDatabasePath` para pruebas.
  final String? ruta;
  final DatabaseFactory? _factory;

  /// Subir este número al agregar un bloque nuevo en `migraciones.dart`.
  static const int version = 4;

  /// Datos que vienen del servidor y se pueden volver a descargar.
  static const tablasDescargadas = [
    'campanias',
    'predios',
    'cat_estados_extintor',
    'cat_infracciones',
    'cat_materiales',
    'meta',
  ];

  /// Datos del inspector que NO existen en el servidor hasta sincronizar: borrarlos
  /// es perder trabajo. Hijos primero.
  static const tablasDelInspector = [
    'acta_materiales',
    'acta_infracciones',
    'acta_evidencias',
    'acta_solicitudes_material',
    'actas',
  ];

  Database? _db;

  Future<Database> get db async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final fabrica = _factory ?? databaseFactory;
    final archivo = ruta ?? p.join(await fabrica.getDatabasesPath(), 'uubr.db');
    return fabrica.openDatabase(
      archivo,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, v) => aplicarMigraciones(db, 0),
        onUpgrade: (db, desde, hasta) => aplicarMigraciones(db, desde),
      ),
    );
  }

  /// Borra absolutamente todo, incluidas las actas aún no enviadas. Se usa al cerrar sesión
  /// (para no mezclar los datos de dos personas); si había actas pendientes, la pantalla
  /// ya le pidió confirmación explícita al inspector antes de llegar aquí.
  Future<void> limpiarTodo() async {
    final base = await db;
    await base.transaction((txn) async {
      for (final tabla in [...tablasDelInspector, ...tablasDescargadas]) {
        await txn.delete(tabla);
      }
    });
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }
}
