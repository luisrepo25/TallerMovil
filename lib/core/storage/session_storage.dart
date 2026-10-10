/// Almacenamiento de la sesión del inspector: tokens y el último usuario conocido.
///
/// El usuario se guarda para poder **abrir la app sin conexión** (offline-first):
/// al arrancar sin red no se puede validar el token, pero sí se puede reconocer
/// al inspector que ya inició sesión antes.
///
/// Es una interfaz para poder sustituirla en las pruebas por una versión en memoria.
abstract class SessionStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({required String access, String? refresh});

  /// Último usuario conocido, serializado como JSON.
  Future<String?> readUsuarioJson();
  Future<void> saveUsuarioJson(String json);

  /// Borra tokens y usuario (cierre de sesión).
  Future<void> clear();
}
