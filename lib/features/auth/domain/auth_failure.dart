/// Motivos por los que falla iniciar sesión. La capa de datos los traduce desde
/// la respuesta HTTP; la UI solo decide qué mensaje mostrar.
enum AuthFailureTipo {
  credencialesInvalidas,
  noEsInspector,
  sinConexion,
  servidor,
}

class AuthFailure implements Exception {
  const AuthFailure(this.tipo);

  final AuthFailureTipo tipo;

  /// Mensaje listo para mostrar al inspector.
  String get mensaje {
    switch (tipo) {
      case AuthFailureTipo.credencialesInvalidas:
        return 'Credenciales inválidas. Verifica tu email y contraseña.';
      case AuthFailureTipo.noEsInspector:
        return 'Esta cuenta no es de Inspector Técnico. '
            'Usa la plataforma web o consulta a tu Oficial de Mando.';
      case AuthFailureTipo.sinConexion:
        return 'No hay conexión con el servidor. Para iniciar sesión por primera vez '
            'necesitas internet.';
      case AuthFailureTipo.servidor:
        return 'El servidor tuvo un problema. Intenta de nuevo en unos minutos.';
    }
  }

  @override
  String toString() => 'AuthFailure($tipo)';
}
