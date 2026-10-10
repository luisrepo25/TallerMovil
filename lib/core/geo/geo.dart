/// Utilidades geométricas simples. Los puntos son siempre `[lat, lng]` (Leaflet/mapas);
/// GeoJSON usa `[lng, lat]`, por eso [anilloDeGeoJson] los invierte.
///
/// La intersección es solo una **ayuda para el inspector** (qué predios caen en la zona
/// de su campaña). La validación real la hace el backend con ST_Intersects.
class Geo {
  Geo._();

  /// Anillo exterior de un `Polygon` GeoJSON, como lista de `[lat, lng]`.
  static List<List<double>> anilloDeGeoJson(Map<String, dynamic> geom) {
    final anillo = (geom['coordinates'] as List).first as List;
    return anillo
        .map<List<double>>(
          (c) => [(c[1] as num).toDouble(), (c[0] as num).toDouble()],
        )
        .toList();
  }

  /// Trazado de rayo: ¿el punto `[lat, lng]` está dentro del anillo?
  static bool puntoEnPoligono(List<double> punto, List<List<double>> anillo) {
    final lat = punto[0];
    final lng = punto[1];
    var dentro = false;
    for (var i = 0, j = anillo.length - 1; i < anillo.length; j = i++) {
      final latI = anillo[i][0], lngI = anillo[i][1];
      final latJ = anillo[j][0], lngJ = anillo[j][1];
      final cruza = (lngI > lng) != (lngJ > lng);
      if (cruza && lat < (latJ - latI) * (lng - lngI) / (lngJ - lngI) + latI) {
        dentro = !dentro;
      }
    }
    return dentro;
  }

  static int _orientacion(List<double> a, List<double> b, List<double> c) {
    final valor = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
    return valor.sign.toInt();
  }

  static bool _segmentosSeCruzan(
    List<double> a,
    List<double> b,
    List<double> c,
    List<double> d,
  ) {
    return _orientacion(a, b, c) != _orientacion(a, b, d) &&
        _orientacion(c, d, a) != _orientacion(c, d, b);
  }

  static bool poligonosSeIntersectan(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    if (a.any((p) => puntoEnPoligono(p, b))) return true;
    if (b.any((p) => puntoEnPoligono(p, a))) return true;
    for (var i = 0; i < a.length; i++) {
      final a2 = a[(i + 1) % a.length];
      for (var j = 0; j < b.length; j++) {
        if (_segmentosSeCruzan(a[i], a2, b[j], b[(j + 1) % b.length])) {
          return true;
        }
      }
    }
    return false;
  }
}
