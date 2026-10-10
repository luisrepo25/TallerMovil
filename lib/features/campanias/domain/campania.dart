import 'dart:convert';

import '../../../core/geo/geo.dart';

/// Campaña de fiscalización asignada al inspector. Los estados son los del backend:
/// `pendiente`, `en_curso`, `cerrada`. La app nunca los modifica.
class Campania {
  const Campania({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    this.geomJson,
  });

  final int id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;

  /// Polígono de la zona como GeoJSON (texto); `null` si aún no se definió.
  final String? geomJson;

  bool get estaCerrada => estado == 'cerrada';
  bool get tieneZona => geomJson != null;

  /// Anillo de la zona como `[lat, lng]`; vacío si no hay zona.
  List<List<double>> get anillo => geomJson == null
      ? const []
      : Geo.anilloDeGeoJson(jsonDecode(geomJson!) as Map<String, dynamic>);

  factory Campania.fromApi(Map<String, dynamic> json) => Campania(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
    fechaFin: DateTime.parse(json['fecha_fin'] as String),
    estado: json['estado'] as String,
    geomJson: json['geom'] == null ? null : jsonEncode(json['geom']),
  );

  factory Campania.fromMap(Map<String, Object?> fila) => Campania(
    id: fila['id']! as int,
    nombre: fila['nombre']! as String,
    fechaInicio: DateTime.parse(fila['fecha_inicio']! as String),
    fechaFin: DateTime.parse(fila['fecha_fin']! as String),
    estado: fila['estado']! as String,
    geomJson: fila['geom_json'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': nombre,
    'fecha_inicio': _soloFecha(fechaInicio),
    'fecha_fin': _soloFecha(fechaFin),
    'estado': estado,
    'geom_json': geomJson,
  };

  static String _soloFecha(DateTime f) => f.toIso8601String().substring(0, 10);
}
