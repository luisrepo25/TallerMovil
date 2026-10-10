import 'dart:convert';

/// Utilidades mínimas de JWT. Solo se lee el `exp` para saber cuándo renovar;
/// la validez real de la firma la comprueba siempre el backend.
class Jwt {
  Jwt._();

  /// Instante de expiración del token, o `null` si no se puede leer.
  static DateTime? expiracion(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(partes[1])),
      );
      final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    } catch (_) {
      return null;
    }
  }

  /// ¿Vence dentro de [margen] (o ya venció)? Un token ilegible se considera vigente
  /// para no entrar en un bucle de renovaciones: el 401 del servidor decidirá.
  static bool venceProntoOYa(
    String token, {
    Duration margen = const Duration(seconds: 30),
  }) {
    final exp = expiracion(token);
    if (exp == null) return false;
    return exp.difference(DateTime.now()).compareTo(margen) < 0;
  }
}
