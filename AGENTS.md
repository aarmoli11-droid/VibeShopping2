# VibeShopping — Prototipo Académico (MVP)

Flutter + Supabase directo. **No hay backend Node.js** (eliminado en el cambio de alcance). Todos los datos se leen con el SDK de Supabase desde la vista `v_products_complete`.

## Estado del alcance

- **Dart**: 84 archivos lib + 4 de test, ~9,601 líneas físicas (código real ~8,530: lib 7,966 + test 564). El código de `lib/` (7,966) sigue dentro del objetivo académico 6,000–8,000; con tests supera el límite por el crecimiento de Fase 2/3 (GPS real + sucursales).
- **Backend / SQL**: 0 (el backend Node.ts y las migraciones `server/` fueron eliminados; los datos siguen en Supabase). Hay 2 scripts SQL manuales en `supabase/manual_sql/` para la tabla `supermarkets` (setup, no backend).
- **Dependencias pubspec**: `supabase_flutter`, `provider`, `hive`, `hive_flutter`, `cached_network_image`, `flutter_map`, `latlong2`, `geolocator` (GPS del mapa), `url_launcher` (enlaces externos), `test`.

## Prerequisites
- Flutter 3.22+ (usa `--dart-define-from-file`)
- Supabase project (local o cloud) con `supermarkets` y `v_products_complete` pobladas

## Quick Start (from zero)

```powershell
git clone <repo>
cd VibeShopping

# 1. Crear configuración Flutter desde plantilla
copy .env.example .env

# 2. Editar .env con credenciales de Supabase
notepad .env

# 3. Ejecutar la app
.\run.ps1
```

Sin IDE, sin variables de entorno globales, sin pasos ocultos.

## Configuración

Solo se necesita el par `SUPABASE_URL` + `SUPABASE_ANON_KEY`. Los flags `USE_NODE_API` / `API_BASE_URL` fueron eliminados junto con el backend.

```bash
flutter run --dart-define-from-file=.env
flutter build apk --dart-define-from-file=.env
```

| Variable | Requerida | Leída por | Propósito |
|---|---|---|---|
| `SUPABASE_URL` | Siempre | `supabase_config.dart:22` | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | Siempre | `supabase_config.dart:24` | Clave anónima |

Cada variable tiene exactamente **un punto de lectura** en el código.

## Funcionalidades (alcance final)

| Feature | Estado | Líneas |
|---|---|---|
| `explorer/` | Conservada — pantalla principal, búsqueda y filtros | 1,246 |
| `products/` | Conservada — productos, precios y detalle | 634 |
| `comparison/` | Conservada — comparación de precios entre tiendas | 466 |
| `auth/` | Conservada — login/registro/perfil | 1,057 |
| `categories/` | Conservada — filtro por categorías | 168 |
| `manual_lists/` | **Congelada** — funciona, NO modificar | 2,745 |
| `location_demo/` | NUEVA — mapa real (GPS) + sucursales con detalle | 1,404 |
| `shopping_assistant/` | NUEVA — recomendación precio+distancia+transporte | 510 |

**Regla**: no invertir tiempo en `manual_lists` (congelado). No migrar, no conectar al asistente, no simplificar.

### Features eliminadas (definitivamente)

| Feature | Por qué se eliminó |
|---|---|
| `assistant/` (IA/chat) | IA fuera de alcance; reemplazada por `shopping_assistant` |
| `shopping_planner/` | 4,695 líneas muertas/inaccesibles; fuera de alcance |
| `navigation/` (OSRM/FlutterMap/GPS) | Complejidad fuera de alcance |
| `location/` (FlutterMap) | Reemplazada por `location_demo` |
| `server/` (Node/TS) + migraciones | Backend fuera de alcance; Supabase directo basta |
| `test/features/shopping_planner/` | Pruebas del motor eliminado |

### Navegación (4 tabs, `explorer_shell.dart`)

