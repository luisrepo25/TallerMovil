import 'package:app_movil_uubr/core/geo/geo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/datos_descarga.dart';

List<List<double>> anillo(double lng, double lat, double lado) =>
    Geo.anilloDeGeoJson(cuadrado(lng, lat, lado));

void main() {
  group('Geo', () {
    test('GeoJSON usa [lng, lat]; la app trabaja con [lat, lng]', () {
      final a = anillo(-63.19, -17.79, 0.01);

      expect(a.first, [-17.79, -63.19]);
      expect(a.length, 5, reason: 'el anillo viene cerrado');
    });

    test('un predio dentro de la zona intersecta', () {
      expect(
        Geo.poligonosSeIntersectan(
          anillo(-63.185, -17.785, 0.001),
          anillo(-63.19, -17.79, 0.01),
        ),
        isTrue,
      );
    });

    test(
      'una zona que contiene al predio intersecta aunque no compartan vértices',
      () {
        expect(
          Geo.poligonosSeIntersectan(
            anillo(-63.19, -17.79, 0.01),
            anillo(-63.185, -17.785, 0.001),
          ),
          isTrue,
        );
      },
    );

    test('un predio que cruza el borde de la zona intersecta', () {
      expect(
        Geo.poligonosSeIntersectan(
          anillo(-63.1805, -17.785, 0.002),
          anillo(-63.19, -17.79, 0.01),
        ),
        isTrue,
      );
    });

    test(
      'dos cuadrados que se cruzan en cruz (sin vértices dentro) intersectan',
      () {
        final horizontal = [
          [0.0, 0.0],
          [0.0, 10.0],
          [1.0, 10.0],
          [1.0, 0.0],
        ];
        final vertical = [
          [-5.0, 4.0],
          [-5.0, 5.0],
          [5.0, 5.0],
          [5.0, 4.0],
        ];

        expect(Geo.poligonosSeIntersectan(horizontal, vertical), isTrue);
      },
    );

    test('un predio lejano no intersecta', () {
      expect(
        Geo.poligonosSeIntersectan(
          anillo(-63.10, -17.70, 0.001),
          anillo(-63.19, -17.79, 0.01),
        ),
        isFalse,
      );
    });
  });
}
