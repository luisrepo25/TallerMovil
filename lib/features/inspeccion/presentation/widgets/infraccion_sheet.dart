import 'package:flutter/material.dart';

import '../../domain/acta_local.dart';
import '../../domain/catalogos.dart';
import '../inspeccion_controller.dart';

/// Hoja inferior para registrar una infracción o editar su descripción.
/// `editar` != null: el tipo no se puede cambiar, solo la descripción.
Future<void> mostrarInfraccionSheet(
  BuildContext context,
  InspeccionController controller, {
  InfraccionActa? editar,
}) {
  final usadas = controller.acta!.infracciones
      .map((i) => i.tipoInfraccionId)
      .toSet();
  final disponibles = controller.catalogos!.infracciones
      .where(
        (t) => editar != null
            ? t.id == editar.tipoInfraccionId
            : !usadas.contains(t.id),
      )
      .toList();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _InfraccionForm(
        tipos: disponibles,
        descripcionInicial: editar?.descripcion,
        editando: editar != null,
        onGuardar: (tipoId, descripcion) =>
            controller.guardarInfraccion(tipoId, descripcion),
      ),
    ),
  );
}

class _InfraccionForm extends StatefulWidget {
  const _InfraccionForm({
    required this.tipos,
    required this.onGuardar,
    required this.editando,
    this.descripcionInicial,
  });

  final List<TipoInfraccion> tipos;
  final String? descripcionInicial;
  final bool editando;
  final Future<void> Function(int tipoId, String descripcion) onGuardar;

  @override
  State<_InfraccionForm> createState() => _InfraccionFormState();
}

class _InfraccionFormState extends State<_InfraccionForm> {
  final _clave = GlobalKey<FormState>();
  late final _descripcion = TextEditingController(
    text: widget.descripcionInicial ?? '',
  );
  late int? _tipoId = widget.tipos.length == 1 ? widget.tipos.first.id : null;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    await widget.onGuardar(_tipoId!, _descripcion.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _clave,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.editando ? 'Editar infracción' : 'Registrar infracción',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _tipoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Infracción'),
                items: [
                  for (final t in widget.tipos)
                    DropdownMenuItem(value: t.id, child: Text(t.nombre)),
                ],
                onChanged: widget.editando
                    ? null
                    : (v) => setState(() => _tipoId = v),
                validator: (v) => v == null ? 'Elige una infracción' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descripcion,
                maxLength: 200,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Detalle (opcional)',
                  hintText: 'Ej. Extintor del pasillo con la carga vencida',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
