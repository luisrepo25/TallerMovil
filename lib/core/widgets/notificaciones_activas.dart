import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../notifications/explicacion_notificaciones.dart';
import '../notifications/notificaciones_controller.dart';
import '../notifications/notificaciones_service.dart';

/// Mantiene vivas las notificaciones push mientras su pantalla está abierta: al entrar pide
/// el permiso (con su explicación) y registra el teléfono; al salir deja de escuchar.
class NotificacionesActivas extends StatefulWidget {
  const NotificacionesActivas({
    super.key,
    required this.alRecibir,
    required this.child,
  });

  /// Qué hacer con un aviso que llega con la app abierta.
  final void Function(AvisoPush aviso) alRecibir;
  final Widget child;

  @override
  State<NotificacionesActivas> createState() => _NotificacionesActivasState();
}

class _NotificacionesActivasState extends State<NotificacionesActivas> {
  late final NotificacionesController _controlador = context
      .read<NotificacionesController>();

  @override
  void initState() {
    super.initState();
    _controlador.iniciar(
      alExplicar: () => explicarNotificaciones(context),
      alRecibir: widget.alRecibir,
    );
  }

  @override
  void dispose() {
    _controlador.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
