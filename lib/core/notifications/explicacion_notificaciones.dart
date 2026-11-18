import 'package:flutter/material.dart';

/// Explica, antes del diálogo de Android/iOS, para qué usa la app las notificaciones.
/// Devuelve true si el usuario quiere continuar y false si prefiere no recibirlas ahora.
Future<bool> explicarNotificaciones(BuildContext context) async {
  // Se espera a que la pantalla esté dibujada: el aviso puede pedirse desde initState.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return false;

  final continuar = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogo) => AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: const Text('Avisos de campañas'),
      content: const Text(
        'UUBR te avisa cuando el administrador te asigna una campaña, para que la '
        'tengas lista en tu teléfono aunque no tengas la app abierta.\n\n'
        'Solo recibirás avisos de trabajo. Puedes cambiar este permiso cuando quieras '
        'desde los ajustes del teléfono.',
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
