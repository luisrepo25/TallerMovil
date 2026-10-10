import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ubicacion_service.dart';

/// Sigue la ubicación del inspector mientras la pantalla del mapa está abierta
/// (se detiene al cerrarla para no gastar batería).
class UbicacionController extends ChangeNotifier {
  UbicacionController(this._servicio);

  final UbicacionService _servicio;

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

    permiso = await _servicio.verificarYPedirPermiso();
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
