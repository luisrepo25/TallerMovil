import 'package:sqflite/sqflite.dart';

/// Esquema de la base local, versión por versión. Las migraciones son incrementales:
/// cada versión nueva agrega su bloque y NUNCA se edita el de una versión ya publicada
/// (los teléfonos que ya la aplicaron no la volverían a ejecutar).
Future<void> aplicarMigraciones(Database db, int desde) async {
  if (desde < 1) await _v1(db);
  if (desde < 2) await _v2(db);
  if (desde < 3) await _v3(db);
  if (desde < 4) await _v4(db);
}

/// v4: de qué inspección anterior se precargó un acta (reinspección).
Future<void> _v4(Database db) async {
  await db.execute('ALTER TABLE actas ADD COLUMN precargada_de TEXT');
}

/// v3: fotos de evidencia y solicitudes de material nuevo, ambas dentro del acta.
Future<void> _v3(Database db) async {
  await db.execute('''
    CREATE TABLE acta_evidencias (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      acta_uuid TEXT NOT NULL REFERENCES actas (uuid_local) ON DELETE CASCADE,
      ruta_local TEXT NOT NULL,
      descripcion TEXT,
      url_remota TEXT
    )''');
  await db.execute('''
    CREATE TABLE acta_solicitudes_material (
      uuid_local TEXT PRIMARY KEY,
      acta_uuid TEXT NOT NULL REFERENCES actas (uuid_local) ON DELETE CASCADE,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      peso_kg_estimado REAL
    )''');
}

/// v1: campañas asignadas y predios descargados para trabajar sin conexión.
Future<void> _v1(Database db) async {
  await db.execute('''
    CREATE TABLE campanias (
      id INTEGER PRIMARY KEY,
      nombre TEXT NOT NULL,
      fecha_inicio TEXT NOT NULL,
      fecha_fin TEXT NOT NULL,
      estado TEXT NOT NULL,
      geom_json TEXT
    )''');
  await db.execute('''
    CREATE TABLE predios (
      id INTEGER PRIMARY KEY,
      nombre TEXT NOT NULL,
      direccion TEXT,
      tipo_nombre TEXT,
      area_m2 REAL,
      aforo INTEGER,
      geom_json TEXT NOT NULL
    )''');
  await db.execute(
    'CREATE TABLE meta (clave TEXT PRIMARY KEY, valor TEXT NOT NULL)',
  );
}

/// v2: catálogos y actas de inspección hechas en el teléfono.
Future<void> _v2(Database db) async {
  await db.execute(
    'CREATE TABLE cat_estados_extintor (id INTEGER PRIMARY KEY, nombre TEXT NOT NULL)',
  );
  await db.execute('''
    CREATE TABLE cat_infracciones (
      id INTEGER PRIMARY KEY,
      nombre TEXT NOT NULL,
      peso_severidad REAL NOT NULL
    )''');
  await db.execute('''
    CREATE TABLE cat_materiales (
      id INTEGER PRIMARY KEY,
      nombre TEXT NOT NULL,
      poder_calorifico REAL NOT NULL,
      coeficiente_peligrosidad REAL NOT NULL
    )''');
  await db.execute('''
    CREATE TABLE actas (
      uuid_local TEXT PRIMARY KEY,
      predio_id INTEGER NOT NULL,
      campania_id INTEGER NOT NULL,
      fecha_inspeccion TEXT NOT NULL,
      estado_extintores_id INTEGER,
      fallas_electricas INTEGER NOT NULL DEFAULT 0,
      rutas_despejadas INTEGER NOT NULL DEFAULT 1,
      estado TEXT NOT NULL,
      fecha_cierre_local TEXT,
      acta_id_servidor INTEGER,
      carga_fuego REAL,
      scoring_riesgo REAL,
      cluster_riesgo TEXT,
      motivo_rechazo TEXT
    )''');
  await db.execute(
    'CREATE INDEX idx_actas_campania_predio ON actas (campania_id, predio_id)',
  );
  await db.execute('''
    CREATE TABLE acta_materiales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      acta_uuid TEXT NOT NULL REFERENCES actas (uuid_local) ON DELETE CASCADE,
      material_id INTEGER NOT NULL,
      peso_kg REAL NOT NULL
    )''');
  await db.execute('''
    CREATE TABLE acta_infracciones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      acta_uuid TEXT NOT NULL REFERENCES actas (uuid_local) ON DELETE CASCADE,
      tipo_infraccion_id INTEGER NOT NULL,
      descripcion TEXT
    )''');
}
