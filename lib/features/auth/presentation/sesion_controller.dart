import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/usuario.dart';

enum EstadoSesion { cargando, autenticado, sinSesion }

/// Estado global de la sesión del inspector. Se crea una sola vez en la raíz de la app.
/// No navega: las pantallas (o el cableado de `app.dart`) deciden a dónde ir.
class SesionController extends ChangeNotifier {
  SesionController(this._repositorio, {this.alCerrarSesion});

  final AuthRepository _repositorio;

  /// Se ejecuta al cerrar sesión por voluntad del usuario (ej. borrar los datos
  /// descargados para no mezclarlos con los del siguiente usuario).
  final Future<void> Function()? alCerrarSesion;

  EstadoSesion estado = EstadoSesion.cargando;
  Usuario? usuario;

  /// Al abrir la app: recupera la sesión guardada (funciona sin conexión).
  Future<void> restaurar() async {
    usuario = await _repositorio.restaurarSesion();
    estado = usuario == null
        ? EstadoSesion.sinSesion
        : EstadoSesion.autenticado;
    notifyListeners();
  }

  /// Lo llama el login cuando el repositorio ya validó al inspector.
  void iniciar(Usuario nuevo) {
    usuario = nuevo;
    estado = EstadoSesion.autenticado;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    await alCerrarSesion?.call();
    expirar();
  }

  /// La sesión dejó de valer (cierre voluntario o refresh token vencido).
  void expirar() {
    if (estado == EstadoSesion.sinSesion) return;
    usuario = null;
    estado = EstadoSesion.sinSesion;
    notifyListeners();
  }
}
