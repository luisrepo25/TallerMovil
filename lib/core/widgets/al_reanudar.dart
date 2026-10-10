import 'package:flutter/widgets.dart';

/// Avisa cuando la app vuelve a primer plano (el inspector regresa de otra app o desbloquea
/// el teléfono). Es el momento de reintentar lo que quedó pendiente por falta de señal.
class AlReanudar extends StatefulWidget {
  const AlReanudar({super.key, required this.onReanudar, required this.child});

  final VoidCallback onReanudar;
  final Widget child;

  @override
  State<AlReanudar> createState() => _AlReanudarState();
}

class _AlReanudarState extends State<AlReanudar> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onReanudar();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
