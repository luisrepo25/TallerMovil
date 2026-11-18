import 'dart:async';

/// Reintenta el envío de actas mientras la pantalla de campañas está abierta: cuando la
/// conexión vuelve y, por si el aviso del sistema no llega, cada cierto tiempo. Solo actúa
/// si hay actas pendientes; el envío en sí lo decide [enviar] (que ignora la llamada si ya
/// hay uno en curso).
class ReintentoEnvio {
  ReintentoEnvio({
    required Stream<bool> conexion,
    required Future<void> Function() enviar,
    required bool Function() hayPendientes,
    this.intervalo = const Duration(seconds: 60),
  }) : _conexion = conexion,
       _enviar = enviar,
       _hayPendientes = hayPendientes;

  final Stream<bool> _conexion;
  final Future<void> Function() _enviar;
  final bool Function() _hayPendientes;
  final Duration intervalo;

  StreamSubscription<bool>? _suscripcion;
  Timer? _temporizador;

  void iniciar() {
    detener();
    _suscripcion = _conexion.listen((hayRed) {
      if (hayRed) _intentar();
    });
    _temporizador = Timer.periodic(intervalo, (_) => _intentar());
  }

  void _intentar() {
    if (_hayPendientes()) _enviar();
  }

  void detener() {
    _suscripcion?.cancel();
    _temporizador?.cancel();
    _suscripcion = null;
    _temporizador = null;
  }
}
