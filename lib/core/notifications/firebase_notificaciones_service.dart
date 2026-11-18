import 'package:firebase_messaging/firebase_messaging.dart';

import 'notificaciones_service.dart';

/// Implementación real sobre Firebase Cloud Messaging (paquete `firebase_messaging`).
/// Se crea solo después de `Firebase.initializeApp()`.
///
/// Se usan `getToken`, `onTokenRefresh` y `deleteToken` (marcados como obsoletos en la v17):
/// la API nueva (`register`/`onRegistered`) entrega un *Firebase Installation ID*, y el
/// backend envía por la API HTTP v1 de FCM, cuyo campo `token` espera el token de registro
/// clásico. Revisar si se sube de versión mayor del paquete.
class FirebaseNotificacionesService implements NotificacionesService {
  FirebaseNotificacionesService({FirebaseMessaging? messaging})
    : _fcm = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _fcm;

  static PermisoNotificaciones _traducir(AuthorizationStatus estado) =>
      switch (estado) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PermisoNotificaciones.concedido,
        AuthorizationStatus.notDetermined => PermisoNotificaciones.porPreguntar,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PermisoNotificaciones.denegado,
      };

  static AvisoPush _aviso(RemoteMessage mensaje) => AvisoPush(
    titulo: mensaje.notification?.title,
    cuerpo: mensaje.notification?.body,
    datos: {for (final e in mensaje.data.entries) e.key: e.value.toString()},
  );

  @override
  Future<PermisoNotificaciones> permiso() async =>
      _traducir((await _fcm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PermisoNotificaciones> pedirPermiso() async =>
      _traducir((await _fcm.requestPermission()).authorizationStatus);

  @override
  // ignore: deprecated_member_use
  Future<String?> obtenerToken() => _fcm.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRenovado => _fcm.onTokenRefresh;

  @override
  Stream<AvisoPush> get avisosEnPrimerPlano =>
      FirebaseMessaging.onMessage.map(_aviso);

  @override
  Stream<AvisoPush> get avisosAlAbrir =>
      FirebaseMessaging.onMessageOpenedApp.map(_aviso);

  @override
  // ignore: deprecated_member_use
  Future<void> olvidarToken() => _fcm.deleteToken();
}