```
ExplorerShell
├── Tab 1: Explorar → MarketExplorerView  (botón asistente en AppBar)
├── Tab 2: Mis Listas → ManualListsView   (congelado)
├── Tab 3: Ubicación → LocationDemoScreen (mapa real flutter_map)
└── Tab 4: Perfil → ProfileView
```

## Flujo del Asistente de Compras (`shopping_assistant/`)

```
Usuario escribe producto + elige transporte
    ↓
ShoppingAssistantScreen → context.read<ProductProvider>() + ExplorerProvider()
    ↓
ShoppingAssistantLogic.buildRecommendation()
    ↓
matchProduct(query) → candidatos (precio por tienda)
distanceToStore(store) → Haversine local (coordenadas reales) + tiempo por transporte
    ↓
score = pesoPrecio * (másBarato/precio) + pesoDistancia * (másCerca/distancia)
    ↓
Recomendación ordenada + ahorro estimado
```

Pesos por transporte: carro 0.6/0.4, bus 0.5/0.5, bici 0.4/0.6, a pie 0.3/0.7. La recomendación también muestra el tiempo de traslado estimado (carro 30, bus 20, bici 15, a pie 5 km/h). Sin IA, sin backend, sin GPS: la posición del usuario es ficticia (centro de San Isidro).

## Flujo de la Ubicación Demo (`location_demo/`)

Mapa real de San Isidro de El General con `flutter_map` (tiles de OpenStreetMap, sin API key) y supermercados reales leídos de Supabase (`supermarkets` → `LocationDemoRepository.listSupermarkets` + `LocationDemoLogic.demoStoresFromModels`, que descarta filas sin coordenadas o con `department`/`home`). La posición del usuario es **GPS real** (`LocationProvider` + `geolocator`) con diálogo de justificación y estados diferenciados (servicio desactivado, permiso denegado/bloqueado, error); la referencia fija del centro de San Isidro (9.3760, -83.7025) queda como centro por defecto del mapa y como posición del asistente (aún ficticia). Marcadores: punto con nombre por tienda + "Tú". Pan y zoom con gestos + botones `+`/`−`. Al tocar un marcador se abre `StoreDetailsScreen` con foto, dirección, teléfono, horarios por día (`OpeningHours`) y distancias/tiempos por transporte (Haversine + VibeTransport: auto 40, moto 35, bici 15, a pie 5 km/h) + enlaces a Google Maps y llamada. Filtro de radio ampliable 5 → 10 → 15 km y estados `ready` / `noNearby` / `noStores` (este último: "No se cargaron supermercados desde Supabase."). Sin rutas, sin OSRM.

## Reporte: Mapa real de Ubicación (flutter_map + OpenStreetMap)

