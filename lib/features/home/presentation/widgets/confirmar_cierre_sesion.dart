import 'package:flutter/material.dart';

/// Pregunta antes de cerrar sesión cuando hay actas que todavía no llegaron al servidor:
/// cerrar sesión borra los datos del teléfono y esas actas se perderían.
/// Devuelve `true` si el inspector confirma que quiere cerrar sesión y descartarlas.
Future<bool> confirmarCierreConPendientes(
  BuildContext context,
  int pendientes,
) async {
  final confirmo = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, size: 36),
      title: Text(
        pendientes == 1
            ? 'Tienes 1 acta sin enviar'
            : 'Tienes $pendientes actas sin enviar',
      ),
      content: const Text(
        'Si cierras sesión ahora se borrarán de este teléfono y no podrás recuperarlas. '
        'Conéctate a internet para enviarlas antes de salir.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            minimumSize: const Size(0, 44),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cerrar sesión y borrar'),
        ),
      ],
    ),
  );
  return confirmo ?? false;
}
