import 'package:app_movil_uubr/core/network/api_client.dart';
import 'package:app_movil_uubr/features/auth/data/auth_repository.dart';

import 'fake_adapter.dart';
import 'memory_session_storage.dart';

/// Respuesta de `GET /api/usuarios/me/` con los subtipos indicados.
Map<String, dynamic> perfil(List<String> subtipos) => {
  'id': 7,
  'nombre_completo': 'Ana Pérez',
  'email': 'ana@uubr.org.bo',
  'rol': {'id': 2, 'nombre': 'Inspector Tecnico'},
  'activo': true,
  'subtipos': subtipos,
};

/// Servidor falso que acepta el login y devuelve el perfil con esos subtipos.
FakeAdapter servidorConPerfil(List<String> subtipos) => FakeAdapter((o) async {
  if (o.path == ApiRutas.login) {
    return jsonResponse({'access': jwtVigente(), 'refresh': 'refresh-1'});
  }
  return jsonResponse(perfil(subtipos));
});

AuthRepository crearRepositorio(
  MemorySessionStorage storage,
  FakeAdapter adapter,
) {
  final api = ApiClient(
    storage: storage,
    baseUrl: 'http://servidor.test',
    adapter: adapter,
  );
  return AuthRepository(api: api, storage: storage);
}
