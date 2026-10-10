# MOVIL.md — App móvil del Inspector Técnico (Flutter, offline-first)

Plan de implementación de la app móvil del **SIG de Riesgo de Incendios — Bomberos Voluntarios UUBR**. Complementa a `Backend/CLAUDE.md`, `Backend/PLANBACKEND.md` y `TallerFronted/FRONTEND.md`: lo que allá se decide (roles, offline-first, cálculo de riesgo en el backend) aquí no se reinterpreta.

## 1. Rol esperado

Actúa como **ingeniero senior de desarrollo móvil (Flutter)** integrado al equipo:
- La app se usa **en la calle**, con sol, una mano, señal intermitente y prisa. Cada decisión se juzga con eso: **nunca perder datos**, pocos toques, textos grandes, sin esperar a la red.
- Si una regla de negocio es ambigua (scoring, qué pasa con actas de una campaña ya cerrada, límite de fotos), **pregunta** antes de asumir.
- Si crees que algo de este documento está mal, dilo y explica por qué; nunca lo cambies en silencio.

## 2. Alcance

| Cliente | Usuario | Hace |
|---|---|---|
| **Móvil (este proyecto)** | **Inspector Técnico** | Ver sus campañas, inspeccionar predios, registrar materiales, infracciones y fotos, consultar historial. **Funciona sin conexión** |
| Web (`TallerFronted`) | Administrador, Oficial de Mando | Gestión, catastro, campañas, reportes. No se implementa aquí |

La app **no** crea campañas, predios ni usuarios, y **no calcula** carga de fuego ni scoring: eso lo hace el backend al recibir el acta (CLAUDE.md, decisión 3).

## 3. Estado actual (revisado 2026-10-09)

Proyecto Flutter `app_movil_uubr` (Flutter 3.38.4, Dart ^3.10.3), repo git propio con 2 commits.

| Existe | Observación |
|---|---|
| Onboarding con 3 tarjetas, login, tema (`AppTheme`, `AppColors`) | Paleta ya alineada con la web (azul marino, rojo seguridad, colores de riesgo) |
| `ApiClient` mínimo con `login()` (paquete `http`) | Sin interceptor, sin refresh de token |
| `LoginController` (`ChangeNotifier` + `provider`) | El token **solo vive en memoria**: se pierde al cerrar la app |
| `InspectorHomeScreen` | Placeholder |

Deuda a resolver en la Fase M0:
- `login_form.dart` (235 líneas) y `onboarding_screen.dart` (239) **superan el límite de 150**.
- Estructura mezclada (`screens/` y `features/`): unificar en *feature-first*.
- El login no consulta `/api/usuarios/me/`, así que **no verifica que sea Inspector**.
- URL base fija (`10.0.2.2` / `localhost`): no sirve en un celular real ni en producción.
- Validación de contraseña mínima de 6 en la app vs 8 en el backend: alinear mensajes.

## 4. Reglas de código limpio (obligatorias, mismas que la web)

1. **Ningún archivo ni widget pasa de 150 líneas.** Si un `build()` se acerca a 100, extraer widgets.
2. **Una pantalla = composición de secciones** (`Header`, `Body`, `Footer`/acciones), cada una en su archivo bajo `features/<modulo>/presentation/widgets/`.
3. **Capas por feature** (equivalente móvil de las 3 capas del backend):
   - `presentation/` — pantallas, widgets y controladores de estado. **Sin SQL, sin HTTP.**
   - `domain/` — modelos inmutables y reglas del negocio móvil (validaciones, estados del acta).
   - `data/` — repositorios (`ActaRepository`…), datasource local (SQLite) y remoto (API). **Los repositorios son la única puerta a los datos.**
