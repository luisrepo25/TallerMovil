import 'package:flutter/foundation.dart';

import '../data/evidencias_archivos.dart';
import '../domain/acta_edicion.dart';
import '../domain/acta_local.dart';

/// Evidencia fotográfica del acta: capturar, describir y quitar fotos. La cámara y el disco
/// se tocan solo a través de [archivos] (así las pruebas usan una versión falsa).
mixin FotosDelActa on ChangeNotifier {
  EvidenciasArchivos get archivos;
  bool get editable;

  /// Error listo para mostrar al inspector.
  String? get error;
  set error(String? valor);

  /// Notifica a la pantalla (ignora la llamada si el controlador ya se liberó).
  void avisar();

  Future<void> modificar(ActaLocal Function(ActaLocal) cambio);

  /// Toma (o elige) una foto y la agrega al acta, sin límite de cantidad. Devuelve la ruta de
  /// la foto agregada para que la pantalla pida su descripción, o `null` si se canceló o falló.
  Future<String?> agregarFoto({required bool camara}) async {
    if (!editable) return null;
    try {
      final ruta = await archivos.capturar(camara: camara);
      if (ruta == null) return null;
      await modificar((a) => a.conEvidencia(ruta, ''));
      return ruta;
    } on Exception {
      error = camara
          ? 'No se pudo abrir la cámara. Revisa el permiso de la app en Ajustes.'
          : 'No se pudo abrir la galería. Revisa el permiso de la app en Ajustes.';
      avisar();
      return null;
    }
  }

  Future<void> describirFoto(String ruta, String descripcion) =>
      modificar((a) => a.conDescripcionEvidencia(ruta, descripcion));

  Future<void> quitarFoto(String ruta) async {
    await modificar((a) => a.sinEvidencia(ruta));
    await archivos.borrar(ruta);
  }
}