- **Flutter**: 3.41.1 stable · **Dart**: 3.11.0 stable (2026-02).
- **Paquete de mapa**: `flutter_map ^8.3.1` + `latlong2 ^0.10.1` (requiere Dart ≥3.6 — cumplido). Reemplaza a `maplibre_gl ^0.26.2`. Sin cambio de SDK.
- **GPS**: `geolocator ^14.1.1` vía `LocationProvider` (`lib/core/location/`) con justificación previa y estados diferenciados; permisos Android `ACCESS_FINE/COARSE_LOCATION` (iOS requiere configuración adicional, no aplica). Enlaces externos con `url_launcher`.
- **Proveedor de tiles**: OpenStreetMap. **URL**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`. **API key**: no requiere. **User-Agent**: `com.example.vibeshopping` (`TileLayer.userAgentPackageName`). Atribución visible: "flutter_map | © OpenStreetMap contributors".
- **Supermercados** (reales, desde `public.supermarkets`; coordenadas localizadas vía Nominatim/OSM):
  - BM Bostón: 9.3808282, -83.7061450 (Alameda Venegas, El Prado)
  - CoopeAgri San Luis: 9.3857375, -83.7065238 (Calle 14, Barrio San Luis)
  - Maxi Palí: 9.3675409, -83.6964465 (Vía 242, Barrio Sinaí)
- **Usuario**: GPS real (`LocationProvider`). La referencia fija 9.3760, -83.7025 (Carretera Interamericana Sur, El Prado, San Isidro) queda como centro por defecto del mapa y como posición del asistente (aún ficticia).
- **Distancias/tiempos** (Haversine + velocidades): BM 0.67 km → 1/1/3/8 min; CoopeAgri SL 1.17 km → 2/2/5/14; Maxi Palí 1.15 km → 2/2/5/14 (auto/moto/bici/a pie). Tiempos coherentes por medio (auto ≤ moto ≤ bici ≤ a pie).
- **Interacción**: pan y zoom con gestos (sin rotación) + botones `+`/`−`. Tap en un marcador abre `StoreDetailsScreen` (foto, dirección, teléfono, horarios por día, distancias/tiempos por transporte, enlaces a Google Maps y llamada). Filtro de radio 5 → 10 → 15 km y estados `ready` / `noNearby` / `noStores`.
- **Archivos**: los 6 de `location_demo/` + `core/location/location_provider.dart`, `core/opening_hours.dart`, `core/external_links.dart`; `explorer_shell.dart` con el tab (ahora con `isActive`).
- **Total del proyecto**: 84 archivos lib (8,923 líneas físicas; código 7,966) + 4 archivos test (678 líneas; código 564). Código real ~8,530: `lib/` dentro de 6,000–8,000; con tests supera el límite por el crecimiento de Fase 2/3.

## Estructura de directorios

### Features conservadas (estructura existente intacta)

```
lib/features/<name>/
  screens/  providers/  services/  models/  domain/  widgets/  data/
```

### Features nuevas (layout plano y sencillo)

```
lib/features/location_demo/
  location_demo_screen.dart          (492 — pantalla con mapa flutter_map + GPS/radio)
  location_demo_data.dart            (53 — tiles OSM + Haversine + referencia 9.3760, -83.7025)
  location_demo_store.dart           (39 — modelo DemoStore + displayTitle)
  location_demo_logic.dart           (175 — mapeo Supabase→demo, estados y radio; lógica pura)
  location_demo_map_widgets.dart     (185 — marcadores StoreMarker/UserMarker + zoom)
  location_demo_store_details_screen.dart (460 — pantalla de detalle de la sucursal)

lib/features/shopping_assistant/
  shopping_assistant_screen.dart  (~150)
  shopping_assistant_logic.dart   (~240)  — lógica pura, sin UI
  shopping_assistant_data.dart    (~20)   — posición + distancias
```

No crear repository/datasource/DTO/mapper/useCase/provider si no hace falta.

### Cross-feature imports (actuales)
- Explorer → Products: `product.dart`, `product_provider.dart`
- Explorer → ShoppingAssistant: `shopping_assistant_screen.dart`
- Explorer → LocationDemo: `location_demo_screen.dart`
- Explorer → Auth: `auth_provider.dart`, `login_view.dart`
- Products → Comparison: `comparison_provider.dart`
- ManualLists → Products: `product_provider.dart`
- ShoppingAssistant → Products, Explorer, LocationDemo (Haversine)
- LocationDemo → Explorer: `store_model.dart` (StoreModel en `demoStoresFromModels`)
- LocationDemo → Core: `location_provider.dart`, `opening_hours.dart`, `external_links.dart`

### Single source of truth
- `lib/core/vibe_constants.dart` (VibeColors) — navy `#2C3E50`, mint `#A8D5BA`, backgroundMint, backgroundWhite
- `lib/core/vibe_theme.dart` (VibeTheme) — Material 3
- `lib/core/vibe_formatter.dart` (VibeFormatter.formatPrice) — precios ₡
- `lib/core/supabase_config.dart` — credenciales Supabase
- `lib/features/products/models/product.dart` — ProductEntity/ProductPrice

### Inyección de dependencias
- Providers registrados centralmente en `lib/core/di/app_providers.dart` (solo Auth, Products, Categories, Explorer, Comparison, ManualList, Location)
- `main.dart` solo inicializa Supabase + Hive y delega el DI a `AppProviders`
- Sin Service Locator, sin GetIt, sin reflexión

