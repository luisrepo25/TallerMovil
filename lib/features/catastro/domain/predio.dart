import 'dart:convert';

import '../../../core/geo/geo.dart';

/// Predio de uso público descargado del catastro. Solo lectura en el móvil.
class Predio {
  const Predio({
    required this.id,
    required this.nombre,
    required this.geomJson,
    this.direccion,
    this.tipoNombre,
    this.areaM2,
    this.aforo,
  });

  final int id;
  final String nombre;
  final String? direccion;
  final String? tipoNombre;
  final double? areaM2;
  final int? aforo;
  final String geomJson;

  /// Contorno del predio como `[lat, lng]`.
  List<List<double>> get anillo =>
      Geo.anilloDeGeoJson(jsonDecode(geomJson) as Map<String, dynamic>);

  factory Predio.fromApi(Map<String, dynamic> json) => Predio(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    direccion: json['direccion'] as String?,
    tipoNombre:
        (json['tipo_predio'] as Map<String, dynamic>?)?['nombre'] as String?,
    // El backend envía los decimales como texto ("320.50")
    areaM2: json['area_m2'] == null
        ? null
        : double.parse(json['area_m2'].toString()),
    aforo: json['aforo'] as int?,
    geomJson: jsonEncode(json['geom']),
  );

  factory Predio.fromMap(Map<String, Object?> fila) => Predio(
    id: fila['id']! as int,
    nombre: fila['nombre']! as String,
    direccion: fila['direccion'] as String?,
    tipoNombre: fila['tipo_nombre'] as String?,
    areaM2: (fila['area_m2'] as num?)?.toDouble(),
    aforo: fila['aforo'] as int?,
    geomJson: fila['geom_json']! as String,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': nombre,
    'direccion': direccion,
    'tipo_nombre': tipoNombre,
    'area_m2': areaM2,
    'aforo': aforo,
    'geom_json': geomJson,
  };
}
