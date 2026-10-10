// Falla si algún archivo .dart de lib/ o test/ supera el límite de líneas del proyecto.
//
//   dart run tool/check_line_limit.dart
//
// Regla de MOVIL.md §4: ningún archivo ni widget pasa de 150 líneas.
import 'dart:io';

const int limite = 150;
const carpetas = ['lib', 'test'];

void main() {
  final excedidos = <String, int>{};

  for (final carpeta in carpetas) {
    final dir = Directory(carpeta);
    if (!dir.existsSync()) continue;
    for (final entidad in dir.listSync(recursive: true)) {
      if (entidad is! File || !entidad.path.endsWith('.dart')) continue;
      final lineas = entidad.readAsLinesSync().length;
      if (lineas > limite) excedidos[entidad.path.replaceAll('\\', '/')] = lineas;
    }
  }

  if (excedidos.isEmpty) {
    stdout.writeln('OK: ningún archivo supera las $limite líneas.');
    return;
  }

  stderr.writeln('Archivos que superan las $limite líneas:');
  excedidos.forEach((ruta, lineas) => stderr.writeln('  $lineas  $ruta'));
  exit(1);
}
