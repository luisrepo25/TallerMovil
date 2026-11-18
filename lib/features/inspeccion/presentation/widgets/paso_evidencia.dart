import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_banner.dart';
import '../inspeccion_controller.dart';
import 'descripcion_foto_form.dart';
import 'fila_foto.dart';

/// Paso 5: fotos de evidencia. Sin límite: una por cada problema que encuentre el inspector.
/// Las fotos quedan en el teléfono y se suben al enviar el acta (funciona sin conexión).
class PasoEvidencia extends StatelessWidget {
  const PasoEvidencia({super.key, required this.controller});

  final InspeccionController controller;

  Future<void> _agregar(BuildContext context, {required bool camara}) async {
    final ruta = await controller.agregarFoto(camara: camara);
    if (ruta != null && context.mounted) {
      await _pedirDescripcion(context, ruta, '');
    }
  }

  Future<void> _pedirDescripcion(
    BuildContext context,
    String ruta,
    String inicial,
  ) async {
    final texto = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DescripcionFotoForm(inicial: inicial),
    );
    if (texto != null) await controller.describirFoto(ruta, texto);
  }

  @override
  Widget build(BuildContext context) {
    final fotos = controller.acta!.evidencias;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evidencia fotográfica', style: textos.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Toma una foto por cada problema que encuentres; puedes agregar todas las '
          'que necesites. Se envían junto con el acta cuando haya conexión.',
          style: TextStyle(color: AppColors.grisTecnico),
        ),
        const SizedBox(height: 16),
        if (controller.error != null) ...[
          ErrorBanner(text: controller.error!),
          const SizedBox(height: 12),
        ],
        if (fotos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aún no agregaste fotos. Si no hay nada que documentar, puedes continuar.',
              style: TextStyle(color: AppColors.grisTecnico),
            ),
          ),
        for (final f in fotos)
          FilaFoto(
            foto: f,
            onEditar: () =>
                _pedirDescripcion(context, f.rutaLocal, f.descripcion),
            onQuitar: () => controller.quitarFoto(f.rutaLocal),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _agregar(context, camara: true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _agregar(context, camara: false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