## Líneas

| Módulo | Líneas |
|---|---|
| manual_lists (congelado) | 2,745 |
| auth | 1,057 |
| explorer | 1,246 |
| products | 634 |
| shopping_assistant (nuevo) | 510 |
| comparison | 466 |
| location_demo (nuevo) | 1,404 |
| core | 659 |
| categories | 168 |
| main | 34 |
| **Total** | **~8,923** |

Código real: ~7,966 en lib + 564 en test = ~8,530 (lib dentro de 6,000–8,000; con tests supera el límite por Fase 2/3). En la fase de limpieza se eliminaron capas de arquitectura innecesarias (interfaces `*Repository`, services passthrough `*Service`), código muerto y ~875 líneas de comentarios de bloque, y se retiró `font_awesome_flutter` (botones Google muertos).

## Verificación

```bash
flutter analyze lib/
flutter test
```

Sin `npx tsc` ni `pnpm test` (el backend fue eliminado). Los tests usan `package:test` (lógica pura, sin widgets): `shopping_assistant/`, `location_demo/` y `opening_hours`.

## Código eliminado (referencia)

- `lib/core/api_client.dart`, `lib/core/api_config.dart` — solo servían al backend eliminado
- `ProductEntity.fromApiMap()` — factory de la API Node.js sin consumidores
- Registros muertos en `app_providers.dart` (shopping_planner, navigation, assistant)
- Directorios `lib/features/{assistant,shopping_planner,navigation,location}/`, `server/`, `test/`
- Fase de limpieza 2026-08: `core/repositories/` (interfaz `ProductRepository`), `products/services/product_service.dart`, `categories/services/category_service.dart`, `categories/domain/repositories/category_repository.dart` (interfaz duplicada), `auth/screens/join_community_gate.dart` → `auth_gate.dart` (`AuthGate`), y en `manual_lists/` (solo código muerto aprobado): `models/route_preparation.dart`, `models/price_comparison_info.dart`, `models/manual_list_summary.dart`, `services/manual_list_serializer.dart`, `services/manual_list_statistics_service.dart`, `providers/parts/manual_list_{comparison,statistics}.dart`, `widgets/detail/coming_soon_banner.dart`.

## Reglas de borrado (permanentes)

Antes de borrar cualquier elemento:
1. Buscar todos los consumidores.
2. Confirmar cero referencias directas e indirectas (Provider, DI, rutas, imports, exports).
3. Ejecutar `flutter analyze` antes y después.
4. Si hay duda, NO borrar; marcar `LEGACY` con comentario explicativo.
5. Documentar en el reporte qué se borró, qué lo reemplaza y cómo se verificó la seguridad.

## Historial de progreso

### Fase 2/3 del mapa: GPS real + sucursales con detalles (2026-10)
- **Creado**: GPS real con `geolocator ^14.1.1` (`LocationProvider` en `lib/core/location/`, diálogo de justificación y estados: servicio desactivado / permiso denegado / bloqueado / error; permisos Android `ACCESS_FINE/COARSE_LOCATION`; iOS requiere configuración adicional). Sucursales reales desde `public.supermarkets` (`LocationDemoRepository.listSupermarkets` + `LocationDemoLogic.demoStoresFromModels`, descartando filas sin coordenadas o `department`/`home`). `StoreDetailsScreen` (foto, dirección, teléfono, horarios `OpeningHours`, distancias/tiempos por transporte con VibeTransport, enlaces Google Maps + llamada con `url_launcher`). Filtro de radio 5 → 10 → 15 km y estados `ready` / `noNearby` / `noStores`.
- **SQL adicional (manual, idempotente)**: `supabase/manual_sql/20261010_phase3_extend_supermarkets.sql` (foto/dirección/teléfono/horarios) y `20261011_authenticated_select_supermarkets.sql` (RLS `select` autenticado para `supermarkets`).
- **Limpieza aplicada**: atribución OSM configurada para renderizar "flutter_map | © OpenStreetMap contributors"; eliminados los legacy `location_demo_stores.dart` (12 tiendas ficticias) y `location_demo_details_sheet.dart` (BottomSheet) — reemplazados por datos reales de Supabase y `StoreDetailsScreen`; eliminados getters muertos de `LocationProvider` y `LocationDemoData.distanceTo`; estado `noStores` + `debugPrint` del error de carga.
- **Verificación**: `flutter analyze`: 0 issues. `flutter test`: 44/44. Commits locales: `c615830` (feature) + el commit de limpieza.
- **Métricas**: 79 → 84 archivos lib (código 7,834 → 7,966); test 2 → 4 archivos (564 código); feature `location_demo` 750 → 1,404 líneas. Código real total ~8,530 (lib 7,966 + tests 564); `lib/` sigue dentro del objetivo académico.

