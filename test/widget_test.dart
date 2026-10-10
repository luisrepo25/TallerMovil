import 'package:app_movil_uubr/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/memory_session_storage.dart';

/// La superficie por defecto de las pruebas es una ventana ancha y baja; la app es
/// para teléfonos en vertical, así que se prueba con un tamaño de teléfono real.
Future<void> abrirApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MyApp(storage: MemorySessionStorage()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin sesión guardada, la app abre en el onboarding', (
    tester,
  ) async {
    await abrirApp(tester);

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
  });

  testWidgets('"Saltar" lleva al login, que pide email y contraseña', (
    tester,
  ) async {
    await abrirApp(tester);

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });

  testWidgets('el login valida los campos vacíos sin llamar al servidor', (
    tester,
  ) async {
    await abrirApp(tester);
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu email'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });
}
