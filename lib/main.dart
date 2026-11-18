import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/notifications/firebase_notificaciones_service.dart';
import 'core/notifications/notificaciones_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(notificaciones: await _iniciarNotificaciones()));
}

/// Las notificaciones son un extra: si Firebase no está configurado o falla al arrancar, la
/// app sigue funcionando sin ellas.
Future<NotificacionesService> _iniciarNotificaciones() async {
  try {
    await Firebase.initializeApp();
    return FirebaseNotificacionesService();
  } on Object {
    return const NotificacionesNoDisponibles();
  }
}
