import 'package:flutter/material.dart';

/// Explica, antes del diálogo de Android/iOS, para qué usa la app la ubicación.
/// Devuelve true si el usuario quiere continuar y false si prefiere no darla ahora.
Future<bool> explicarUbicacion(BuildContext context) async {
  // Se espera a que la pantalla esté dibujada: el aviso puede pedirse desde initState.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return false;

  final continuar = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogo) => AlertDialog(
      icon: const Icon(Icons.my_location),
      title: const Text('Permiso de ubicación'),
      content: const Text(
        'UUBR usa tu ubicación solo mientras ves el mapa de la campaña, para '
        'decirte si estás dentro de la zona de inspección.\n\n'
        'Tu ubicación no se guarda ni se envía al servidor. Puedes cambiar este '
        'permiso cuando quieras desde los ajustes del teléfono.',
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(dialogo).pop(false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(dialogo).pop(true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
  return continuar ?? false;
}
