import 'dart:async';

/// Estado del permiso para mostrar notificaciones.
enum PermisoNotificaciones {
  concedido,

  /// Todavía no se le pidió al usuario: es el momento de explicarle para qué sirven.
  porPreguntar,

  /// Dijo que no. Solo se arregla desde los ajustes del teléfono.
  denegado,
}

/// Una notificación recibida, ya sin nada de Firebase.
class AvisoPush {
  const AvisoPush({this.titulo, this.cuerpo, this.datos = const {}});

  static const tipoCampaniaAsignada = 'campania_asignada';

  final String? titulo;
  final String? cuerpo;
  final Map<String, String> datos;

  bool get esCampaniaAsignada => datos['tipo'] == tipoCampaniaAsignada;
}

/// Notificaciones push del teléfono. Es una interfaz para poder sustituirla en las pruebas
/// (no hay Firebase en un test ni en el escritorio).
abstract class NotificacionesService {
  Future<PermisoNotificaciones> permiso();

  /// Muestra el diálogo del sistema (Android 13+ / iOS).
  Future<PermisoNotificaciones> pedirPermiso();

  /// Identificador de esta instalación para que el servidor le envíe avisos.
  Future<String?> obtenerToken();

  /// Firebase renovó el token: hay que volver a registrarlo en el servidor.
  Stream<String> get tokenRenovado;

  /// Llegó un aviso con la app abierta (el sistema no lo muestra solo).
  Stream<AvisoPush> get avisosEnPrimerPlano;

  /// El usuario tocó un aviso estando la app en segundo plano.
  Stream<AvisoPush> get avisosAlAbrir;

  /// Invalida el token actual (al cerrar sesión): nadie más recibe avisos de este usuario
  /// en este aparato.
  Future<void> olvidarToken();
}

/// Sin notificaciones: la app funciona igual (escritorio, pruebas, o Firebase sin configurar).
class NotificacionesNoDisponibles implements NotificacionesService {
  const NotificacionesNoDisponibles();

  @override
  Future<PermisoNotificaciones> permiso() async =>
      PermisoNotificaciones.denegado;

  @override
  Future<PermisoNotificaciones> pedirPermiso() async =>
      PermisoNotificaciones.denegado;

  @override
  Future<String?> obtenerToken() async => null;

  @override
  Stream<String> get tokenRenovado => const Stream.empty();

  @override
  Stream<AvisoPush> get avisosEnPrimerPlano => const Stream.empty();

  @override
  Stream<AvisoPush> get avisosAlAbrir => const Stream.empty();

  @override
  Future<void> olvidarToken() async {}
}