4. **La UI nunca habla con la API directamente.** Lee del repositorio, que lee de SQLite; la sincronización es un servicio aparte (`sync/`), no lógica metida en widgets (CLAUDE.md, convención móvil).
5. Estado con **`provider` + `ChangeNotifier`** (ya está en el proyecto; no cambiar de librería "por si acaso"). Un controlador por pantalla/flujo.
6. Modelos **inmutables** con `fromJson`/`toJson`/`fromMap`/`toMap` explícitos. Sin `dynamic` suelto en la UI.
7. Dominio en español (`ActaInspeccion`, `Predio`, `MaterialRegistrado`); términos técnicos genéricos en inglés (`SyncQueue`, `Repository`). Archivos en `snake_case.dart`.
8. Colores, espacios y radios **solo desde el tema** (`AppColors`/`AppTheme`); nada hardcodeado en widgets.
9. Cada pantalla de datos maneja **cargando / vacío / error / con datos**, y dice qué hacer ("Aún no tienes campañas asignadas").
10. `flutter analyze` sin avisos antes de cada PR; `dart format`. Commits en español referenciando RF/CU (`feat: implementa RF12 registro offline de acta`).
11. Rama por tarea: `feature/movil-<modulo>-<descripcion>`; PR revisado por otra persona.

## 5. Arquitectura offline-first

**Principio:** la base de datos local (SQLite) es la **fuente de verdad de la app**. La red solo sincroniza.

```
 UI (widgets) ──► Controller ──► Repository ──► SQLite (siempre)
                                     │
                                     └──► Outbox (cola de envíos) ──► SyncService ──► API
                                                                          ▲
                                                  conectividad / app al frente / botón manual
```

- **Lecturas:** siempre desde SQLite. Con conexión, el `SyncService` hace *pull* y actualiza la base; la UI se refresca sola.
- **Escrituras:** se guardan en SQLite **y** se encolan en la *outbox*. Nada espera a la red.
- **Ciclo de vida del acta** (local):
  `borrador` → `cerrada_local` (lista, pendiente de envío) → `sincronizada` (el servidor ya calculó carga de fuego, scoring y cluster) · o `rechazada` (el servidor la rechazó; se conserva para revisión, **nunca se borra sola**).
- **Borrador con autoguardado en cada paso**: si el sistema mata la app o se acaba la batería, el inspector retoma donde iba.
- **Idempotencia:** cada acta nace con un `uuid_local` (UUID v4). Reintentar un envío no duplica (el backend ya tiene `uuid_local` único).
- **Fotos:** se guardan en el almacenamiento privado de la app, comprimidas; se suben aparte cuando hay red, y el acta referencia la foto por su identificador local hasta tener URL.
- **Carga de fuego y scoring:** el celular **no los calcula**. Tras sincronizar, se muestran los valores del servidor. Mientras tanto la pantalla dice "Se calculará al sincronizar".
- **Sesión:** el inspector puede trabajar sin conexión aunque su token haya vencido; el token solo se necesita al sincronizar. Si el refresh token también venció, se pide iniciar sesión **sin perder la cola**.
- **Cerrar sesión con datos pendientes:** avisar ("Tienes 3 actas sin sincronizar") y no borrarlas sin confirmación explícita.

### Mapa sin conexión (decisión pendiente)
Los mosaicos de OpenStreetMap **no permiten descarga masiva** (política de uso). Opciones: (a) caché solo de lo que el inspector ya vio (`flutter_map_tile_caching`, uso moderado), (b) dibujar solo polígonos de predios y zona sobre fondo liso cuando no hay red, (c) proveedor de mapas offline propio. **Recomendación:** (a) + (b), y revisar (c) si se necesita cobertura total.

## 6. Dependencias propuestas

| Necesidad | Paquete | Nota |
|---|---|---|
| HTTP con interceptores (JWT, refresh) | `dio` | Reemplaza `http`; permite una sola renovación compartida, como la web |
| Base local | `sqflite` (+ `path`) | CLAUDE.md ya la nombra. Migraciones versionadas a mano |
| Tokens | `flutter_secure_storage` | Nunca `shared_preferences` para tokens |
| Conectividad | `connectivity_plus` | Dispara sincronización al recuperar señal |
| Cámara/galería | `image_picker` + `flutter_image_compress` + `path_provider` | Máx. ~1280 px, calidad ~80 |
| Mapa | `flutter_map` + `latlong2` | OSM, sin API key (igual que la web) |
| GPS (opcional) | `geolocator` | Mostrar posición y validar cercanía al predio |
| Identificadores | `uuid` | `uuid_local` |
| Segundo plano (más adelante) | `workmanager` | Primero sincronizar en primer plano y con botón manual |
| Pruebas | `sqflite_common_ffi`, `mocktail` | BD en memoria para probar repos y sync |

No agregar nada más sin discutirlo.

## 7. Datos locales (SQLite)

Reflejan lo necesario del esquema del backend; no se copia todo.

