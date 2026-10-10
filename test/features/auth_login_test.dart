import 'package:app_movil_uubr/features/auth/domain/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_setup.dart';
import '../helpers/fake_adapter.dart';
import '../helpers/memory_session_storage.dart';

void main() {
  late MemorySessionStorage storage;

  setUp(() => storage = MemorySessionStorage());

  Matcher fallaDeTipo(AuthFailureTipo tipo) =>
      isA<AuthFailure>().having((f) => f.tipo, 'tipo', tipo);

  group('iniciarSesion', () {
    test(
      'un Inspector inicia sesión y queda guardado (tokens y usuario)',
      () async {
        final repo = crearRepositorio(
          storage,
          servidorConPerfil(['inspector_tecnico']),
        );

        final usuario = await repo.iniciarSesion(
          email: 'ana@uubr.org.bo',
          password: 'x',
        );

        expect(usuario.nombreCompleto, 'Ana Pérez');
        expect(usuario.esInspector, isTrue);
        expect(await storage.readRefreshToken(), 'refresh-1');
        expect(await storage.readUsuarioJson(), isNotNull);
      },
    );

    test(
      'una cuenta que no es Inspector se rechaza y no deja nada guardado',
      () async {
        final repo = crearRepositorio(
          storage,
          servidorConPerfil(['administrador']),
        );

        await expectLater(
          repo.iniciarSesion(email: 'a@a.com', password: 'x'),
          throwsA(fallaDeTipo(AuthFailureTipo.noEsInspector)),
        );
        expect(await storage.readAccessToken(), isNull);
        expect(await storage.readRefreshToken(), isNull);
      },
    );

    test(
      'un Oficial que además es Inspector sí puede entrar (subtipos solapados)',
      () async {
        final repo = crearRepositorio(
          storage,
          servidorConPerfil(['oficial_mando', 'inspector_tecnico']),
        );

        final usuario = await repo.iniciarSesion(
          email: 'a@a.com',
          password: 'x',
        );

        expect(usuario.esInspector, isTrue);
      },
    );

    test('credenciales incorrectas', () async {
      final repo = crearRepositorio(
        storage,
        FakeAdapter((o) async => jsonResponse({'detail': 'x'}, status: 401)),
      );

      await expectLater(
        repo.iniciarSesion(email: 'a@a.com', password: 'mala'),
        throwsA(fallaDeTipo(AuthFailureTipo.credencialesInvalidas)),
      );
    });

    test(
      'sin conexión se explica que el primer inicio necesita internet',
      () async {
        final repo = crearRepositorio(
          storage,
          FakeAdapter((o) async => throw sinRed(o)),
        );

        await expectLater(
          repo.iniciarSesion(email: 'a@a.com', password: 'x'),
          throwsA(fallaDeTipo(AuthFailureTipo.sinConexion)),
        );
      },
    );
  });
}
