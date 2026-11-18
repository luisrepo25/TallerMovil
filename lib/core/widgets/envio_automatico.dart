import 'package:flutter/widgets.dart';

import '../../sync/reintento_envio.dart';

/// Mantiene vivo el reintento automático de envío mientras su pantalla está abierta.
class EnvioAutomatico extends StatefulWidget {
  const EnvioAutomatico({
    super.key,
    required this.conexion,
    required this.enviar,
    required this.hayPendientes,
    required this.child,
  });

  final Stream<bool> conexion;
  final Future<void> Function() enviar;
  final bool Function() hayPendientes;
  final Widget child;

  @override
  State<EnvioAutomatico> createState() => _EnvioAutomaticoState();
}

class _EnvioAutomaticoState extends State<EnvioAutomatico> {
  late final ReintentoEnvio _reintento = ReintentoEnvio(
    conexion: widget.conexion,
    enviar: widget.enviar,
    hayPendientes: widget.hayPendientes,
  );

  @override
  void initState() {
    super.initState();
    _reintento.iniciar();
  }

  @override
  void dispose() {
    _reintento.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
