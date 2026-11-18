import 'package:app_movil_uubr/core/notifications/notificaciones_controller.dart';
import 'package:app_movil_uubr/core/notifications/notificaciones_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/notificaciones_falsas.dart';

Future<void> esperar() => Future<void>.delayed(Duration.zero);

void main() {
  late NotificacionesFalsas firebase;
  late DispositivosFalsos servidor;
  late NotificacionesController controlador;
  late List<AvisoPush> recibidos;
  var explicaciones = 0;
  var respuesta = true;

  Future<void> iniciar() => controlador.iniciar(
    alExplicar: () async {
      explicaciones++;
      return respuesta;
    },
    alRecibir: recibidos.add,
  );

  setUp(() {
    firebase = NotificacionesFalsas();
    servidor = DispositivosFalsos();
    controlador = NotificacionesController(
      servicio: firebase,
      dispositivos: servidor,
    );
    recibidos = [];
    explicaciones = 0;
    respuesta = true;
  });

  tearDown(() => controlador.detener());

  group('permiso y registro del teléfono', () {
    test(
      'con el permiso ya dado registra el token sin volver a preguntar',
      () async {
        await iniciar();

        expect(servidor.registrados, ['token-1']);
        expect(explicaciones, 0);
        expect(firebase.pidioPermiso, isFalse);
      },
    );

    test(
      'si falta el permiso, primero explica y luego lo pide al sistema',
      () async {
        firebase.estado = PermisoNotificaciones.porPreguntar;

        await iniciar();

        expect(explicaciones, 1);
        expect(firebase.pidioPermiso, isTrue);
        expect(servidor.registrados, ['token-1']);
      },
    );

    test('"Ahora no": no pide el permiso ni registra nada', () async {
      firebase.estado = PermisoNotificaciones.porPreguntar;
      respuesta = false;

      await iniciar();

      expect(firebase.pidioPermiso, isFalse);
      expect(servidor.registrados, isEmpty);
    });

    test(
      'con "Ahora no" se le vuelve a ofrecer al abrir la app otra vez',
      () async {
        firebase.estado = PermisoNotificaciones.porPreguntar;
        respuesta = false;
        await iniciar();

        respuesta = true;
        await iniciar();

        expect(explicaciones, 2);
        expect(servidor.registrados, ['token-1']);
      },
    );

    test(
      'si el permiso fue denegado en el sistema no insiste ni registra',
      () async {
        firebase.estado = PermisoNotificaciones.denegado;

        await iniciar();

        expect(explicaciones, 0);
        expect(firebase.pidioPermiso, isFalse);
        expect(servidor.registrados, isEmpty);
      },
    );

    test('sin conexión el registro se omite sin romper la app', () async {
      servidor.sinConexion = true;

      await expectLater(iniciar(), completes);

      expect(servidor.registrados, isEmpty);
    });

    test('cuando Firebase renueva el token, el nuevo se registra', () async {
      await iniciar();

      firebase.renovarToken('token-2');
      await esperar();

      expect(servidor.registrados, ['token-1', 'token-2']);
    });
  });

  group('avisos que llegan', () {
    const aviso = AvisoPush(
      titulo: 'Nueva campaña asignada',
      cuerpo: 'Zona Norte',
      datos: {'tipo': 'campania_asignada', 'campania_id': '7'},
    );

    test('con la app abierta llegan a quien los atiende', () async {
      await iniciar();

      firebase.llegaAvisoEnPrimerPlano(aviso);
      await esperar();

      expect(recibidos, [aviso]);
      expect(recibidos.single.esCampaniaAsignada, isTrue);
    });

    test(
      'al tocar el aviso con la app en segundo plano también llegan',
      () async {
        await iniciar();

        firebase.usuarioTocaAviso(aviso);
        await esperar();

        expect(recibidos, [aviso]);
      },
    );

    test('otros tipos de aviso no se confunden con una campaña asignada', () {
      expect(
        const AvisoPush(datos: {'tipo': 'otro'}).esCampaniaAsignada,
        isFalse,
      );
      expect(const AvisoPush().esCampaniaAsignada, isFalse);
    });

    test('al detener, deja de escuchar', () async {
      await iniciar();
      controlador.detener();

      firebase.llegaAvisoEnPrimerPlano(aviso);
      await esperar();

      expect(recibidos, isEmpty);
      expect(firebase.alguienEscucha, isFalse);
    });
  });

  group('cerrar sesión', () {
    test('da de baja el teléfono en el servidor y olvida el token', () async {
      await iniciar();

      await controlador.cerrarSesion();

      expect(servidor.quitados, ['token-1']);
      expect(firebase.tokensOlvidados, 1);
    });

    test(
      'sin conexión no falla: igual invalida el token en Firebase',
      () async {
        await iniciar();
        servidor.sinConexion = true;

        await expectLater(controlador.cerrarSesion(), completes);

        expect(servidor.quitados, isEmpty);
        expect(firebase.tokensOlvidados, 1);
      },
    );

    test('después de cerrar sesión ya no entregan avisos', () async {
      await iniciar();
      await controlador.cerrarSesion();

      firebase.llegaAvisoEnPrimerPlano(const AvisoPush(titulo: 'x'));
      await esperar();

      expect(recibidos, isEmpty);
    });
  });

  test('sin Firebase disponible la app sigue funcionando', () async {
    final sinFirebase = NotificacionesController(
      servicio: const NotificacionesNoDisponibles(),
      dispositivos: servidor,
    );

    await expectLater(
      sinFirebase.iniciar(alExplicar: () async => true, alRecibir: (_) {}),
      completes,
    );
    await expectLater(sinFirebase.cerrarSesion(), completes);
    expect(servidor.registrados, isEmpty);
  });
}
