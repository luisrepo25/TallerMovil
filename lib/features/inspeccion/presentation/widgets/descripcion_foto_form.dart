import 'package:flutter/material.dart';

/// Hoja inferior para describir el problema que muestra una foto (opcional).
class DescripcionFotoForm extends StatefulWidget {
  const DescripcionFotoForm({super.key, required this.inicial});

  final String inicial;

  @override
  State<DescripcionFotoForm> createState() => DescripcionFotoFormState();
}

class DescripcionFotoFormState extends State<DescripcionFotoForm> {
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
