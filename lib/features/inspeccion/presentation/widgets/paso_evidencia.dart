import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../domain/acta_local.dart';
import '../inspeccion_controller.dart';

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
      builder: (_) => _DescripcionForm(inicial: inicial),
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
          _FilaFoto(
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

class _FilaFoto extends StatelessWidget {
  const _FilaFoto({
    required this.foto,
    required this.onEditar,
    required this.onQuitar,
  });

  final EvidenciaActa foto;
  final VoidCallback onEditar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onEditar,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(foto.rutaLocal),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            // cacheWidth evita decodificar la foto completa para una miniatura
            cacheWidth: 168,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        title: Text(
          foto.descripcion.isEmpty ? 'Sin descripción' : foto.descripcion,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: foto.descripcion.isEmpty ? AppColors.grisTecnico : null,
          ),
        ),
        subtitle: const Text('Toca para describir el problema'),
        trailing: IconButton(
          tooltip: 'Quitar foto',
          icon: const Icon(Icons.delete_outline),
          onPressed: onQuitar,
        ),
      ),
    );
  }
}

class _DescripcionForm extends StatefulWidget {
  const _DescripcionForm({required this.inicial});

  final String inicial;

  @override
  State<_DescripcionForm> createState() => _DescripcionFormState();
}

class _DescripcionFormState extends State<_DescripcionForm> {
  late final _texto = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Describe el problema',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _texto,
                autofocus: true,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej. Extintor sin carga junto a la salida',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_texto.text),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
