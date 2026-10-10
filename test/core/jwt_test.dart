import 'package:app_movil_uubr/core/network/jwt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';

void main() {
  group('Jwt', () {
    test('lee la expiración del token', () {
      final exp = DateTime.now().add(const Duration(minutes: 5));
      final leida = Jwt.expiracion(jwtConExp(exp));
      expect(leida!.difference(exp).inSeconds.abs(), lessThan(2));
    });

    test('un token ilegible no tiene expiración y no se considera vencido', () {
      expect(Jwt.expiracion('basura'), isNull);
      expect(Jwt.venceProntoOYa('basura'), isFalse);
    });

    test('detecta token vencido y token por vencer', () {
      expect(Jwt.venceProntoOYa(jwtVencido()), isTrue);
      final enDiezSegundos = jwtConExp(
        DateTime.now().add(const Duration(seconds: 10)),
      );
      expect(Jwt.venceProntoOYa(enDiezSegundos), isTrue);
    });

    test('un token con margen suficiente no se renueva', () {
      expect(Jwt.venceProntoOYa(jwtVigente()), isFalse);
    });
  });
}
