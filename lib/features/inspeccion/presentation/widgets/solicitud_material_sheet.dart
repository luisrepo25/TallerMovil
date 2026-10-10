import 'package:flutter/material.dart';

import '../inspeccion_controller.dart';

/// Hoja inferior para pedirle al administrador un material que no está en el catálogo.
/// El inspector solo dice cuál es: el poder calorífico y la peligrosidad los define el
/// administrador según la norma, así que la carga de fuego sigue siendo comparable.
Future<void> mostrarSolicitudMaterialSheet(
  BuildContext context,
  InspeccionController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _SolicitudForm(
        onGuardar: (nombre, descripcion, peso) => controller.solicitarMaterial(
          nombre: nombre,
          descripcion: descripcion,
          pesoKgEstimado: peso,
        ),
      ),
    ),
  );
}

class _SolicitudForm extends StatefulWidget {
  const _SolicitudForm({required this.onGuardar});

  final Future<void> Function(String nombre, String descripcion, double? peso)
  onGuardar;

  @override
  State<_SolicitudForm> createState() => _SolicitudFormState();
}

class _SolicitudFormState extends State<_SolicitudForm> {
  static const _pesoMaximo = 999999.99; // la columna es NUMERIC(8,2)

  final _clave = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _peso = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _peso.dispose();
    super.dispose();
  }

  double? _leerPeso(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  String? _validarPeso(String? texto) {
    if (texto == null || texto.trim().isEmpty) return null; // es opcional
    final peso = _leerPeso(texto);
    if (peso == null) return 'Escribe un número';
    if (peso <= 0) return 'Debe ser mayor que cero';
    if (peso > _pesoMaximo) return 'Es demasiado grande';
    return null;
  }

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    await widget.onGuardar(
      _nombre.text,
      _descripcion.text,
      _leerPeso(_peso.text),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _clave,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Solicitar material nuevo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'El administrador lo revisará y lo agregará al catálogo. Mientras '
                'tanto no se suma a la carga de fuego de esta acta.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombre,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nombre del material',
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Escribe el nombre del material'
                    : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descripcion,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Dónde está y cómo se almacena',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _peso,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Peso aproximado (opcional)',
                  suffixText: 'kg',
                ),
                validator: _validarPeso,
                onFieldSubmitted: (_) => _guardar(),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _guardar, child: const Text('Solicitar')),
            ],
          ),
        ),
      ),
    );
  }
}
