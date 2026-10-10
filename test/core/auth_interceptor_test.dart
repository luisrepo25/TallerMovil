import 'package:app_movil_uubr/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/memory_session_storage.dart';

void main() {
  late MemorySessionStorage storage;
  late String tokenNuevo;
  int sesionesExpiradas = 0;

  setUp(() {
    storage = MemorySessionStorage()..refresh = 'refresh-valido';
    // Distinto del "vigente" (+5 min) de otros tokens de la prueba: si fueran iguales el
    // servidor aceptaría el viejo y no se ejercitaría el reintento.
    tokenNuevo = jwtConExp(DateTime.now().add(const Duration(minutes: 10)));
    sesionesExpiradas = 0;
  });

  ApiClient crearCliente(FakeAdapter adapter) => ApiClient(
    storage: storage,
    baseUrl: 'http://servidor.test',
    adapter: adapter,
    onSesionExpirada: () => sesionesExpiradas++,
  );

  // Servidor que acepta solo el token nuevo y renueva con el refresh válido
  FakeAdapter servidorNormal() => FakeAdapter((o) async {
    if (o.path.contains('refresh')) return jsonResponse({'access': tokenNuevo});
    final autorizado = o.headers['Authorization'] == 'Bearer $tokenNuevo';
    return autorizado
        ? jsonResponse({'ok': true})
        : jsonResponse({'detail': 'x'}, status: 401);
  });

  test(
    'renueva de antemano un token vencido, antes de enviar (sin 401 visible)',
    () async {
      storage.access = jwtVencido();
      final adapter = servidorNormal();

      final respuesta = await crearCliente(
        adapter,
      ).dio.get<Map<String, dynamic>>('/api/algo/');

      expect(respuesta.data!['ok'], isTrue);
      expect(adapter.cuantas('refresh'), 1);
      expect(
        adapter.cuantas('/api/algo/'),
        1,
        reason: 'no hubo un primer intento con 401',
      );
      expect(await storage.readAccessToken(), tokenNuevo);
    },
  );

  test('varias peticiones simultáneas comparten UNA sola renovación', () async {
    storage.access = jwtVencido();
    final adapter = servidorNormal();
    final dio = crearCliente(adapter).dio;

    await Future.wait([
      dio.get<dynamic>('/api/a/'),
      dio.get<dynamic>('/api/b/'),
      dio.get<dynamic>('/api/c/'),
    ]);

    expect(adapter.cuantas('refresh'), 1);
  });

  test(
    'si llega un 401 con token aparentemente vigente, renueva y reintenta una vez',
    () async {
      storage.access =
          jwtVigente(); // vigente para el reloj, pero el servidor no lo acepta
      final adapter = servidorNormal();

      final respuesta = await crearCliente(
        adapter,
      ).dio.get<Map<String, dynamic>>('/api/algo/');

      expect(respuesta.data!['ok'], isTrue);
      expect(adapter.cuantas('/api/algo/'), 2);
      expect(adapter.cuantas('refresh'), 1);
    },
  );

  test('si el refresh también falla, avisa que la sesión expiró', () async {
    storage.access = jwtVencido();
    final adapter = FakeAdapter(
      (o) async => jsonResponse({'detail': 'x'}, status: 401),
    );

    await expectLater(
      crearCliente(adapter).dio.get<dynamic>('/api/algo/'),
      throwsA(isA<DioException>()),
    );

    expect(sesionesExpiradas, 1);
  });

  test('sin red no se declara la sesión como expirada', () async {
    storage.access = jwtVencido();
    final adapter = FakeAdapter((o) async => throw sinRed(o));

    await expectLater(
      crearCliente(adapter).dio.get<dynamic>('/api/algo/'),
      throwsA(isA<DioException>()),
    );

    expect(sesionesExpiradas, 0);
  });

  test('el login no lleva token ni intenta renovar', () async {
    storage.access = jwtVencido();
    final adapter = FakeAdapter(
      (o) async => jsonResponse({'access': 'a', 'refresh': 'r'}),
    );

    await crearCliente(adapter).dio.post<dynamic>(ApiRutas.login, data: {});

    expect(adapter.cuantas('refresh'), 0);
    expect(
      adapter.peticiones.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });
}
