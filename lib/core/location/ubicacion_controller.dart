import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ubicacion_service.dart';

/// Sigue la ubicación del inspector mientras la pantalla del mapa está abierta
/// (se detiene al cerrarla para no gastar batería).
class UbicacionController extends ChangeNotifier {
  UbicacionController(this._servicio, {Future<bool> Function()? alExplicar})
    : _alExplicar = alExplicar;

  final UbicacionService _servicio;

  /// Muestra al usuario para qué se usa la ubicación antes del diálogo del sistema.
  /// Devuelve false si prefiere no darla ahora.
  final Future<bool> Function()? _alExplicar;

  Ubicacion? actual;
  PermisoUbicacion? permiso;
  bool buscando = false;

  StreamSubscription<Ubicacion>? _suscripcion;
  bool _liberado = false;

  /// Revisa el permiso y empieza a seguir la posición. Se puede volver a llamar para
  /// reintentar (por ejemplo, después de que el usuario activó el GPS).
  Future<void> iniciar() async {
    await _suscripcion?.cancel();
    buscando = true;
    _avisar();

    if (_alExplicar != null && await _servicio.faltaPreguntarPermiso()) {
      final acepto = await _alExplicar();
      if (!acepto) {
        permiso = PermisoUbicacion.denegado;
        buscando = false;
        _avisar();
        return;
      }
    }
    if (_liberado) return;

    permiso = await _servicio.verificarYPedirPermiso();
    if (_liberado) return;
    if (permiso != PermisoUbicacion.concedido) {
      buscando = false;
      _avisar();
      return;
    }

    _suscripcion = _servicio.seguir().listen(
      (posicion) {
        actual = posicion;
        buscando = false;
        _avisar();
      },
      onError: (_) {
        buscando = false;
        _avisar();
      },
    );
  }

  Future<void> abrirAjustes() async {
    final motivo = permiso;
    if (motivo != null && motivo != PermisoUbicacion.concedido) {
      await _servicio.abrirAjustes(motivo);
    }
  }

  void _avisar() {
    if (!_liberado) notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    _suscripcion?.cancel();
    super.dispose();
  }
}
