import 'package:flutter/material.dart';

/// Llave global del navegador: permite navegar desde fuera de un widget, por ejemplo
/// al vencer la sesión en medio de una petición.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
