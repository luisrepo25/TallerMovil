import 'dart:async';

import 'package:app_movil_uubr/core/notifications/dispositivos_api.dart';
import 'package:app_movil_uubr/core/notifications/notificaciones_service.dart';

/// Firebase de mentira: se decide el permiso y se emiten tokens y avisos a mano.
class NotificacionesFalsas implements NotificacionesService {
  NotificacionesFalsas({this.estado = PermisoNotificaciones.concedido});

  PermisoNotificaciones estado;
  String? token = 'token-1';
  bool pidioPermiso = false;
  int tokensOlvidados = 0;

  final _renovado = StreamController<String>.broadcast();
  final _primerPlano = StreamController<AvisoPush>.broadcast();
  final _alAbrir = StreamController<AvisoPush>.broadcast();

  bool get alguienEscucha =>
      _renovado.hasListener || _primerPlano.hasListener || _alAbrir.hasListener;

  void renovarToken(String nuevo) => _renovado.add(nuevo);

  void llegaAvisoEnPrimerPlano(AvisoPush aviso) => _primerPlano.add(aviso);

  void usuarioTocaAviso(AvisoPush aviso) => _alAbrir.add(aviso);

  @override
  Future<PermisoNotificaciones> permiso() async => estado;

  @override
  Future<PermisoNotificaciones> pedirPermiso() async {
    pidioPermiso = true;
    // El usuario acepta en el diálogo del sistema
    estado = PermisoNotificaciones.concedido;
    return estado;
  }

  @override
  Future<String?> obtenerToken() async => token;

  @override
  Stream<String> get tokenRenovado => _renovado.stream;

  @override
  Stream<AvisoPush> get avisosEnPrimerPlano => _primerPlano.stream;

  @override
  Stream<AvisoPush> get avisosAlAbrir => _alAbrir.stream;

  @override
  Future<void> olvidarToken() async => tokensOlvidados++;
}

/// El servidor de mentira: guarda los tokens y puede fallar como si no hubiera conexión.
class DispositivosFalsos implements DispositivosRegistro {
  final registrados = <String>[];
  final quitados = <String>[];
  bool sinConexion = false;

  @override
  Future<void> registrar(String token) async {
    if (sinConexion) throw Exception('sin conexión');
    registrados.add(token);
  }

  @override
  Future<void> quitar(String token) async {
    if (sinConexion) throw Exception('sin conexión');
    quitados.add(token);
  }
}
