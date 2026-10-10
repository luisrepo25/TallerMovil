import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Servidor falso: cada petición la responde [handler]. Guarda las peticiones recibidas
/// para poder contar y verificar cabeceras.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> peticiones = [];

  int cuantas(String fragmentoDeRuta) =>
      peticiones.where((p) => p.path.contains(fragmentoDeRuta)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    peticiones.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object cuerpo, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(cuerpo),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Simula que no hay red (el adaptador falla antes de obtener respuesta).
DioException sinRed(RequestOptions options) => DioException(
  requestOptions: options,
  type: DioExceptionType.connectionError,
);

/// JWT de prueba con el `exp` indicado (la firma no se valida en la app).
String jwtConExp(DateTime exp) {
  String codificar(Map<String, Object> datos) =>
      base64Url.encode(utf8.encode(jsonEncode(datos))).replaceAll('=', '');
  final exp1000 = exp.millisecondsSinceEpoch ~/ 1000;
  return '${codificar({'alg': 'HS256'})}.${codificar({'exp': exp1000})}.firma';
}

String jwtVigente() =>
    jwtConExp(DateTime.now().add(const Duration(minutes: 5)));
String jwtVencido() =>
    jwtConExp(DateTime.now().subtract(const Duration(minutes: 1)));
