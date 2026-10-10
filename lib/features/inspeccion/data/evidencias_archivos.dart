import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Fotos de evidencia: captura y archivo en el teléfono. La UI no habla con la cámara ni con
/// el disco: pasa por aquí (así las pruebas usan una versión falsa).
abstract interface class EvidenciasArchivos {
  /// Abre la cámara o la galería y guarda la foto en un lugar permanente de la app.
  /// Devuelve su ruta, o `null` si el inspector canceló.
  Future<String?> capturar({required bool camara});

  /// Borra el archivo de una foto que se quitó del acta (si existe).
  Future<void> borrar(String ruta);
}

class EvidenciasEnDisco implements EvidenciasArchivos {
  EvidenciasEnDisco({ImagePicker? picker, Uuid? uuid})
    : _picker = picker ?? ImagePicker(),
      _uuid = uuid ?? const Uuid();

  final ImagePicker _picker;
  final Uuid _uuid;

  @override
  Future<String?> capturar({required bool camara}) async {
    final foto = await _picker.pickImage(
      source: camara ? ImageSource.camera : ImageSource.gallery,
      // Una foto de 12 MP pesa ~5 MB: reducida se ve igual de bien y se sube rápido con
      // datos móviles. El servidor acepta hasta 10 MB.
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (foto == null) return null;

    // La ruta que devuelve la cámara es temporal: el sistema puede borrarla antes de que
    // haya conexión para subirla. Se copia a la carpeta de la app.
    final base = await getApplicationDocumentsDirectory();
    final carpeta = Directory(p.join(base.path, 'evidencias'));
    await carpeta.create(recursive: true);
    final destino = p.join(carpeta.path, '${_uuid.v4()}.jpg');
    await File(foto.path).copy(destino);
    return destino;
  }

  @override
  Future<void> borrar(String ruta) async {
    final archivo = File(ruta);
    if (await archivo.exists()) await archivo.delete();
  }
}