### Migración del mapa a flutter_map 2026-08 (flutter_map + OpenStreetMap)
- **Reemplazado**: el mapa de `maplibre_gl ^0.26.2` (tiles de OpenFreeMap) por `flutter_map ^8.3.1` + `latlong2 ^0.10.1` con tiles de OpenStreetMap (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`, sin API key). User-Agent `com.example.vibeshopping` y atribución visible.
- **Creado**: `location_demo_map_widgets.dart` (marcadores `StoreMarker`/`UserMarker` y controles de zoom `+`/`−`). Tap en marcador o tarjeta → BottomSheet; pan/zoom con gestos (sin rotación).
- **Ajustado**: velocidades coherentes auto 40 / moto 35 / bici 15 / a pie 5 km/h; etiquetas Auto/Moto/Bici/A pie; nota "tiempos estimados de referencia del prototipo" en tarjeta y BottomSheet; botón Cerrar. Se eliminó `mapStyleUrl` (OpenFreeMap).
- **Verificación**: `flutter analyze lib/`: 0 issues. `flutter test`: 7/7 pass.
- **Métricas**: 78 → 79 archivos lib; 7,637 → 7,993 líneas totales (6,960 → 7,834 código lib); feature `location_demo` 553 → 750 líneas.

### Mapa real de Ubicación 2026-08 (MapLibre + OpenFreeMap)
- **Creado**: `location_demo_widgets.dart` (StoreCard) y `location_demo_details_sheet.dart` (BottomSheet).
- **Reemplazado**: el mapa simulado (CustomPainter) por un mapa real con `maplibre_gl ^0.26.2` y tiles de OpenFreeMap (sin API key). Marcadores de texto con el nombre de cada tienda + "Tu ubicación".
- **Datos reales**: 3 supermercados con coordenadas verificadas en OSM (BM Bostón, CoopeAgri San Luis, Maxi Palí); distancia Haversine y tiempos a pie/bici/moto/carro calculados, no escritos a mano.
- **Verificación**: `flutter analyze lib/`: 0 issues. `flutter test`: 7/7 pass.
- **Métricas**: 76 → 78 archivos lib; 7,541 → 7,637 líneas totales; 6,867 → 6,960 código lib; test 121 → 159.

### Fase de limpieza final 2026-08 (código, alcance e incoherencias)
- **Eliminado** (sin consumidores): `lib/core/repositories/product_repository.dart` + carpeta `core/repositories/`, `products/services/product_service.dart`, `categories/services/category_service.dart`, `categories/domain/repositories/category_repository.dart`, `auth/screens/join_community_gate.dart` (→ `auth_gate.dart`), y en `manual_lists/`: `route_preparation.dart`, `price_comparison_info.dart`, `manual_list_summary.dart`, `manual_list_serializer.dart`, `manual_list_statistics_service.dart`, `providers/parts/manual_list_{comparison,statistics}.dart`, `widgets/detail/coming_soon_banner.dart`.
- **Eliminado de providers/modelos**: `ProductProvider.loadProductDetail/selectedProduct/error`, `ComparisonProvider.compareProducts/compareStore/invalidateCache/buildPriceComparisonInfo`, `ExplorerProvider.refresh()`, `CategoryProvider.refresh()`, `AuthProvider.authService` setter + `clearError`, `SupabaseAuthService.refreshSession/isAuthenticated`, `CategoryService`, campos muertos `priceComparison`/`routePreparation` y servicios del `ManualListProvider`, `VibeTheme.screenBackgroundGradient`, `AuthGatewayStyles.buildLogoHero`, `VibeSelectionModals.openLocationPicker`, `ProductDisplayHelper.resolveGridPrice/GridPriceRef/referenceStoreName`, `ComparisonPreview.storeCount`, `ProductEntity.referenceStoreName/fromSupabaseMap`, `StoreModel.fromJson/copyWith/==`.
- **Eliminado de UI (incoherencias)**: botones Google deshabilitados en login/registro (y `font_awesome_flutter` de pubspec), tiles no-op del perfil, `ComingSoonBanner` ("Próximamente"), banner "Comunidad" en `explorer_shell.dart`, picker de zona en `market_explorer_view.dart`.
- **Ajustado al alcance**: `location_demo` ahora muestra tiempos a pie/bici/moto/carro; el asistente muestra tiempo de traslado y ya no usa distancias de respaldo por nombre (solo Haversine real).
- **Simplificado**: repositorios Supabase concretos sin interfaces, inyección directa en providers (`app_providers.dart`), helpers de display limpios, ~875 líneas de comentarios de bloque → comentarios cortos.
- **Verificación**: `flutter analyze`: 0 issues. `flutter test`: 7/7 pass.
- **Métricas**: lib 88 → 76 archivos; 9,649 → 7,541 líneas totales; 7,972 → 6,867 código; 993 → 118 comentarios. Código real ~6,988 (dentro de 6,000–8,000).

### Cambio de alcance a Prototipo Académico
- **Eliminado**: `lib/features/assistant/` (8 archivos), `lib/features/shopping_planner/` (62), `lib/features/navigation/` (18), `lib/features/location/` (6), `test/` (3), `server/` completo (Node/TS + migraciones SQL), `lib/core/api_client.dart`, `lib/core/api_config.dart`.
- **Creado**: `location_demo/` (3 archivos, 470 líneas — mapa estático de San Isidro con CustomPainter + Haversine) y `shopping_assistant/` (3 archivos, 552 líneas — recomendación precio/distancia/transporte sin IA).
- **Modificado**: `app_providers.dart` (242→97 líneas), `main.dart` (sin ApiClient), `explorer_shell.dart` (tab Ubicación → LocationDemoScreen), `market_explorer_view.dart` (botón Asistente en AppBar), `pubspec.yaml` (−dio, −flutter_map, −latlong2, −geolocator, −url_launcher, −image_picker), `product.dart` (eliminado `fromApiMap`).
- **Verificación**: `flutter analyze lib/`: 0 issues. `flutter analyze` (completo): 0 issues.
- **Métricas**: 20,705 → 9,649 líneas totales; 233 → 88 archivos Dart; backend 1,828 → 0; SQL 1,672 → 0.

### Historial previo (resumen)
- Manual Lists refactor a 4 mixins; widgets extraídos (`manual_lists_view.dart` 890→212).
- Price Comparator MVP integrado en `ProductDetailView`.
- `StoreModel` con coordenadas (latitude/longitude) — usadas por el asistente para distancia real.
- Migración `20260709_extend_supermarkets.sql` (coordenadas de San Isidro) — los datos ya están en Supabase.
- Phase D.4: Edge Function `asistente-compras` eliminada de Flutter (borrar del Dashboard si existe).
- Estabilización: dead code removal, file splits, DI centralizado, `docs/ARCHITECTURE.md`.
- Community feature removida (Phase 12) — tab "Comunidad" es placeholder; el tab se conserva.
- Explorer loading stabilizado (Phase D.2) — 2 queries Supabase por sesión, filtrado local.
