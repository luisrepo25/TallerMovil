import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_setup.dart';
import '../helpers/fake_adapter.dart';
import '../helpers/memory_session_storage.dart';

void main() {
  late MemorySessionStorage storage;

  setUp(() => storage = MemorySessionStorage());

  group('restaurarSesion', () {
    test('sin tokens guardados no hay sesión', () async {
      final repo = crearRepositorio(
        storage,
        servidorConPerfil(['inspector_tecnico']),
      );

      expect(await repo.restaurarSesion(), isNull);
    });

    test(
      'con red, valida contra el servidor y refresca el usuario guardado',
      () async {
        storage
          ..access = jwtVigente()
          ..refresh = 'refresh-1';
        final repo = crearRepositorio(
          storage,
          servidorConPerfil(['inspector_tecnico']),
        );

        final usuario = await repo.restaurarSesion();

        expect(usuario!.email, 'ana@uubr.org.bo');
        expect(await storage.readUsuarioJson(), isNotNull);
      },
    );

    test(
      'SIN CONEXIÓN abre con el último usuario conocido (offline-first)',
      () async {
        final conRed = crearRepositorio(
          storage,
          servidorConPerfil(['inspector_tecnico']),
        );
        await conRed.iniciarSesion(email: 'ana@uubr.org.bo', password: 'x');

        final sinRedRepo = crearRepositorio(
          storage,
          FakeAdapter((o) async => throw sinRed(o)),
        );
        final usuario = await sinRedRepo.restaurarSesion();

        expect(usuario!.nombreCompleto, 'Ana Pérez');
        expect(
          await storage.readRefreshToken(),
          isNotNull,
          reason: 'la sesión se conserva',
        );
      },
    );

    test(
      'si el servidor confirma que la sesión ya no vale, se limpia',
      () async {
        storage
          ..access = jwtVencido()
          ..refresh = 'refresh-vencido'
          ..usuarioJson = '{}';
        final repo = crearRepositorio(
          storage,
          FakeAdapter((o) async => jsonResponse({'detail': 'x'}, status: 401)),
        );

        expect(await repo.restaurarSesion(), isNull);
        expect(await storage.readRefreshToken(), isNull);
      },
    );
  });

  test('cerrarSesion borra tokens y usuario', () async {
    storage
      ..access = 'a'
      ..refresh = 'r'
      ..usuarioJson = '{}';

    await crearRepositorio(
      storage,
      servidorConPerfil(['inspector_tecnico']),
    ).cerrarSesion();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readUsuarioJson(), isNull);
  });
}