| Tabla | Para qué |
|---|---|
| `campanias` | Campañas asignadas al inspector (id, nombre, fechas, estado, polígono GeoJSON) |
| `predios` | Predios de sus campañas (id, nombre, dirección, tipo, área, polígono) |
| `hidrantes` | Red de hidrantes activa (para mapa y consulta) |
| `cat_estados_extintor`, `cat_infracciones`, `cat_materiales` | Catálogos (con Hi y Ci para mostrar, no para calcular) |
| `actas` | `uuid_local` (PK), predio, campaña, campos de la inspección, `estado_local`, `fecha_inspeccion` (captura en el dispositivo), resultados del servidor (carga, scoring, cluster) |
| `acta_materiales`, `acta_infracciones` | Hijos del acta (se borran en cascada con ella) |
| `acta_evidencias` | `ruta_local`, `descripcion`, `subida`, `url_remota` |
| `outbox` | Cola: tipo de operación, referencia, `intentos`, `ultimo_error`, `estado` |
| `meta` | Último sync por entidad, versión del esquema |

## 8. Pantallas (flujo del Inspector)

1. **Onboarding** *(hecho)* → **Login** *(hecho; falta sesión persistente y verificar subtipo)*.
2. **Mis campañas** (inicio): campañas asignadas, estado, % local de predios inspeccionados, chip "Sin conexión", contador de **pendientes de sincronizar**.
3. **Campaña**: mapa con la zona y los predios (coloreados por estado local: pendiente / inspeccionado / enviado) + lista. Tocar un predio → ficha → "Iniciar inspección".
4. **Inspección (asistente de 6 pasos)**, autoguardado en cada paso:
   1. Confirmar predio (nombre, dirección, aforo; opcional validar GPS).
   2. Seguridad: estado de extintores (catálogo), fallas eléctricas (sí/no), rutas de evacuación despejadas (sí/no).
   3. Materiales combustibles: elegir material del catálogo + peso en kg (lista editable).
   4. Infracciones: elegir del catálogo + descripción opcional.
   5. Evidencias: foto con descripción (cámara o galería).
   6. Resumen y **Cerrar acta** (queda `cerrada_local`; inmutable desde ese momento).
5. **Historial**: actas del inspector (locales y sincronizadas) con su estado y, si ya sincronizó, scoring y riesgo.
6. **Sincronización**: cola con estado por acta, reintentar, ver el motivo de un rechazo.
7. **Hidrantes**: mapa de la red y el más cercano a mi posición.
8. **Perfil**: datos del usuario, última sincronización, cerrar sesión.

Mockups (ASCII):
```
┌───────────────────────────┐   ┌───────────────────────────┐   ┌───────────────────────────┐
│ UUBR        ☁ Sin conexión│   │ ← Mercados Zona Norte     │   │ ← Inspección · Paso 3/6   │
├───────────────────────────┤   ├───────────────────────────┤   │ ▓▓▓▓▓▓░░░░░░ Materiales   │
│ Pendientes de enviar: 3 ⟳ │   │  [   mapa con predios   ] │   ├───────────────────────────┤
│                           │   │   ● pendiente ● hecho     │   │ Madera            300 kg ✎│
│ ▌Mercados Zona Norte      │   ├───────────────────────────┤   │ Plásticos         150 kg ✎│
│  En curso · 12 de 40      │   │ Mercado Los Pozos     ›   │   │ [ + Agregar material ]    │
│ ▌Escuelas Plan 3000       │   │ Mercado Abasto        ›   │   ├───────────────────────────┤
│  Pendiente · 0 de 25      │   │ Mercado Mutualista  ✔ ›   │   │ [ Atrás ]      [ Siguiente]│
└───────────────────────────┘   └───────────────────────────┘   └───────────────────────────┘
```
Principios de UI: botones ≥ 48 px, alto contraste (uso al sol), selectores y *chips* en vez de teclado cuando se pueda, un solo CTA principal por pantalla, estados vacíos que dicen qué hacer, y color de riesgo siempre con texto/ícono (nunca solo color).

## 9. Reglas de negocio en la app

Las valida el backend (autoridad); la app las refleja para evitar errores evidentes y mostrar el motivo cuando el servidor rechaza.

