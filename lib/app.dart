import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/location/geolocator_ubicacion_service.dart';
import 'core/location/ubicacion_service.dart';
import 'core/navigation/app_navigator.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_session_storage.dart';
import 'core/storage/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/transitions/page_transitions.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/screens/app_gate.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/sesion_controller.dart';
import 'features/campanias/data/campanias_local_source.dart';
import 'features/campanias/data/campanias_repository.dart';
import 'features/catastro/data/predios_local_source.dart';
import 'features/catastro/data/predios_repository.dart';
import 'features/inspeccion/data/actas_local_source.dart';
import 'features/inspeccion/data/actas_repository.dart';
import 'features/inspeccion/data/catalogos_local_source.dart';
import 'features/inspeccion/data/catalogos_repository.dart';
import 'features/inspeccion/data/evidencias_archivos.dart';
import 'sync/descarga_service.dart';
import 'sync/envio_service.dart';

/// Raíz de la app: arma las dependencias una sola vez y las expone con Provider.
/// Los widgets nunca crean repositorios ni clientes HTTP por su cuenta.
class MyApp extends StatefulWidget {
  const MyApp({super.key, SessionStorage? storage}) : _storage = storage;

  final SessionStorage? _storage; // inyectable para pruebas

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SessionStorage _storage =
      widget._storage ?? SecureSessionStorage();
  late final ApiClient _api = ApiClient(
    storage: _storage,
    onSesionExpirada: _sesionExpirada,
  );
  late final AuthRepository _auth = AuthRepository(
    api: _api,
    storage: _storage,
  );
  late final SesionController _sesion = SesionController(
    _auth,
    // Datos de otra persona no deben quedar en el teléfono al cerrar sesión
    alCerrarSesion: _database.limpiarTodo,
  );

  // Base local: se abre sola la primera vez que alguien la usa (no al arrancar la app)
  late final AppDatabase _database = AppDatabase();
  late final CampaniasRepository _campanias = CampaniasRepository(
    CampaniasLocalSource(_database),
  );
  late final PrediosRepository _predios = PrediosRepository(
    PrediosLocalSource(_database),
  );
  late final ActasLocalSource _actasSource = ActasLocalSource(_database);
  late final ActasRepository _actas = ActasRepository(_actasSource);
  late final EnvioService _envio = EnvioService(api: _api, actas: _actasSource);
  late final CatalogosRepository _catalogos = CatalogosRepository(
    CatalogosLocalSource(_database),
  );
  late final EvidenciasArchivos _evidencias = EvidenciasEnDisco();
  late final UbicacionService _ubicacionService = GeolocatorUbicacionService();
  late final DescargaService _descarga = DescargaService(
    api: _api,
    database: _database,
  );

  // El refresh token venció a mitad de una petición: volver al login limpiando la pila
  void _sesionExpirada() {
    _sesion.expirar();
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      LogoutToLoginRoute(child: const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _auth),
        ChangeNotifierProvider<SesionController>.value(value: _sesion),
        Provider<CampaniasRepository>.value(value: _campanias),
        Provider<PrediosRepository>.value(value: _predios),
        Provider<DescargaService>.value(value: _descarga),
        Provider<EnvioService>.value(value: _envio),
        Provider<UbicacionService>.value(value: _ubicacionService),
        Provider<ActasRepository>.value(value: _actas),
        Provider<CatalogosRepository>.value(value: _catalogos),
        Provider<EvidenciasArchivos>.value(value: _evidencias),
      ],
      child: MaterialApp(
        title: 'UUBR - Riesgo de Incendios',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: AppTheme.light(),
        home: const AppGate(),
      ),
    );
  }
}
