import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/acta_local.dart';

/// Una foto del acta con su descripción: tocar para describirla, el ícono para quitarla.
class FilaFoto extends StatelessWidget {
  const FilaFoto({
    super.key,
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