- **Solo Inspector Técnico.** Tras el login se consulta `/api/usuarios/me/`; si no tiene el subtipo `inspector_tecnico`, pantalla "Esta cuenta trabaja desde la plataforma web" y cerrar sesión.
- **Solo campañas asignadas y no cerradas.** El backend rechaza actas en campañas cerradas (409), en campañas donde no está asignado, o de predios fuera de la zona (ST_Intersects).
- **Estados de campaña:** `pendiente`, `en_curso`, `cerrada`. La app no los modifica.
- **Acta:** extintores obligatorios (catálogo); fallas eléctricas default `no`; rutas despejadas default `sí`; peso de materiales ≥ 0 con 2 decimales; **carga de fuego nunca se ingresa**; distancia al hidrante la fija el backend si no se envía.
- **Acta cerrada es inmutable** (el backend rechaza agregar materiales, infracciones o fotos a un acta cerrada).
- **Reincidencia:** la determina el backend al registrar la infracción; la app solo la muestra cuando ya sincronizó.
- **Riesgo:** valores `'Bajo' | 'Medio' | 'Critico'` (sin tilde); mostrar "Crítico". Colores semánticos de `AppColors.riesgoColor`.
- **Fotos:** comprimidas, privadas de la app, con descripción opcional; no se pueden agregar a un acta cerrada.
- **Errores al sincronizar, por acta** (un acta mala no frena a las demás): `409` campaña cerrada → `rechazada` con motivo; `400` predio fuera de zona / inspector no asignado → `rechazada`; `5xx`/sin red → se reintenta con espera creciente.

## 10. Brechas con el backend (decidir con el equipo)

El backend actual cubre login, `/me`, catálogos, campañas visibles al inspector y el registro de actas **en línea**. Para trabajar **sin conexión** faltan cosas; la mayoría ya figuran en la **Fase 7 del PLANBACKEND**.

| # | Brecha | Por qué importa | Propuesta |
|---|---|---|---|
| **G1 ✅** | **Resuelta 2026-10-09:** `POST /api/fiscalizacion/sync/actas/` (lote idempotente, resultado por acta). Antes: no existía `POST /sync/actas/` | Hoy registrar un acta completa son ≥ 5 llamadas **no atómicas** (acta → materiales → infracciones → evidencias → cerrar). Offline, un corte a la mitad deja actas a medias | Endpoint de sincronización que reciba el acta completa (con `uuid_local`, materiales, infracciones), responda **por acta**, la deje cerrada y dispare cálculo. Es la Fase 7 |
| **G2** | Las evidencias reciben solo `url_imagen` (texto) | La app tiene un archivo, no una URL | Endpoint de subida (multipart) + decidir almacenamiento (Supabase Storage / S3 / disco). Pendiente en el plan: "definir con Luis" |
| **G3 ✅** | **Resuelta 2026-10-09** en el endpoint de sincronización (acepta `fecha_inspeccion`, ISO 8601 con zona; no puede ser futura). Antes: `ActaInspeccionCreateSerializer` **no aceptaba `fecha_inspeccion`** | Un acta hecha el lunes y sincronizada el jueves quedaría con fecha del jueves | Aceptar la fecha de captura enviada por el dispositivo (validando que no sea futura) |
| **G4** | No hay "predios de mi campaña" | Descargar todos los predios es innecesario | `GET /campanias/{id}/predios/` (usa la misma intersección espacial) |
| **G5** | Catálogos en 3 llamadas, sin versión | Más datos y más tiempo al descargar | Opcional: un solo endpoint de catálogos con versión/ETag |
| **G6** | Historial de predio no trae infracciones previas "livianas" | Mostrar al inspector reincidencias previas sin conexión | Incluir resumen de infracciones previas por predio en la descarga |
| **G7** | Access token 5 min / refresh 1 día | Un inspector en campo varios días sin abrir la app pierde el refresh | Subir el refresh a 7–14 días para el móvil, o permitir re-login sin perder la cola |
| **G8 ✅** | **Resuelta 2026-10-09:** la API ahora responde ISO 8601 con zona (`...-04:00`); la app envía `fecha_inspeccion` también con zona (`DateTime.now().toUtc().toIso8601String()`). Antes: marcas de tiempo sin zona horaria | Dispositivo en Bolivia (UTC-4) vs servidor | Acordar convención: la app envía ISO 8601 con offset; el backend normaliza |
| **G9** | `/api/fiscalizacion/actas/historial/` no filtra por usuario | El inspector vería actas de otros | Restringir al propio inspector (o parámetro obligatorio) |

