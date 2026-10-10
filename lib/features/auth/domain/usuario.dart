import 'dart:convert';

/// Usuario autenticado, tal como lo devuelve `GET /api/usuarios/me/`.
/// Los subtipos pueden solaparse (una persona puede ser Inspector y Oficial a la vez).
class Usuario {
  const Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.rolNombre,
    required this.subtipos,
  });

  final int id;
  final String nombreCompleto;
  final String email;
  final String rolNombre;
  final List<String> subtipos;

  /// La app móvil es exclusiva del Inspector Técnico.
  bool get esInspector => subtipos.contains('inspector_tecnico');

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    nombreCompleto: json['nombre_completo'] as String,
    email: json['email'] as String,
    rolNombre:
        (json['rol'] as Map<String, dynamic>?)?['nombre'] as String? ?? '',
    subtipos: List<String>.from(json['subtipos'] as List? ?? const []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre_completo': nombreCompleto,
    'email': email,
    'rol': {'nombre': rolNombre},
    'subtipos': subtipos,
  };

  String toJsonString() => jsonEncode(toJson());

  factory Usuario.fromJsonString(String texto) =>
      Usuario.fromJson(jsonDecode(texto) as Map<String, dynamic>);
}
