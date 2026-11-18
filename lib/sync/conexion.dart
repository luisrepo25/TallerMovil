import 'package:connectivity_plus/connectivity_plus.dart';

/// Avisa cuando el teléfono gana o pierde red: `true` si hay alguna (wifi, datos, etc.).
/// Que haya red no garantiza que haya internet: por eso el envío igual tolera el fallo y
/// se reintenta. Un error del plugin (por ejemplo, en pruebas) se ignora.
Stream<bool> cambiosDeConexion() => Connectivity().onConnectivityChanged
    .map((tipos) => !tipos.contains(ConnectivityResult.none))
    .handleError((_) {});
