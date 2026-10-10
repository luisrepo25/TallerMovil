// Catálogos que el inspector elige al llenar un acta. Se descargan con las campañas y se
// usan sin conexión. Los coeficientes (Hi, Ci) solo se muestran: la carga de fuego la
// calcula el servidor al sincronizar.

class EstadoExtintor {
  const EstadoExtintor({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory EstadoExtintor.fromApi(Map<String, dynamic> json) =>
      EstadoExtintor(id: json['id'] as int, nombre: json['nombre'] as String);

  factory EstadoExtintor.fromMap(Map<String, Object?> fila) =>
      EstadoExtintor(id: fila['id']! as int, nombre: fila['nombre']! as String);

  Map<String, Object?> toMap() => {'id': id, 'nombre': nombre};
}

class TipoInfraccion {
  const TipoInfraccion({
    required this.id,
    required this.nombre,
    required this.pesoSeveridad,
  });

  final int id;
  final String nombre;
  final double pesoSeveridad;

  factory TipoInfraccion.fromApi(Map<String, dynamic> json) => TipoInfraccion(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    pesoSeveridad: double.parse(json['peso_severidad'].toString()),
  );

  factory TipoInfraccion.fromMap(Map<String, Object?> fila) => TipoInfraccion(
    id: fila['id']! as int,
    nombre: fila['nombre']! as String,
    pesoSeveridad: (fila['peso_severidad']! as num).toDouble(),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': nombre,
    'peso_severidad': pesoSeveridad,
  };
}

class MaterialCombustible {
  const MaterialCombustible({
    required this.id,
    required this.nombre,
    required this.poderCalorifico,
    required this.coeficientePeligrosidad,
  });

  final int id;
  final String nombre;

  /// Hi, en MJ/kg
  final double poderCalorifico;

  /// Ci
  final double coeficientePeligrosidad;

  factory MaterialCombustible.fromApi(Map<String, dynamic> json) =>
      MaterialCombustible(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        poderCalorifico: double.parse(
          json['poder_calorifico_mj_kg'].toString(),
        ),
        coeficientePeligrosidad: double.parse(
          json['coeficiente_peligrosidad'].toString(),
        ),
      );

  factory MaterialCombustible.fromMap(Map<String, Object?> fila) =>
      MaterialCombustible(
        id: fila['id']! as int,
        nombre: fila['nombre']! as String,
        poderCalorifico: (fila['poder_calorifico']! as num).toDouble(),
        coeficientePeligrosidad: (fila['coeficiente_peligrosidad']! as num)
            .toDouble(),
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': nombre,
    'poder_calorifico': poderCalorifico,
    'coeficiente_peligrosidad': coeficientePeligrosidad,
  };
}

/// Los tres catálogos juntos, como los usa el asistente de inspección.
class Catalogos {
  const Catalogos({
    required this.estadosExtintor,
    required this.infracciones,
    required this.materiales,
  });

  final List<EstadoExtintor> estadosExtintor;
  final List<TipoInfraccion> infracciones;
  final List<MaterialCombustible> materiales;

  bool get estaVacio =>
      estadosExtintor.isEmpty && infracciones.isEmpty && materiales.isEmpty;

  EstadoExtintor? estadoExtintor(int? id) =>
      estadosExtintor.where((e) => e.id == id).firstOrNull;

  TipoInfraccion? infraccion(int id) =>
      infracciones.where((i) => i.id == id).firstOrNull;

  MaterialCombustible? material(int id) =>
      materiales.where((m) => m.id == id).firstOrNull;
}
