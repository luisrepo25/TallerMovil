import 'dart:async';

import 'dispositivos_api.dart';
import 'notificaciones_service.dart';

/// Pide el permiso, registra el teléfono en el servidor y reparte los avisos que llegan.
///
/// **Nunca bloquea ni falla la app**: las notificaciones son un aviso extra. Sin conexión el
/// registro se omite y se reintenta la próxima vez que se abre la app (offline-first).
class NotificacionesController {
  NotificacionesController({
    required NotificacionesService servicio,
    required DispositivosRegistro dispositivos,
  }) : _servicio = servicio,
       _dispositivos = dispositivos;

  final NotificacionesService _servicio;
  final DispositivosRegistro _dispositivos;

  final _suscripciones = <StreamSubscription<Object?>>[];
  String? _tokenRegistrado;

  /// [alExplicar] muestra para qué sirven los avisos ANTES del diálogo del sistema y
  /// devuelve `false` si el usuario prefiere no darlos ahora (se le vuelve a ofrecer al
  /// abrir la app otra vez). [alRecibir] atiende cada aviso que llega con la app abierta.
  Future<void> iniciar({
    required Future<bool> Function() alExplicar,
    required void Function(AvisoPush) alRecibir,
  }) async {
    detener();
    _suscripciones
      ..add(_servicio.avisosEnPrimerPlano.listen(alRecibir))
      ..add(_servicio.avisosAlAbrir.listen(alRecibir));

    var permiso = await _servicio.permiso();
    if (permiso == PermisoNotificaciones.porPreguntar) {
      if (!await alExplicar()) return;
      permiso = await _servicio.pedirPermiso();
    }
    if (permiso != PermisoNotificaciones.concedido) return;

    _suscripciones.add(_servicio.tokenRenovado.listen(_registrar));
    final token = await _servicio.obtenerToken();
    if (token != null) await _registrar(token);
  }

  Future<void> _registrar(String token) async {
    try {
      await _dispositivos.registrar(token);
      _tokenRegistrado = token;
    } on Object {
      // Sin conexión o servidor caído: no importa, se reintenta al abrir la app.
    }
  }

  /// Al cerrar sesión: el servidor deja de avisar a este teléfono. Si no hay red, el token
  /// queda invalidado igual (se borra en Firebase) y el servidor lo olvida al no poder
  /// entregarle nada. Debe llamarse ANTES de borrar la sesión: la baja necesita el JWT.
  Future<void> cerrarSesion() async {
    detener();
    try {
      final token = _tokenRegistrado ?? await _servicio.obtenerToken();
      if (token != null) await _dispositivos.quitar(token);
    } on Object {
      // Se ignora: ver arriba.
    }
    try {
      await _servicio.olvidarToken();
    } on Object {
      // Se ignora.
    }
    _tokenRegistrado = null;
  }

  void detener() {
    for (final s in _suscripciones) {
      s.cancel();
    }
    _suscripciones.clear();
  }
}
