import 'package:flutter/foundation.dart';

import '../../../sync/descarga_service.dart';
import '../../../sync/envio_service.dart';
import '../../catastro/data/predios_repository.dart';
import '../data/campanias_repository.dart';
import '../domain/campania.dart';

/// Estado de la pantalla "Mis campañas". Siempre muestra primero lo que hay en el
/// teléfono y, en paralelo, intenta actualizarlo desde el servidor y enviar las actas
/// pendientes: sin conexión la pantalla funciona igual con la última descarga.
class CampaniasController extends ChangeNotifier {
  CampaniasController({
    required CampaniasRepository campanias,
    required PrediosRepository predios,
    required DescargaService descarga,
    required EnvioService envio,
  }) : _campanias = campanias,
       _predios = predios,
       _descarga = descarga,
       _envio = envio;

  final CampaniasRepository _campanias;
  final PrediosRepository _predios;
  final DescargaService _descarga;
  final EnvioService _envio;

  List<Campania> items = [];

  /// campaña -> cantidad de predios descargados que caen en su zona
  Map<int, int> prediosPorCampania = {};

  bool cargandoInicial = true;
  bool descargando = false;
  bool sinConexion = false;
  DateTime? ultimaDescarga;

  /// Problema de la última descarga (no bloquea: se siguen mostrando los datos locales).
  String? aviso;

  /// Actas cerradas que todavía no llegaron al servidor.
  int pendientesEnvio = 0;
  bool enviando = false;

  /// Resultado o problema del último envío ("2 actas enviadas", "Sin conexión...").
  String? avisoEnvio;
  bool envioConProblema = false;

  bool _liberado = false;

  Future<void> iniciar() async {
    await _leerLocal();
    cargandoInicial = false;
    _avisar();
    await sincronizar();
  }

  /// Baja los datos nuevos y envía las actas pendientes (lo que hace "Actualizar").
  Future<void> sincronizar() async {
    await descargar();
    await enviar();
  }

  /// Envía las actas cerradas, de la más antigua a la más nueva. Se llama al abrir la
  /// pantalla, al volver a la app y desde el botón "Enviar ahora".
  Future<void> enviar() async {
    if (enviando || _envio.enCurso) return;
    enviando = true;
    avisoEnvio = null;
    envioConProblema = false;
    _avisar();
    try {
      final r = await _envio.enviarPendientes();
      avisoEnvio = _mensajeEnvio(r);
      envioConProblema = r.aviso != null || r.rechazadas > 0;
    } finally {
      pendientesEnvio = await _envio.contarPendientes();
      enviando = false;
      _avisar();
    }
  }

  /// Vuelve a contar las pendientes (por ejemplo, al regresar de una inspección).
  Future<void> actualizarPendientes() async {
    pendientesEnvio = await _envio.contarPendientes();
    _avisar();
  }

  static String? _mensajeEnvio(ResultadoEnvio r) {
    final partes = <String>[
      if (r.enviadas > 0)
        '${r.enviadas} ${r.enviadas == 1 ? 'acta enviada' : 'actas enviadas'}',
      if (r.rechazadas > 0)
        '${r.rechazadas} ${r.rechazadas == 1 ? 'acta rechazada' : 'actas rechazadas'} por el sistema',
      if (r.fotosOmitidas > 0)
        '${r.fotosOmitidas} ${r.fotosOmitidas == 1 ? 'foto no se pudo subir' : 'fotos no se pudieron subir'}',
      ?r.aviso,
    ];
    return partes.isEmpty ? null : '${partes.join('. ')}.';
  }

  Future<void> descargar() async {
    if (descargando) return;
    descargando = true;
    aviso = null;
    _avisar();
    try {
      await _descarga.descargar();
      sinConexion = false;
      await _leerLocal();
    } on DescargaFailure catch (falla) {
      aviso = falla.mensaje;
      sinConexion = falla.sinConexion;
    } finally {
      descargando = false;
      _avisar();
    }
  }

  Future<void> _leerLocal() async {
    items = await _campanias.listar();
    final todosLosPredios = await _predios.listar();
    prediosPorCampania = {
      for (final c in items)
        c.id: PrediosRepository.filtrarEnZona(todosLosPredios, c).length,
    };
    ultimaDescarga = await _descarga.ultimaDescarga();
    pendientesEnvio = await _envio.contarPendientes();
  }

  void _avisar() {
    if (!_liberado) notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
