import 'package:flutter/material.dart';

import '../../domain/acta_local.dart';
import '../../domain/catalogos.dart';
import '../inspeccion_controller.dart';

/// Hoja inferior para agregar un material combustible o editar su peso.
/// `editar` != null: el material no se puede cambiar, solo su peso.
Future<void> mostrarMaterialSheet(
  BuildContext context,
  InspeccionController controller, {
  MaterialActa? editar,
}) {
  final usados = controller.acta!.materiales.map((m) => m.materialId).toSet();
  final disponibles = controller.catalogos!.materiales
      .where(
        (m) =>
            editar != null ? m.id == editar.materialId : !usados.contains(m.id),
      )
      .toList();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _MaterialForm(
        materiales: disponibles,
        pesoInicial: editar?.pesoKg,
        onGuardar: (materialId, peso) =>
            controller.guardarMaterial(materialId, peso),
      ),
    ),
  );
}

class _MaterialForm extends StatefulWidget {
  const _MaterialForm({
    required this.materiales,
    required this.onGuardar,
    this.pesoInicial,
  });

  final List<MaterialCombustible> materiales;
  final double? pesoInicial;
  final Future<void> Function(int materialId, double peso) onGuardar;

  @override
  State<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<_MaterialForm> {
  static const _pesoMaximo = 999999.99; // la columna es NUMERIC(8,2)

  final _clave = GlobalKey<FormState>();
  late final _peso = TextEditingController(
    text: widget.pesoInicial == null ? '' : widget.pesoInicial!.toString(),
  );
  late int? _materialId = widget.materiales.length == 1
      ? widget.materiales.first.id
      : null;

  @override
  void dispose() {
    _peso.dispose();
    super.dispose();
  }

  double? _leerPeso(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  String? _validarPeso(String? texto) {
    final peso = _leerPeso(texto);
    if (peso == null) return 'Escribe el peso en kg';
    if (peso <= 0) return 'Debe ser mayor que cero';
    if (peso > _pesoMaximo) return 'Es demasiado grande';
    return null;
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    await widget.onGuardar(_materialId!, _leerPeso(_peso.text)!);
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
                widget.pesoInicial == null ? 'Agregar material' : 'Editar peso',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _materialId,
                decoration: const InputDecoration(labelText: 'Material'),
                items: [
                  for (final m in widget.materiales)
                    DropdownMenuItem(value: m.id, child: Text(m.nombre)),
                ],
                onChanged: widget.pesoInicial == null
                    ? (v) => setState(() => _materialId = v)
                    : null,
                validator: (v) => v == null ? 'Elige un material' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _peso,
                autofocus: widget.pesoInicial != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  suffixText: 'kg',
                ),
                validator: _validarPeso,
                onFieldSubmitted: (_) => _guardar(),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
