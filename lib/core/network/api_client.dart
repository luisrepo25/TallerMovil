import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/session_storage.dart';
import 'auth_interceptor.dart';

/// Rutas del backend que usa el móvil. Única fuente de URLs (como `endpoints.js` en la web).
/// Los endpoints de administración (usuarios, roles, catastro editable…) son del cliente
/// web: no se agregan aquí (ver CLAUDE.md, "Alcance").
class ApiRutas {
  ApiRutas._();

  static const login = '/api/auth/token/';
  static const refresh = '/api/auth/token/refresh/';
  static const perfil = '/api/usuarios/me/';
  static const campanias = '/api/campanias/campanias/';
  static const predios = '/api/catastro/predios/';
  static const estadosExtintor = '/api/fiscalizacion/estados-extintor/';
  static const infracciones = '/api/fiscalizacion/infracciones-catalogo/';
  static const materiales = '/api/fiscalizacion/materiales-combustibles/';
  static const sincronizarActas = '/api/fiscalizacion/sync/actas/';
  static const subirEvidencia = '/api/fiscalizacion/evidencias/subir/';
  static const solicitudesMaterial = '/api/fiscalizacion/solicitudes-material/';
}

/// Cliente HTTP de la app: base URL por entorno y JWT gestionado por [AuthInterceptor].
/// Las pantallas nunca lo usan directamente: solo los repositorios (capa `data`).
class ApiClient {
  ApiClient({
    required SessionStorage storage,
    String? baseUrl,
    void Function()? onSesionExpirada,
    HttpClientAdapter? adapter, // para pruebas
  }) : dio = Dio(_opciones(baseUrl)) {
    final sinInterceptores = Dio(_opciones(baseUrl));
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
      sinInterceptores.httpClientAdapter = adapter;
    }
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        dio: dio,
        dioSinInterceptores: sinInterceptores,
        rutaRefresh: ApiRutas.refresh,
        rutasPublicas: const [ApiRutas.login],
        onSesionExpirada: onSesionExpirada,
      ),
    );
  }

  final Dio dio;

  static BaseOptions _opciones(String? baseUrl) => BaseOptions(
    baseUrl: baseUrl ?? AppConfig.apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  );
}