## 11. Plan de implementación

Una rama por tarea; marcar `[x]` con fecha al terminar; cada archivo ≤ 150 líneas.

### Fase M0 — Fundaciones y refactor
- [x] Estructura *feature-first* (`lib/core`, `lib/features/<modulo>/{data,domain,presentation}`) — **2026-10-09**. Archivos movidos con `git mv`; `lib/sync` se crea en la Fase M6.
- [x] `login_form.dart` (235) y `onboarding_screen.dart` (239) partidos; ningún archivo de `lib/` ni `test/` pasa de 150 líneas (el mayor tiene 138) — **2026-10-09**.
- [x] `http` reemplazado por `dio` con interceptor: inyecta el JWT, **renueva antes de vencer**, comparte **una sola renovación** entre peticiones simultáneas y reintenta una vez ante un 401 — **2026-10-09**. Sin red no se declara la sesión como expirada.
- [x] Configuración de entorno: `--dart-define=API_URL=...` (por defecto `10.0.2.2` en emulador Android, `localhost` en escritorio) — **2026-10-09**.
- [x] `flutter_secure_storage` para tokens y último usuario; sesión persistente — **2026-10-09**.
- [x] Componentes base: `LoadingButton`, `ErrorBanner`, `EmptyState`, `ErrorState`, `LoadingState` — **2026-10-09**. Pendiente: `SectionCard` y tokens de espaciado/tipografía (se agregan cuando los pidan las pantallas de M3/M4).
- [x] `flutter analyze` sin avisos y script `dart run tool/check_line_limit.dart` que falla si un `.dart` supera 150 líneas — **2026-10-09**.
- [x] 23 pruebas automáticas (JWT, interceptor, repositorio de autenticación, 3 pruebas de pantalla) — **2026-10-09**. Falta probar en un celular real y contra el backend real (necesita credenciales de un usuario Inspector).
- Arreglo extra: la tarjeta del onboarding se desbordaba en pantallas pequeñas; ahora su texto se desplaza.

### Fase M1 — Autenticación y sesión *(Backend Fase 1)*
- [x] Login → `/api/usuarios/me/`; verifica el subtipo `inspector_tecnico` y rechaza otras cuentas con un mensaje claro — **2026-10-09** (hecho junto con M0). Los subtipos solapados cuentan: un Oficial que también es Inspector entra.
- [x] Restaurar sesión al abrir la app, **también sin conexión** (usa el último usuario conocido; solo cierra sesión si el servidor confirma que ya no vale) — **2026-10-09**.
- [x] Cerrar sesión con aviso si hay actas sin enviar ("Tienes N actas sin enviar… se borrarán") y solo se borra con confirmación explícita — **2026-10-09**. Una sesión que EXPIRA no borra nada.
- [x] Mensajes de error claros: credenciales, sin conexión, servidor, cuenta que no es de Inspector — **2026-10-09**. Una cuenta inactiva llega como "credenciales inválidas" (el backend responde 401 genérico).

### Fase M2 — Base local y descarga inicial *(Backend Fases 2–4; G4, G5)*
- [x] SQLite (`sqflite`) con migraciones incrementales (`AppDatabase`, v1: `campanias`, `predios`, `meta`) — **2026-10-09**. Las demás tablas del §7 se agregan en su fase (catálogos y actas en M4, outbox en M6).
- [x] Fuentes locales y modelos de dominio (`Campania`, `Predio`) + repositorios — **2026-10-09**.
- [x] "Descargar para trabajar sin conexión" (`DescargaService`): campañas asignadas y predios en **una sola transacción** (si falla la red o el servidor, la base no cambia); guarda la fecha de la última descarga — **2026-10-09**. Pendiente: hidrantes y catálogos (se suman con M3/M4).
- [x] Pruebas con SQLite real en memoria (41 pruebas en total) — **2026-10-09**.
- Decisión: al **cerrar sesión se borran los datos descargados** para no mezclar usuarios. Cuando exista la cola de actas (M6) habrá que impedirlo si quedan actas sin enviar.
- Limitación (brecha G4): sin endpoint "predios de mi campaña", la app descarga todos los predios y calcula en el teléfono cuáles caen en la zona (ayuda visual; el backend valida al sincronizar).

