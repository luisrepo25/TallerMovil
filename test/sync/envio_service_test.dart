import 'dart:io';

import 'package:app_movil_uubr/core/network/api_client.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_edicion.dart';
import 'package:app_movil_uubr/features/inspeccion/domain/acta_local.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_descarga.dart';
import '../helpers/fake_adapter.dart';
import '../helpers/inspeccion_en_memoria.dart';

void main() {
  late ActasEnMemoria almacen;
  late Directory carpeta;

  setUp(() {
    almacen = ActasEnMemoria();
    carpeta = Directory.systemTemp.createTempSync('envio_test');
  });
  tearDown(() => carpeta.deleteSync(recursive: true));

  /// Acta cerrada en el teléfono, lista para enviar.
  ActaLocal cerrada(String uuid, {int hora = 10, int predio = 10}) => ActaLocal(
    uuidLocal: uuid,
    predioId: predio,
    campaniaId: 1,
    fechaInspeccion: DateTime.utc(2026, 10, 9, hora),
    estadoExtintoresId: 1,
    estado: EstadoActa.cerradaLocal,
  );

  Future<ActaLocal> guardar(ActaLocal a) async {
    await almacen.guardar(a);
    return a;
  }

  String foto(String nombre) {
    final archivo = File('${carpeta.path}/$nombre')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
    return archivo.path;
  }

  ResponseBody aceptada(RequestOptions o, {String estado = 'sincronizada'}) {
    final uuid = ((o.data as Map)['actas'] as List).first['uuid_local'];
    return jsonResponse({
      'resultados': [
        {
          'uuid_local': uuid,
          'estado': estado,
          'acta_id': 77,
          'carga_fuego': '83.61', // DRF serializa los decimales como texto
          'scoring_riesgo': '41.50',
          'cluster_riesgo': 'Medio',
        },
      ],
    });
  }

  List<String> uuidsEnviados(FakeAdapter a) => [
    for (final p in a.peticiones.where(
      (p) => p.path == ApiRutas.sincronizarActas,
    ))
      ((p.data as Map)['actas'] as List).first['uuid_local'] as String,
  ];

  test(
    'envía las actas de la más antigua a la más nueva y guarda lo que calculó el '
    'servidor',
    () async {
      await guardar(cerrada('nueva', hora: 15));
      await guardar(cerrada('vieja', hora: 8));
      final servidor = FakeAdapter((o) async => aceptada(o));

      final r = await crearEnvio(almacen, servidor).enviarPendientes();

      expect(uuidsEnviados(servidor), ['vieja', 'nueva']);
      expect(r.enviadas, 2);
      expect(r.aviso, isNull);
      final enviada = almacen.actas['vieja']!;
      expect(enviada.estado, EstadoActa.sincronizada);
      expect(enviada.actaIdServidor, 77);
      expect(enviada.cargaFuego, 83.61);
      expect(enviada.scoringRiesgo, 41.5);
      expect(enviada.clusterRiesgo, 'Medio');
    },
  );

  test('un borrador y un acta ya enviada no se mandan', () async {
    await guardar(cerrada('lista'));
    await guardar(cerrada('borrador').copyWith(estado: EstadoActa.borrador));
    final servidor = FakeAdapter((o) async => aceptada(o));

    await crearEnvio(almacen, servidor).enviarPendientes();
    final segunda = await crearEnvio(almacen, servidor).enviarPendientes();

    expect(uuidsEnviados(servidor), ['lista'], reason: 'solo una vez');
    expect(segunda.enviadas, 0);
    expect(almacen.actas['borrador']!.estado, EstadoActa.borrador);
  });

  test(
    'sin conexión no se pierde nada: el acta sigue lista y se avisa',
    () async {
      await guardar(cerrada('a1'));
      final servidor = FakeAdapter((o) async => throw sinRed(o));

      final r = await crearEnvio(almacen, servidor).enviarPendientes();

      expect(r.sinConexion, isTrue);
      expect(r.pendientes, 1);
      expect(r.aviso, contains('Sin conexión'));
      expect(almacen.actas['a1']!.estado, EstadoActa.cerradaLocal);
    },
  );

  test(
    'si una acta no sale, no se salta a las siguientes (el orden importa para '
    'la reincidencia)',
    () async {
      await guardar(cerrada('primera', hora: 8));
      await guardar(cerrada('segunda', hora: 9));
      final servidor = FakeAdapter((o) async => throw sinRed(o));

      final r = await crearEnvio(almacen, servidor).enviarPendientes();

      expect(uuidsEnviados(servidor), ['primera'], reason: 'se detuvo ahí');
      expect(r.pendientes, 2);
    },
  );

  test('error del servidor: queda pendiente para reintentar', () async {
    await guardar(cerrada('a1'));
    final servidor = FakeAdapter(
      (o) async => jsonResponse({'detail': 'x'}, status: 500),
    );

    final r = await crearEnvio(almacen, servidor).enviarPendientes();

    expect(r.pendientes, 1);
    expect(r.sinConexion, isFalse);
    expect(almacen.actas['a1']!.estado, EstadoActa.cerradaLocal);
  });

  test('el servidor la rechaza: se conserva con el motivo y se sigue con las '
      'demás', () async {
    await guardar(cerrada('mala', hora: 8));
    await guardar(cerrada('buena', hora: 9));
    final servidor = FakeAdapter((o) async {
      final uuid = ((o.data as Map)['actas'] as List).first['uuid_local'];
      if (uuid == 'mala') {
        return jsonResponse({
          'resultados': [
            {
              'uuid_local': 'mala',
              'estado': 'rechazada',
              'codigo': 'conflicto',
              'detalle':
                  'No se pueden registrar actas en una campania cerrada.',
            },
          ],
        });
      }
      return aceptada(o);
    });

    final r = await crearEnvio(almacen, servidor).enviarPendientes();

    expect(r.rechazadas, 1);
    expect(r.enviadas, 1);
    final mala = almacen.actas['mala']!;
    expect(mala.estado, EstadoActa.rechazada);
    expect(mala.motivoRechazo, contains('campania cerrada'));
    expect(almacen.actas['buena']!.estado, EstadoActa.sincronizada);
  });

  group('fotos', () {
    ResponseBody respuestaFoto(RequestOptions o, FakeAdapter a) => jsonResponse(
      {'url_imagen': 'https://res.cloudinary.com/x/${a.cuantas('subir')}.jpg'},
      status: 201,
    );

    test(
      'se suben antes del acta y viajan como URL, con su descripción',
      () async {
        final f1 = foto('a.jpg');
        final f2 = foto('b.jpg');
        await guardar(
          cerrada('a1').conEvidencia(f1, 'Humedad').conEvidencia(f2, ''),
        );
        late FakeAdapter servidor;
        servidor = FakeAdapter((o) async {
          if (o.path == ApiRutas.subirEvidencia) {
            return respuestaFoto(o, servidor);
          }
          return aceptada(o);
        });

        await crearEnvio(almacen, servidor).enviarPendientes();

        final rutas = servidor.peticiones.map((p) => p.path).toList();
        expect(rutas, [
          ApiRutas.subirEvidencia,
          ApiRutas.subirEvidencia,
          ApiRutas.sincronizarActas,
        ]);
        final acta = servidor.peticiones.last.data as Map;
        final evidencias = (acta['actas'] as List).first['evidencias'] as List;
        expect(evidencias, [
          {
            'url_imagen': 'https://res.cloudinary.com/x/1.jpg',
            'descripcion_infraccion': 'Humedad',
          },
          {
            'url_imagen': 'https://res.cloudinary.com/x/2.jpg',
            'descripcion_infraccion': '',
          },
        ]);
      },
    );

    test('la foto se manda como archivo (multipart), no como JSON', () async {
      await guardar(cerrada('a1').conEvidencia(foto('a.jpg'), ''));
      late FakeAdapter servidor;
      servidor = FakeAdapter((o) async {
        if (o.path == ApiRutas.subirEvidencia) {
          return respuestaFoto(o, servidor);
        }
        return aceptada(o);
      });

      await crearEnvio(almacen, servidor).enviarPendientes();

      final subida = servidor.peticiones.first;
      expect(subida.data, isA<FormData>());
      expect(
        subida.headers['Content-Type'].toString(),
        contains('multipart/form-data'),
      );
    });

    test(
      'si el envío se corta después de subir, la foto no se vuelve a subir',
      () async {
        await guardar(cerrada('a1').conEvidencia(foto('a.jpg'), ''));
        var redCaida = true;
        late FakeAdapter servidor;
        servidor = FakeAdapter((o) async {
          if (o.path == ApiRutas.subirEvidencia) {
            return respuestaFoto(o, servidor);
          }
          if (redCaida) throw sinRed(o);
          return aceptada(o);
        });
        final envio = crearEnvio(almacen, servidor);

        await envio
            .enviarPendientes(); // sube la foto y se cae al mandar el acta
        redCaida = false;
        final r = await envio.enviarPendientes();

        expect(servidor.cuantas('subir'), 1, reason: 'no se duplicó la subida');
        expect(r.enviadas, 1);
        expect(almacen.actas['a1']!.evidencias.single.urlRemota, isNotNull);
      },
    );

    test(
      'una foto borrada del teléfono no frena el acta: viaja sin ella',
      () async {
        await guardar(
          cerrada('a1').conEvidencia('${carpeta.path}/no_existe.jpg', ''),
        );
        final servidor = FakeAdapter((o) async => aceptada(o));

        final r = await crearEnvio(almacen, servidor).enviarPendientes();

        expect(r.enviadas, 1);
        expect(r.fotosOmitidas, 1);
        expect(servidor.cuantas('subir'), 0);
      },
    );

    test(
      'el servidor dice que la imagen no vale (400): se omite y el acta sigue',
      () async {
        await guardar(cerrada('a1').conEvidencia(foto('a.jpg'), ''));
        final servidor = FakeAdapter((o) async {
          if (o.path == ApiRutas.subirEvidencia) {
            return jsonResponse({'detail': 'no es imagen'}, status: 400);
          }
          return aceptada(o);
        });

        final r = await crearEnvio(almacen, servidor).enviarPendientes();

        expect(r.enviadas, 1);
        expect(r.fotosOmitidas, 1);
      },
    );
  });

  group('solicitudes de material', () {
    ActaLocal conSolicitud() => cerrada('a1').conSolicitudMaterial(
      const SolicitudMaterialActa(
        uuidLocal: 'sol-1',
        nombre: 'Espuma',
        pesoKgEstimado: 40.5,
      ),
    );

    test(
      'se piden al administrador con su uuid antes de mandar el acta',
      () async {
        await guardar(conSolicitud());
        final servidor = FakeAdapter((o) async {
          if (o.path == ApiRutas.solicitudesMaterial) {
            return jsonResponse({'id': 1}, status: 201);
          }
          return aceptada(o);
        });

        await crearEnvio(almacen, servidor).enviarPendientes();

        expect(servidor.peticiones.first.path, ApiRutas.solicitudesMaterial);
        expect(servidor.peticiones.first.data, {
          'uuid_local': 'sol-1',
          'nombre': 'Espuma',
          'peso_kg_estimado': '40.50',
        });
        expect(almacen.actas['a1']!.estado, EstadoActa.sincronizada);
      },
    );

    test('si ya existe o ya está pedida (409) no frena el acta', () async {
      await guardar(conSolicitud());
      final servidor = FakeAdapter((o) async {
        if (o.path == ApiRutas.solicitudesMaterial) {
          return jsonResponse({'detail': 'ya existe'}, status: 409);
        }
        return aceptada(o);
      });

      final r = await crearEnvio(almacen, servidor).enviarPendientes();

      expect(r.enviadas, 1);
    });

    test(
      'sin red, ni la solicitud ni el acta salen: se reintenta todo junto',
      () async {
        await guardar(conSolicitud());
        final servidor = FakeAdapter((o) async => throw sinRed(o));

        final r = await crearEnvio(almacen, servidor).enviarPendientes();

        expect(r.pendientes, 1);
        expect(almacen.actas['a1']!.estado, EstadoActa.cerradaLocal);
      },
    );
  });

  test('no corren dos envíos a la vez', () async {
    await guardar(cerrada('a1'));
    final servidor = FakeAdapter((o) async => aceptada(o));
    final envio = crearEnvio(almacen, servidor);

    final primero = envio.enviarPendientes();
    final segundo = await envio.enviarPendientes();
    await primero;

    expect(segundo.enviadas, 0);
    expect(uuidsEnviados(servidor), ['a1'], reason: 'solo una vez');
  });
}