### Fase M3 — Mis campañas y mapa *(RF-7…RF-10, CU07…)*
- [x] Lista de campañas: estado, fechas, cantidad de predios en la zona, franja "datos descargados hace X" con botón y deslizar para actualizar; funciona sin conexión — **2026-10-09**. Pendiente: avance local y contador de pendientes por enviar (M4/M6).
- [x] Detalle de campaña con la lista de predios de su zona — **2026-10-09**.
- [x] Mapa de la campaña (`flutter_map` + OpenStreetMap, sin API key): zona con contorno punteado, predios de la zona, y al tocar un predio de la lista se resalta en rojo y el mapa se centra en él — **2026-10-09**. Pendiente: colorear los predios por estado de inspección (llega con M4) y tocar el predio directamente en el mapa.
- [x] Ubicación del inspector en el mapa (`geolocator`): punto azul con círculo de precisión, botón "Mi ubicación", aviso **"Estás en la zona de la campaña" / "Estás fuera de la zona"** y mensajes claros si falta el permiso o el GPS está apagado (con acceso a los ajustes). Se sigue solo mientras la pantalla está abierta (ahorra batería) — **2026-10-09**. Es informativa: no bloquea inspeccionar fuera de la zona (la decisión §13.8 sigue abierta).
- [~] Estrategia de mapa sin conexión (§5): hoy la zona y los predios se dibujan siempre (salen de SQLite) y el fondo de calles solo carga con internet. Falta guardar en caché los mosaicos ya vistos (opción (a) del §5).

### Fase M4 — Inspección *(RF-12, RF-22; CU12, CU22)*
- [x] Asistente de **5 pasos** (Predio · Seguridad · Materiales · Infracciones · Resumen) con **autoguardado en cada cambio** y retomar el borrador — **2026-10-09**. El paso de fotos se inserta antes del resumen en la M5 (serán 6).
- [x] Materiales (catálogo + peso en kg, uno por tipo, se edita en vez de repetir) e infracciones (catálogo + detalle) — **2026-10-09**. La carga de fuego NO se ingresa ni se calcula en el teléfono.
- [x] Resumen con "Editar" por sección y **cerrar acta** (pasa a `cerrada_local`, inmutable; el botón se apaga y se explica qué falta si no hay extintores) — **2026-10-09**.
- [x] Validaciones locales y mensajes en español: peso > 0 y ≤ 999 999,99 (acepta coma decimal), campaña cerrada no se inspecciona — **2026-10-09**.
- [x] Estado de cada predio en el detalle de la campaña (Sin inspeccionar · Borrador · Lista para enviar · Enviada · Rechazada) con botón **Inspeccionar / Continuar / Reinspeccionar** — **2026-10-09**.
- [x] Regla decidida: **una sola acta abierta por predio y campaña**; tras cerrarla se puede reinspeccionar (acta nueva, la anterior se conserva) — **2026-10-09**.
- [x] El `ActaLocal.toSyncJson()` ya produce el cuerpo exacto de `POST /api/fiscalizacion/sync/actas/` (fecha en UTC con zona) — **2026-10-09**. Falta el envío en sí (M6).
- Estructura: catálogos y actas en SQLite (migración v2 en `core/database/migraciones.dart`); `ActasRepository`/`CatalogosRepository` sobre interfaces (`ActasStore`, `CatalogosStore`) para probar sin SQLite.

### Fase M5 — Evidencias fotográficas *(RF-13; G2)*
- [ ] Captura con cámara o galería, compresión, almacenamiento privado.
- [ ] Descripción por foto; miniaturas; eliminar mientras el acta esté en borrador.
- [ ] Manejo de permisos (Android/iOS) con explicación al usuario.

### Fase M6 — Sincronización *(RF-21, CU23; Backend Fase 7; G1, G3, G7, G8)* — **crítica**
- [ ] Outbox persistente y `SyncService` (al recuperar señal, al abrir la app, botón manual).
- [ ] Envío idempotente por `uuid_local`; respuesta por acta; marcar `sincronizada` y guardar carga de fuego / scoring / cluster del servidor.
- [ ] Subida de fotos aparte, con reintento y reanudación.
- [ ] Reintentos con espera creciente; actas `rechazada` con motivo visible.
- [ ] Pantalla de sincronización (estado por acta, reintentar).
- [ ] Sesión vencida durante el sync: pedir login **sin perder la cola**.
- [ ] Pruebas: corte de red a mitad de envío, duplicado del mismo `uuid_local`, lote parcialmente fallido, campaña cerrada mientras estaba offline.

### Fase M7 — Historial, hidrantes y pulido
- [ ] Historial del inspector (local + servidor) con scoring y riesgo.
- [ ] Mapa de hidrantes y el más cercano a mi posición (`geolocator`).
- [ ] Reincidencias previas del predio visibles offline (G6).
- [ ] Accesibilidad (tamaños de fuente, contraste), modo oscuro opcional.

### Fase M8 — Pruebas de campo y entrega
- [ ] Matriz de pruebas offline (modo avión, señal intermitente, batería baja, app cerrada a la fuerza a mitad de acta).
- [ ] Pruebas de integración del flujo completo (login → descargar → inspeccionar → cerrar → sincronizar).
- [ ] Permisos y *manifest* (Android/iOS), ícono y *splash*, firma del APK.
- [ ] HTTPS en producción (sin tráfico en texto plano), sin datos personales en logs.
- [ ] Distribución a los inspectores (APK / Play interna).

## 12. Seguridad

- Tokens en almacenamiento seguro; nunca en `shared_preferences` ni en logs.
- HTTPS en producción; el tráfico `http://` solo en desarrollo.
- Fotos y base de datos en el almacenamiento privado de la app. Evaluar cifrar SQLite (SQLCipher) si las actas se consideran sensibles.
- No guardar la contraseña; solo tokens.
- Cerrar sesión limpia tokens; los datos locales se conservan hasta sincronizar.

## 13. Decisiones abiertas (responder antes de la fase indicada)

1. ✅ *Decidido 2026-10-09: no se muestra.* **¿Se muestra una vista previa de carga de fuego/scoring en el celular?** Recomendación aceptada: no (decisión 3 de CLAUDE.md: se calcula en Django). Si se quiere una estimación, habría que **duplicar la fórmula** en Dart. *(M4)*
2. **Acta de una campaña que se cerró mientras el inspector estaba sin conexión:** ¿se acepta al sincronizar o se rechaza? Hoy el backend la rechaza. *(M6)*
3. ✅ *Decidido 2026-10-09: una sola acta abierta por predio y campaña; reinspección tras cerrar.* **¿Una o varias actas por predio y campaña?** La BD no lo impide. Afecta el asistente y el avance. *(M3)*
4. **Fotos:** ¿máximo por acta? ¿mínimo obligatorio cuando hay infracciones? *(M5)*
5. **Almacenamiento de fotos: Cloudinary** (decidido 2026-10-09; entorno `dn483x0ri`, carpeta `evidencias_campanias`). El API Secret vive solo en el `.env` del backend; el móvil nunca lo ve: sube la foto al backend (o con una firma de un solo uso emitida por el backend). Carpeta `evidencias_campanias` creada y rol Master Admin asignado a la key "Taller" (2026-10-09). Falta el endpoint de subida del backend (G2). *(M5)*.
6. **Mapa sin conexión** (§5) *(M3)*. Aviso: `flutter_map` advierte que los mosaicos públicos de OpenStreetMap **no son para uso en producción masivo** (OSM Tile Usage Policy). Para el despliegue real conviene un proveedor propio o con plan (MapTiler, Stadia, Thunderforest…) o servir mosaicos propios.
7. **Vigencia del refresh token** para el móvil (G7) *(M1)*.
8. **¿Validar la cercanía GPS al predio al inspeccionar?** Útil como control, pero exige permisos y falla en interiores. *(M4)*
9. **Distribución:** ¿APK directo o Play Store interna? ¿Solo Android o también iOS? *(M8)*

## 14. Definición de "terminado" por tarea

- Cumple el límite de 150 líneas y la separación de capas.
- Funciona **sin conexión** y no pierde datos si la app se cierra a la fuerza.
- Maneja cargando / vacío / error / datos.
- Respeta las reglas de §9 y no calcula lo que calcula el backend.
- `flutter analyze` limpio y pruebas pasando.
- Probada en un celular real (no solo emulador) con y sin red.
- Casilla marcada aquí con la fecha.
