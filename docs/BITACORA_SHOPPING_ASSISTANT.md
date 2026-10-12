# Bitácora de desarrollo — Shopping Assistant

Proyecto académico VibeShopping (Flutter + Supabase).
Bitácora de los pasos del desarrollo de Shopping Assistant.
Cada entrada registra **qué** se hizo y **para qué** se hizo.

---

## Entrada 1 — Revisión inicial y diagnóstico (2026-08)

### Qué se hizo
Revisión completa y de solo lectura del proyecto antes de tocar código:
estructura de `lib/`, conexión con Explorer, dependencias, estado actual
de Shopping Assistant, arquitectura, componentes reutilizables,
compatibilidad con `flutter_ai_toolkit`, seguridad de credenciales y
tamaño del proyecto.

### Para qué se hizo
Para conocer exactamente qué existe antes de comenzar el desarrollo,
evitar duplicar código, no romper features existentes y mantener el
proyecto dentro del rango académico de líneas (6,000–8,000).

### Diagnóstico encontrado
- El proyecto usa la arquitectura `lib/features/<feature>/` con
  `core/` para lo compartido y Provider para el manejo de estado.
- Ya existe un `shopping_assistant/` **funcional y activo**:
  motor de recomendación precio + distancia + transporte, sin IA
  (lógica pura). Se abre desde el botón del AppBar en
  `market_explorer_view.dart`.
- No existe ningún código de chat / IA / Gemini / LLM en el proyecto.
  Las únicas menciones son históricas en `AGENTS.md` y `docs/ARCHITECTURE.md`.
- El `.env` (ignorado por git) ya contiene `GEMINI_API_KEY` y
  `API_BASE_URL` como restos de un backend eliminado; hoy no se usan.
- Las dependencias actuales son Supabase, Provider, Hive,
  cached_network_image y (solo para Ubicación) flutter_map/latlong2.
- No hay Firebase en el proyecto: solo Supabase.
- Líneas actuales: `lib/` 7,117 + `test/` 137 = ~7,254 (dentro del rango).
- `flutter_ai_toolkit` 1.0.0 (última) requiere Firebase (`firebase_ai`).
  La versión 0.8.0 es la última que funciona con Gemini por API key.

### Decisiones iniciales
1. Mantener el motor de recomendación actual como está (no se toca
   hasta decidir cómo convive con el chat).
2. Para la UI de chat evaluar `LlmChatView` de `flutter_ai_toolkit`.
3. No colocar claves en el código: seguir el patrón existente
   `.env` → `--dart-define-from-file` → `String.fromEnvironment`,
   igual que `VibeSupabaseConfig`.
4. No crear arquitectura nueva: reutilizar `features/` + Provider +
   `core/`.
5. Próximo paso: decidir cómo integrar el chat (ver Entrada 2).

### Restricciones activas
- No modificar código existente sin aprobación.
- No instalar dependencias todavía.
- No crear backend ni configurar Firebase (criterio revisado en Entrada 2).
- No implementar audio, imágenes ni adjuntos.

---

## Entrada 2 — Comparar alternativas de integración con Gemini (2026-08)

### Nombre
Comparar alternativas de integración de chat e IA con Gemini.

### Resumen
Con el criterio actualizado (Firebase y backend pequeño ya **no** están
excluidos si hacen la integración más sencilla, segura y fácil de
explicar), se compararon tres alternativas y se verificó con
`dart pub add --dry-run` qué dependencias resuelven con el pubspec
actual. No se instaló ni modificó nada.

### Criterio actualizado (prioridades)
1. Código sencillo.
2. Arquitectura pequeña.
3. Fácil de explicar en una exposición de ≤30 minutos.
4. Mantener el proyecto entre ~6,000 y 8,000 líneas.
5. Evitar capas y clases innecesarias.
6. Conservar la lógica multicriterio propia de VibeShopping.

### Objetivo final del asistente
Usuario escribe una solicitud → el asistente interpreta la solicitud →
identifica productos o necesidades → consulta los datos disponibles →
obtiene precios y tiendas → usa distancia y tiempo cuando corresponde →
aplica la lógica multicriterio → genera una recomendación → responde
dentro del chat.

Gemini se encarga principalmente de **comprender y conversar**; la
decisión de qué tienda conviene se apoya en datos y en la lógica de
VibeShopping, **no en una respuesta inventada por el modelo**.

### Verificaciones realizadas (`dart pub add --dry-run`, sin cambios)
| Prueba | Resultado |
|---|---|
| `flutter_ai_toolkit 0.8.0` con `test ^1.31.1` | **NO resuelve** |
| `flutter_ai_toolkit 1.0.0` con `test ^1.31.1` | **NO resuelve** |
| `flutter_ai_toolkit 0.8.0` con `test 1.25.8` o `test 1.31.0` | **NO resuelve** |
| `google_generative_ai 0.4.7` | **Resuelve OK** (añade solo `http`) |

Causa del bloqueo de `flutter_ai_toolkit`: arrastra `firebase_vertexai`/
`firebase_ai` → `firebase_core_platform_interface` → `flutter_test` (SDK),
que fija `test_api 0.7.9`, incompatible con las versiones recientes de
`test` (0.7.11/0.7.12). Ajustar la versión de `test` no bastó en las
combinaciones probadas.
Dato adicional: `google_generative_ai` está marcado como deprecated por
Google, aunque sigue funcionando y es viable para un prototipo.

### Opción A — Flutter + flutter_ai_toolkit + Gemini directo
- **Dependencias**: `flutter_ai_toolkit ^0.8.0` (trae `google_generative_ai`).
  Bloqueada hoy por el conflicto con `test` (verificado).
- **Archivos a crear**: pantalla de chat que envuelve `LlmChatView` +
  pequeño provider/servicio.
- **Archivos a modificar**: `pubspec.yaml` (añadir dependencia y resolver
  `test`), `market_explorer_view.dart` (botón ya existente abre el chat).
- **Complejidad aproximada**: baja en UI (widget listo), media-alta en
  resolución de dependencias.
- **Exposición**: "Usamos una librería de chat lista que recibe un
  proveedor de Gemini; solo escribimos la pantalla".
- **API key**: en el cliente vía `.env` → `--dart-define-from-file`
  (queda embebida en el binario; aceptable para prototipo académico).
- **Lógica multicriterio**: se conserva; se invoca antes o después de la
  respuesta del modelo.
- **Veredicto**: UI atractiva, pero actualmente **no instalable** sin
  ajustar `test`, sin garantía de que la resolución tenga éxito.

### Opción B — Flutter + Firebase AI Logic
- **Dependencias**: `firebase_ai`, `firebase_core`, `flutter_ai_toolkit ^1.0.0`.
  También **NO resuelve** con `test ^1.31.1` (verificado).
- **Archivos a crear**: `firebase_options.dart` (generado por `flutterfire
  config`), pantalla con `FirebaseProvider` + `googleAI()`.
- **Archivos a modificar**: `pubspec.yaml`, `main.dart`
  (`Firebase.initializeApp`), config Android (`google-services.json`),
  `market_explorer_view.dart`.
- **Complejidad aproximada**: media-alta; requiere crear un proyecto
  Firebase, ejecutar `flutterfire` y (según plan) habilitar facturación.
- **Exposición**: "Usamos la vía oficial de Google: Firebase gestiona la
  credencial y nosotros solo llamamos al modelo".
- **API key**: no viaja en la app; Firebase administra la autenticación.
- **Lógica multicriterio**: se conserva igual.
- **Veredicto**: la más segura y oficial, pero con más pasos externos y
  el mismo bloqueo de `test`. Requiere comprobación externa (crear
  proyecto Firebase), no verificable localmente.

### Opción C — Flutter + backend pequeño (Edge Function de Supabase)
- **Dependencias**: cliente: `supabase_flutter` (`functions.invoke`, ya
  presente) o `http` (ya está en el grafo). Sin `flutter_ai_toolkit`.
  Servidor: Deno/TS en una Edge Function de Supabase.
- **Archivos a crear**: `supabase/functions/gemini-chat/index.ts` (guarda
  la clave en secrets de Supabase y proxya a Gemini) + pantalla de chat.
- **Archivos a modificar**: `market_explorer_view.dart`; `pubspec.yaml`
  casi sin cambios (sin conflicto de dependencias).
- **Complejidad aproximada**: media; añade una función serverless
  (backend pequeño, permitido por el nuevo criterio).
- **Exposición**: "La clave vive en Supabase, no en el teléfono; la app
  envía el mensaje y recibe la respuesta".
- **API key**: se guarda en los secrets de la Edge Function (nunca en el
  cliente). Requiere `supabase functions deploy` para probarlo.
- **Lógica multicriterio**: se conserva; la app la aplica sobre datos
  propios (products/stores) y el modelo solo redacta.
- **Veredicto**: buena seguridad sin Firebase, reutiliza Supabase; añade
  un archivo TS y un paso de despliegue.

### Decisión tomada
**Opción A, variante simple**: `google_generative_ai` directo (0.4.7,
resolución verificada) con una **UI de chat mínima propia** en lugar de
`flutter_ai_toolkit` (bloqueado por el conflicto con `test`, verificado).
Motivos: código sencillo, una sola dependencia, sin Firebase ni backend,
explicación corta, y la primera versión del chat (campo de texto, botón
enviar, mensajes, estado de carga y manejo básico de errores) no requiere
un widget tan completo como `LlmChatView`.

`flutter_ai_toolkit` queda descartado por ahora por el bloqueo de
resolución. B (Firebase) y C (Edge Function) quedan como alternativas
documentadas si más adelante se prefiere seguridad u oficialidad.

### Alcance de la primera versión (solo esto)
- Campo de texto, botón enviar, mensajes del usuario, respuestas del
  asistente, estado de carga y manejo básico de errores.
- Dejado para una etapa posterior: audio, imágenes, archivos,
  reconocimiento de productos por imagen y funciones avanzadas de IA.

### Elementos que todavía no se implementan
- `ai_config.dart` (no se crea).
- Instalación de `google_generative_ai` ni de ninguna otra dependencia.
- Conexión con Gemini ni lectura de `GEMINI_API_KEY`.
- Chat ni UI conversacional.
- No se modifica `shopping_assistant_logic.dart` ni
  `shopping_assistant_data.dart` (la lógica multicriterio se conserva).

### Nota de seguridad (registrada)
`.env` + `--dart-define-from-file` evita subir la clave al repositorio,
pero una clave usada directamente desde una app Flutter **no es una
credencial secreta de producción** (queda embebida en el binario y es
extraíble). Es aceptable para un prototipo académico.

---

## Entrada 3 — Prueba técnica: ¿Firebase AI Logic funciona con el proyecto? (2026-08)

### Nombre
Prueba técnica de compatibilidad de **Firebase AI Logic** (`firebase_ai`)
con el proyecto actual, antes de decidir entre Firebase AI Logic y
Supabase Edge Functions.

### Qué se investigó
Si `firebase_ai`, `firebase_core` y `firebase_app_check` resuelven con el
`pubspec.yaml` actual **sin cambiar versiones de las dependencias
existentes** (regla: no forzar la resolución), y si la integración
resultaría sencilla para el prototipo académico.

### Versiones comprobadas (estables actuales, pub.dev API)
Todas son compatibles con Dart 3.11.0 / Flutter 3.41.1 instalados:

| Paquete | Versión estable | Publicada | SDK Dart mínimo | Flutter mínimo |
|---|---|---|---|---|
| `firebase_ai` | **3.15.0** | 2026-08-03 | `^3.6.0` | `>=3.16.0` |
| `firebase_core` | **4.13.0** | 2026-08-03 | `^3.6.0` | `>=3.27.0` |
| `firebase_app_check` | **0.4.6** | 2026-08-03 | `^3.6.0` | `>=3.27.0` |
| `firebase_core_platform_interface` | **8.1.0** | 2026-08-03 | `^3.6.0` | `>=3.27.0` |

`firebase_ai 3.15.0` depende de: `firebase_app_check ^0.4.6`,
`firebase_auth ^6.5.7`, `firebase_core ^4.13.0`,
`firebase_core_platform_interface ^8.1.0`, `http ^1.1.0`,
`meta ^1.15.0`, `web_socket_channel ^3.0.1`.
Nota: `firebase_ai` arrastra además `firebase_auth`.

### Resolución de dependencias obtenida (`dart pub add --dry-run`, sin cambios)
| Prueba | Resultado |
|---|---|
| `firebase_ai:^3.15.0` + `firebase_core:^4.13.0` + `firebase_app_check:^0.4.6` | **NO resuelve** |
| `firebase_core:^4.13.0` (solo) | **NO resuelve** |
| `firebase_app_check:^0.4.6` (solo) | **NO resuelve** |

El conflicto es idéntico en los tres casos:

> `Paquete A` (`firebase_ai >=3.15.0`, `firebase_core >=4.13.0`,
> `firebase_app_check >=0.4.6`) **requiere**
> `firebase_core_platform_interface ^8.1.0`, que declara
> `flutter_test` (SDK) como dependencia de **runtime** → fija
> `test_api 0.7.9`.
>
> `Paquete B` (`test ^1.31.1`, dev dependency actual) **requiere**
> `test_api 0.7.12` o `0.7.13`.
>
> `test_api` no puede ser 0.7.9 y 0.7.12/0.7.13 a la vez →
> **version solving failed**.

Se verificó con la documentación de pub.dev: `firebase_core_platform_interface`
declara `flutter_test` en su sección `dependencies` (no dev) en todas las
versiones recientes. No se comprobó conflicto con `supabase_flutter`,
`provider`, `flutter_map` ni `latlong2`; el único paquete incompatible es
`test`. Al estar prohibido tocar `test`, **Firebase no puede instalarse**
en este proyecto hoy.

### ¿Firebase funcionó?
**NO.** La resolución de dependencias falla de forma real y reproducible.

### ¿Qué prototipo se creó?
**Ninguno.** El Paso 4 del plan era condicional: el prototipo aislado
(campo de texto, botón enviar, carga, respuesta y errores) solo se crea
**si la resolución funciona**. Como no funciona, no se creó nada y no se
tocó `shopping_assistant_screen.dart` ni se conectó Gemini.

### Archivos modificados o creados
- Solo `docs/BITACORA_SHOPPING_ASSISTANT.md` (esta entrada).
- Ningún archivo en `lib/`, `test/`, ni `pubspec.yaml`/`pubspec.lock`
  (los `--dry-run` no escriben; se verificó que no quedaron entradas
  `firebase`/`vertex` en ellos).

### Dependencias agregadas
Ninguna.

### Pruebas ejecutadas
| Prueba | Resultado |
|---|---|
| `dart pub add --dry-run firebase_ai:^3.15.0 firebase_core:^4.13.0 firebase_app_check:^0.4.6` | Fallo de resolución (documentado) |
| `dart pub add --dry-run firebase_core:^4.13.0` | Fallo de resolución |
| `dart pub add --dry-run firebase_app_check:^0.4.6` | Fallo de resolución |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **7/7 pass** |
| Conteo de líneas | lib 78 archivos / 7,117 líneas; test 1 / 137; **total 7,254** (en rango) |

### Configuración que habría requerido Firebase (documentada, no ejecutada)
Para completar la prueba haría falta un **proyecto Firebase real**. No se
creó ninguna configuración para no dejar el proyecto roto. Qué exige cada
pieza:

| Elemento | Qué es | Requiere |
|---|---|---|
| Proyecto Firebase | Proyecto en consola de Firebase | Cuenta Google + (para Vertex AI en Firebase) plan de facturación **Blaze** |
| `firebase_options.dart` | Config por plataforma (apiKey, appId, projectId, etc.) | FlutterFire CLI: `dart run flutterfire configure` (genera el archivo) |
| `google-services.json` | Config Android del proyecto | Descarga desde la consola Firebase, en `android/app/` |
| `GoogleService-Info.plist` | Config iOS | **No aplica**: el proyecto solo apunta a Android |
| App Check | Atestación de la app (Play Integrity en Android) | Activar en consola + `FirebaseAppCheck.instance.activate()`; requiere la app registrada/verificada |
| `main.dart` | Inicialización | `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` antes de `runApp` |

Nota: habría que habilitar además las APIs de Google Cloud (Vertex AI /
Generative Language) y el modelo de Gemini en la consola.

### API key y seguridad en Firebase AI Logic (documentado)
- **Dónde se configura Gemini**: en la consola de Firebase (Vertex AI en
  Firebase → model providers), no en la app.
- **¿La API key queda expuesta?** No viaja en el binario. `firebase_ai`
  autentica con **Firebase Auth + App Check**; la credencial vive en el
  proyecto de Google Cloud.
- **Qué cumple Firebase AI Logic**: gestiona la conexión segura con
  Vertex AI / Gemini sin clave embebida; soporta chat, streaming, audio,
  imagen y herramientas.
- **Qué cumple App Check**: atestación de que la app es auténtica (no una
  copia), protegiendo los recursos de Firebase.
- **Config mínima para un prototipo académico**: proyecto + plan Blaze +
  habilitar APIs + `flutterfire configure`; App Check recomendable pero
  añade pasos (Play Console). Esto supera la complejidad que buscamos.
- **Diferencia con `google_generative_ai`**: ese SDK embebe la API key en
  la app (`GenerativeModel(model, apiKey:)`); Firebase AI Logic no expone
  clave en el cliente. Firebase es más seguro pero no se puede usar hoy
  (bloqueo de dependencias).

### Arquitectura explicable
Primera fase (lo que se probaría):
```
Usuario → Shopping Assistant → Firebase AI Logic → Vertex AI/Gemini → respuesta
```
Posterior (integrando la lógica propia):
```
Usuario → Gemini interpreta la solicitud
       → VibeShopping obtiene productos y precios (Supabase)
       → VibeShopping compara opciones (precio + distancia + transporte)
       → VibeShopping calcula la recomendación (ShoppingAssistantLogic)
       → Gemini presenta la respuesta en el chat
```
La decisión de qué supermercado conviene **no** queda en Gemini: el modelo
interpreta y conversa; la lógica de VibeShopping decide con los datos.

### Comparación con Supabase Edge Functions (sin implementar)
| Aspecto | Firebase AI Logic | Supabase Edge Function |
|---|---|---|
| Archivos | `firebase_options.dart` + config Android + pantalla | `supabase/functions/<fn>/index.ts` (1-2 TS) + pantalla de chat |
| Dependencias nuevas en cliente | `firebase_ai`, `firebase_core`, `firebase_app_check` (+`firebase_auth`) — **no resuelven hoy** | **Ninguna** (`supabase_flutter` ya está; `functions.invoke`) |
| Configuración | Proyecto Firebase, plan Blaze, FlutterFire, App Check | CLI de Supabase: `supabase functions deploy` + `supabase secrets set GEMINI_API_KEY=...` |
| Complejidad | Alta (bloqueo + pasos externos) | Media (un archivo TS + deploy) |
| Facilidad de explicación | "Vía oficial de Google, sin clave en el teléfono" | "La clave vive en Supabase, no en el teléfono" |
| Seguridad de la API key | No viaja en la app (Auth + App Check) | No viaja en la app (secret server-side) |
| Impacto en líneas | +1 archivo de config + pantalla (~200-400) | +1 TS (~40-80) + pantalla de chat (~200-300) |
| Imágenes/audio/archivos después | Soportado por Firebase nativamente | La Edge Function puede recibir datos binarios o URL y llamar a Gemini; equivalente para el prototipo |

### Decisión tomada
**Firebase AI Logic queda DESCARTADO para esta etapa** porque vuelve a
presentar un **conflicto real de dependencias** (verificado con las
versiones estables actuales y sin forzar cambios): `firebase_ai 3.15.0`,
`firebase_core 4.13.0` y `firebase_app_check 0.4.6` arrastran
`firebase_core_platform_interface ^8.1.0` → `flutter_test` (SDK) →
`test_api 0.7.9`, incompatible con `test ^1.31.1` (0.7.12/0.7.13). Además
exigiría proyecto Firebase + plan Blaze + FlutterFire + App Check, una
configuración externa demasiado grande para el prototipo académico.

**Opción principal pasa a Supabase Edge Functions**: una función Deno/TS
que guarda `GEMINI_API_KEY` en secrets de Supabase y llama a Gemini; la
app Flutter solo usa `supabase_flutter` (ya presente) con la pantalla de
chat mínima y conserva `shopping_assistant_logic.dart` y
`shopping_assistant_data.dart` intactos.

### Siguiente paso
Diseñar la Edge Function de Supabase (`supabase/functions/gemini-chat/
index.ts`) y la pantalla de chat mínima en Flutter, y decidir con el
usuario antes de implementar. **Comprobación externa requerida**: el
deploy de la función y una prueba real con Gemini no son verificables
localmente (necesitan la CLI de Supabase conectada al proyecto).

---

## Entrada 4 — Prueba técnica implementada: Edge Function `gemini-chat` + Gemini (2026-08)

### Nombre
Integración mínima Flutter → Supabase Edge Function → Gemini (modelo
`gemini-2.5-flash`) para validar el flujo completo de chat sin depender de
CLI local (Supabase/Deno/Docker no disponibles en este entorno) y sin tocar
la lógica multicriterio.

### Qué se creó
| Archivo | Líneas | Propósito |
|---|---|---|
| `supabase/functions/gemini-chat/index.ts` | 61 | Edge Function Deno/TS: recibe `{"message"}`, lee el secret `GEMINI_API_KEY`, llama a Gemini `:generateContent` con `fetch` (REST, sin dependencias Deno) y devuelve `{"response"}`. Incluye CORS, `OPTIONS` y errores HTTP claros (400/405/500/502). |
| `supabase/config.toml` | 5 | Config de Supabase: `project_id` + `verify_jwt = true` para `gemini-chat`. |
| `lib/features/shopping_assistant/shopping_assistant_test_screen.dart` | 184 | Pantalla de prueba de chat: envía el mensaje con `Supabase.instance.client.functions.invoke('gemini-chat', ...)`, muestra la respuesta y los errores (`FunctionException`), burbujas de usuario/asistente/error y spinner de carga. |

### Cambios temporales (reversibles)
- `lib/features/explorer/screens/market_explorer_view.dart`: 2 líneas — el
  botón "Asistente" del AppBar abre ahora `ShoppingAssistantTestScreen`
  (antes `ShoppingAssistantScreen`). Se revierte cuando se implemente el
  chat definitivo.

### Qué NO se tocó (conservado intacto)
- `shopping_assistant_logic.dart` y `shopping_assistant_data.dart`.
- auth, explorer, products, categories, comparison, manual_lists,
  location_demo, mapa y navegación (salvo las 2 líneas temporales).
- `pubspec.yaml` / `pubspec.lock`: **sin dependencias nuevas** (usa
  `supabase_flutter` ya presente; se verificó `functions_client 2.6.1` con
  API `invoke`/`FunctionException`).

### Seguridad de la API key
`GEMINI_API_KEY` **no existe en Flutter** (ni `lib/`, ni `.env` del cliente,
ni dart-define). Vive solo como secret de Supabase
(`supabase secrets set GEMINI_API_KEY=<clave>`); la Edge Function la lee con
`Deno.env.get`. El binario no contiene la clave.

### Verificación local ejecutada
| Prueba | Resultado |
|---|---|
| `flutter pub get` | OK (sin cambios de dependencias) |
| `dart format` | Mi archivo formateado; `location_demo_data.dart` tiene drift preexistente que **no se tocó** |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **7/7 pass** |
| Sintaxis TS de `index.ts` | Validada con `esbuild` (vía `npx`), sin errores |
| Revisión imports/código muerto/TODO/prints | Sin residuos en archivos nuevos |
| Conteo de líneas | lib 79 / 7,875; test 1 / 159; **total 8,034** (borde superior del rango ~6,000–8,000; la pantalla de prueba es temporal) |

### Pendiente (requiere credenciales/proyecto real)
La prueba **real** con Gemini no es verificable localmente (no hay CLI de
Supabase, Deno ni Docker). Pasos exactos para completarla:
```powershell
supabase login
supabase link --project-ref <PROJECT_REF>
supabase secrets set GEMINI_API_KEY=<clave>
supabase functions deploy gemini-chat
# Prueba local opcional: supabase functions serve
```
Luego abrir el botón "Asistente" en la app y enviar un mensaje.

### Flujo de comunicación (validado)
```
Usuario → shopping_assistant_test_screen.dart
        → functions.invoke('gemini-chat', {'message': ...})
        → Edge Function (Deno) → fetch Gemini :generateContent (secret GEMINI_API_KEY)
        → {"response": ...} → Flutter (burbuja)
```

### Siguiente paso
Cuando se demuestre la integración básica, reemplazar la pantalla de prueba
por el chat definitivo del asistente (manteniendo `shopping_assistant_logic`
y `shopping_assistant_data` intactos) y revertir las 2 líneas temporales.

---

## Entrada 5 — Pantalla definitiva del Shopping Assistant (2026-08)

### Cambios realizados

| Archivo | Acción | Detalle |
|---|---|---|
| `lib/features/shopping_assistant/shopping_assistant_screen.dart` | **Reescrito** (337 → 194 líneas) | Dejó de ser el formulario multicriterio y pasó a ser el chat conversacional definitivo. |
| `lib/features/shopping_assistant/shopping_assistant_test_screen.dart` | **Eliminado** (186 líneas) | Ya no hay dos pantallas con la misma función; su lógica se reutilizó en la definitiva. |
| `lib/features/explorer/screens/market_explorer_view.dart` | **2 líneas revertidas** | El botón "Asistente" del AppBar vuelve a abrir `ShoppingAssistantScreen` (import + builder). Se eliminó la referencia temporal a la pantalla de prueba. Navegación general intacta. |
| `supabase/functions/gemini-chat/index.ts` | **Modificado** (61 → 67 líneas) | Se agregó `SYSTEM_PROMPT`; el flujo (POST → secret → Gemini → `{"response"}`) no cambia. |

### Qué se eliminó de la pantalla antigua
Formulario de producto + selector de transporte + tarjetas de recomendación
(`_IntroCard`, `_BestStoreCard`, `_BestMetric`, `_AlternativeTile`), y el uso
de `provider`, `ProductProvider`, `ExplorerProvider`, `VibeFormatter` y
`ShoppingAssistantLogic` en la UI (la lógica sigue existiendo, solo no se usa
todavía desde la pantalla).

### Qué se creó / agregó
- **AppBar**: título "VibeShopping Assistant" (tema de la app, mint/navy).
- **Descripción inicial** (primer mensaje del asistente): "Pregúntame sobre
  tus compras y te ayudaré a elegir la mejor opción."
- **Área de conversación**: lista de mensajes; usuario a la derecha (burbuja
  navy con texto blanco) y asistente a la izquierda (burbuja mint).
- **Campo de texto inferior** + **botón enviar** (`send_rounded`).
- **Indicador de carga**: spinner mint mientras Gemini responde.
- **Manejo de errores**: `FunctionException` (muestra el error del backend) o
  mensaje genérico si no hay conexión.
- **Auto-scroll** al final de la conversación tras cada respuesta.

### Qué código de la prueba anterior se reutilizó
- La llamada `Supabase.instance.client.functions.invoke('gemini-chat', ...)`.
- `_describeError` (lectura de `error.details['error']`).
- Las burbujas y el patrón de carga (misma paleta `VibeColors`).

### Qué código se eliminó
- `shopping_assistant_test_screen.dart` completo.
- Los 4 widgets privados de la pantalla antigua y sus imports.

### Dependencia agregada
Ninguna. Sigue usando `supabase_flutter` (ya presente) y los estilos de
`core/vibe_constants.dart` / `core/vibe_theme.dart` / `core/vibe_formatter.dart`.

### Prompt de sistema (Edge Function)
`SYSTEM_PROMPT` define la persona del asistente: responder en español, corto,
y **no inventar precios, supermercados, distancias ni tiempos**. Si le piden
datos concretos de VibeShopping, debe decir que aún no tiene acceso a esa
información. Esto protege al usuario contra respuestas inventadas mientras
la integración de datos no esté lista.

### Lógica multicriterio (conservada)
`shopping_assistant_logic.dart` y `shopping_assistant_data.dart` quedan
**intactos** (sin UI que los use todavía). El asistente queda preparado para
trabajar con ellos.

### Revisión de datos reutilizables (para la próxima etapa, sin estructuras nuevas)
- `ProductProvider.products` → `ProductEntity`/`ProductPrice` (vienen de
  `v_products_complete`).
- `ExplorerProvider.stores` → `StoreModel` con coordenadas reales.
- `CategoryProvider`, `ComparisonProvider` y `ManualLists` → ya comparan y
  agrupan productos.
- `ShoppingAssistantLogic.buildRecommendation(query, products, stores, mode)`
  → combina precio + distancia (Haversine) + transporte.
- No se crearon repositorios, servicios ni DTOs: todo lo necesario ya existe.

### Problema y solución
- **Problema**: `dart format lib/` formatearía también
  `location_demo_data.dart` (drift preexistente, fuera de alcance).
- **Solución**: se formateó solo el archivo modificado; `location_demo` no se
  tocó.

### Verificación ejecutada
| Prueba | Resultado |
|---|---|
| `flutter pub get` | OK |
| `dart format` (archivo nuevo) | OK |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **7/7 pass** |
| Sintaxis TS de `index.ts` (esbuild) | OK |
| Grep: TODO / prints / pantalla de prueba | Sin residuos |
| Conteo de líneas | lib 78 / 7,548; test 1 / 159; **total 7,707** (por debajo de 8,000) |

### Prueba real (pendiente)
Mismo bloqueo de la Entrada 4: falta la CLI de Supabase y credenciales.
Comandos exactos:
```powershell
supabase login
supabase link --project-ref <PROJECT_REF>
supabase secrets set GEMINI_API_KEY=<clave>
supabase functions deploy gemini-chat
```
Con la función desplegada, abrir el botón "Asistente" y probar mensajes como
"Hola", "¿Qué me puedes ayudar a hacer?" o "Quiero comprar arroz".

### Futuras mejoras (documentadas, NO implementadas ahora)
Audio, micrófono, subida de imágenes, archivos, cámara, historial persistente,
autenticación específica del chat, streaming, markdown avanzado, animaciones
complejas y el asistente multicriterio completo (Gemini interpreta la
intención y VibeShopping calcula la recomendación con sus datos).

---

## Entrada 6 — Corrección de integración Gemini y prueba real del asistente (2026-08)

### Síntoma
Al enviar un mensaje en la app, la Edge Function respondía
"Gemini respondió 404".

### Diagnóstico (causa exacta del 404)
Se probó la función desplegada y a Gemini directamente con la clave real:

- `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
  → **404 NOT_FOUND** con este mensaje de Google:
  > "This model models/gemini-2.5-flash is no longer available to new users.
  > Please update your code to use a newer model..."

**Causa**: el modelo `gemini-2.5-flash` fue retirado para usuarios nuevos de la
Gemini API (la cuenta/clave del proyecto es nueva). El nombre del modelo en
`index.ts` estaba desactualizado.

Al corregir el modelo apareció un segundo problema en la prueba real: la
API key fue **revocada por Google** (`403: Your API key was reported as
leaked`). La clave vivía en `.env` y `flutter run --dart-define-from-file=.env`
la incrustaba en la app Flutter; Google la marcó como filtrada y la bloqueó.

### Archivo modificado
`supabase/functions/gemini-chat/index.ts` (67 → 75 líneas):
- `MODEL = "gemini-2.5-flash"` → `MODEL = "gemini-3.5-flash"`.
- Manejo de errores mejorado: cuando Gemini responde con error, la función
  ahora incluye el `message` del cuerpo de la respuesta de Gemini (máx. 400
  caracteres), p. ej. `Gemini respondió 403: Your API key was reported as
  leaked...`. Esto permite identificar si el problema es modelo, endpoint,
  autenticación o solicitud.

### Modelo Gemini utilizado
`gemini-3.5-flash` (modelo Flash actual recomendado en la documentación
oficial; `gemini-2.5-flash` ya no está disponible para usuarios nuevos).

### Endpoint utilizado
`POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent`
Formato correcto según la documentación: `models/{model}:generateContent`.
Se mantiene `generateContent` (legacy pero totalmente soportado) en lugar de
la nueva Interactions API para conservar una integración mínima y explicable
(una sola llamada stateless por mensaje, sin historial en el servidor).

### Forma de autenticación
- La Edge Function lee el secret con `Deno.env.get("GEMINI_API_KEY")`
  (verificado con `supabase secrets list`: el secret existe en el proyecto
  `qdcbfqifwsmvmrvmrjgy`).
- La clave viaja en el header `x-goog-api-key`, con `Content-Type: application/json`.
- **La clave no existe en Flutter**: se eliminó `GEMINI_API_KEY` de `.env`
  (`.env` queda solo con `SUPABASE_URL` y `SUPABASE_ANON_KEY`), para que
  `flutter run --dart-define-from-file=.env` no la incruste en el binario.

### Resultado de la prueba real
- Despliegue: `supabase functions deploy gemini-chat` → OK
  ("Deployed Functions", proyecto `qdcbfqifwsmvmrvmrjgy`).
- Llamada real a la función desplegada con
  `{"message":"Hola, responde brevemente en español."}`:
  - Antes de la corrección: `502 {"error":"Gemini respondió 404"}`.
  - Después de la corrección (modelo nuevo): `502 {"error":"Gemini respondió
    403: Your API key was reported as leaked. Please use another API key."}`.
- **Con la clave nueva (secret de Supabase actualizado)**: **200 OK** con
  respuesta válida de Gemini:
  > "¡Hola! Soy VibeShopping Assistant. Te ayudo a orientarte con tus compras
  > de supermercado en Costa Rica. ¿En qué te puedo colaborar hoy?"
- **El flujo real Flutter → Edge Function → Gemini → respuesta queda
  demostrado y funcional.**

### Resultado de `flutter analyze lib/`
**0 issues**.

### Resultado de `flutter test`
**7/7 pass**.

### Líneas actuales del proyecto
lib 78 / 7,548; test 1 / 159; **total 7,707** (por debajo de 8,000).
`index.ts` 75 líneas.

### Dependencias
Ninguna nueva. Sin Firebase. Solo se usó el REST de Gemini desde la Edge
Function (el SDK oficial no se agregó para no introducir dependencias Deno).

### Nota de seguridad
La clave anterior quedó revocada por Google y se eliminó del `.env` local.
La nueva clave debe vivir únicamente como secret de Supabase.

---

## Entrada 7 — Conexión del asistente con datos reales: precios por supermercado (2026-08)

### Síntoma detectado en el diagnóstico
La Edge Function `gemini-chat` respondía **HTTP 500 `Error al consultar el catálogo: [object Object]`**
cuando el mensaje contenía una palabra de producto (p. ej. "arroz"). La prueba real anterior con HTTP 200
solo se había hecho con un mensaje genérico ("hola", stopword) que no consultaba el catálogo.

**Causa exacta (verificada en vivo):** `queryCatalog` seleccionaba las columnas
`supermarket_latitude` y `supermarket_longitude` de la vista `v_products_complete`, y **esa vista no tiene
esas columnas** (PostgREST devuelve 400 → la función devolvía 500). La vista sí expone
`canonical_name, price, supermarket_id, supermarket_name, supermarket_logo_url`; las coordenadas viven
en la tabla `supermarkets` (id, name, latitude, longitude, address).

### Archivo modificado
`supabase/functions/gemini-chat/index.ts` (400 → 434 líneas; desplegada como versión 5).

### Motivo
Que Gemini reciba datos reales de productos y precios. Los precios se consultan en `v_products_complete`
y las coordenadas de los supermercados en `supermarkets`, sin inventar nada.

### Código agregado o modificado
| Cambio | Detalle |
|---|---|
| `queryCatalog` (corregido) | `select` pasa de `canonical_name,price,supermarket_id,supermarket_name,supermarket_latitude,supermarket_longitude` a **solo columnas existentes**: `canonical_name,price,supermarket_id,supermarket_name`. Mantiene el filtro `.or(canonical_name.ilike.%kw%)`. |
| `querySupermarkets` (nuevo) | Consulta `supermarkets` con `select("id,name,latitude,longitude,address")` y devuelve un `Map<supermarket_id, SupermarketRow>`. |
| `CatalogRow` (interface) | Se eliminaron los campos inexistentes `supermarket_latitude`/`supermarket_longitude`. |
| `SupermarketRow` (interface nueva) | `id, name, latitude, longitude, address`. |
| `StoreOffer` | Nuevo campo `address` (dirección del supermercado). |
| `buildOffers` | Firma nueva `buildOffers(rows, supermarkets, transport)`: las coordenadas de cada oferta salen del mapa de `supermarkets`, no de la vista. El resto del cálculo (Haversine, tiempos, score multicriterio) no cambió. |
| Handler `Deno.serve` | `Promise.all([queryCatalog, querySupermarkets])` y `buildOffers(rows, supermarkets, transport)`. |

### Consultas realizadas (las mismas que ejecuta la función)
- `v_products_complete`: `select(canonical_name,price,supermarket_id,supermarket_name)` + `or(ilike)`.
- `supermarkets`: `select(id,name,latitude,longitude,address)`.

### Datos utilizados (verificados contra la BD antes de implementar)
- **Catálogo real (11 productos):** Arroz Grano entero 2 kg, Leche Líquida Entera 1 L, Aceite Vegetal 1 L,
  Atún Trocitos 160 g, Helado de Vainilla 946 ml, Jabón Líquido para manos, Pan Baguette 350 g,
  Pan Cuadrado 600 g, Pechuga de Pollo Deshuesada 1 kg, Posta de Res 1 kg, Uvas Verdes 500 g.
- **Supermercados reales (4, con coordenadas):** Mi Súper (9.3719, -83.7048), Buen Día (9.3675, -83.6964),
  Súper Ahorro (9.3503, -83.6744), Super Vida Saludable (9.3414, -83.6734).
- Posición de referencia del usuario: 9.376, -83.7025 (la misma de `LocationDemoData`).

### Pruebas realizadas (Edge Function desplegada, invocada con la anon key como JWT)
| Mensaje | Resultado |
|---|---|
| `{"message":"¿Cuánto cuesta el arroz en los supermercados?","transport":"car"}` | **200 OK**. Precios exactos de la BD: Super Vida Saludable ₡1.100 (5.00 km, 10 min carro), Súper Ahorro ₡1.175 (4.20 km, 9 min), Buen Día ₡1.300 (1.16 km, 3 min), Mi Súper ₡1.350 (0.52 km, 2 min). |
| `{"message":"¿cuánto cuesta la leche?","transport":"walking"}` | **200 OK**. Súper Ahorro ₡900 (4.20 km, 51 min a pie), Super Vida Saludable ₡1.000 (5.00 km, 60 min), Mi Súper… (precio visible). |

Distancias y tiempos verificados a mano con Haversine (coinciden con las reales); el puntaje multicriterio
existente eligió a Mi Súper para el arroz en carro (precio 0.6 / distancia 0.4) — coherente con la lógica.

### Verificación local
| Prueba | Resultado |
|---|---|
| `flutter pub get` | OK (sin cambios de dependencias) |
| `dart format --output=none` (solo reporta) | Reporta drift preexistente en `location_demo_data.dart` y `shopping_assistant_logic_test.dart`; **no se tocaron** (fuera de alcance, se respeta el historial) |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **10/10 pass** (7 del motor + 3 de cesta) |
| Sintaxis TS (`npx esbuild`) | OK |
| Despliegue | `supabase functions deploy gemini-chat` → versión **5** activa |

### Estado
- Fase 1 (precios por supermercado) funcional de punta a punta: Flutter → Edge Function → datos reales →
  contexto estructurado → Gemini → respuesta con los números exactos del catálogo.
- Las estructuras existentes para distancias (Haversine), transporte y puntaje multicriterio ya estaban en la
  función y quedan **activas** con coordenadas reales (no se eliminó funcionalidad).
- **Siguiente etapa pendiente de aprobación:** probar "¿Dónde me conviene comprar arroz?" (distancia) y
  "arroz y leche en carro" (cesta + transporte + multicriterio) con las mismas estructuras.

---

## Entrada 8 — Fases 2 y 3: distancia, transporte y cesta multicriterio (2026-08)

### Qué se hizo
Verificar de punta a punta las consultas de recomendación con las estructuras ya existentes en la Edge
Function (Haversine, pesos por transporte, cobertura de cesta y puntaje multicriterio), ahora que el
catálogo y las coordenadas se consultan con datos reales. Se detectó y corrigió un **recorte de respuesta**
en las consultas de cesta.

### Archivo modificado
`supabase/functions/gemini-chat/index.ts` (434 → 434 líneas con un cambio puntual; desplegada como versión 6).

### Motivo del cambio puntual
`generationConfig.maxOutputTokens` era **1024**. En las consultas de un solo producto (fases 1 y 2) la
respuesta cabía; en la cesta de dos productos (fase 3) la respuesta de Gemini **se cortaba a mitad de texto**
(se observó truncada en "0.52", "Super…"). Se aumentó a **2048** para respuestas completas.

### Código modificado
```ts
generationConfig: { temperature: 0.7, maxOutputTokens: 2048 },
```

### Consultas realizadas y resultados (Edge Function desplegada v6, invocada con la anon key)
| Consulta | Transporte | Resultado |
|---|---|---|
| "¿Dónde me conviene comprar arroz?" | `car` | **200 OK.** Precios exactos + distancia real por tienda + recomendación: Mi Súper (₡1.350, 0.52 km, 2 min en carro). |
| "¿Dónde me conviene comprar arroz y leche si voy en carro?" | `car` | **200 OK (completa).** Cesta: Mi Súper ₡2.400 total (arroz ₡1.350 + leche ₡1.050), 0.52 km, 2 min, ahorro ₡60. Incluye alternativas individuales por producto con precios reales. |
| "¿Dónde me conviene comprar arroz y leche caminando?" | `walking` | **200 OK.** Recomienda Mi Súper (la más cercana, 0.52 km), coherente con los pesos a pie (0.3 precio / 0.7 distancia). |

### Verificación de la lógica (manual, contra la BD)
- **Cesta carro (arroz+leche):** totales por tienda — Super Vida Saludable ₡2.100 (5.00 km), Súper Ahorro
  ₡2.075 (4.20 km), Buen Día ₡2.460 (1.16 km), Mi Súper ₡2.400 (0.52 km).
  Puntaje (0.6 precio / 0.4 distancia): Mi Súper 0.919 (gana), Buen Día 0.685, Súper Ahorro 0.650, SVS 0.635.
  Ahorro = 2.460 − 2.400 = **₡60**. Todo coincide con lo que respondió Gemini.
- **A pie:** Mi Súper 0.959 (0.3/0.7) → la más cercana, como se espera. En este conjunto de datos Mi Súper
  domina por su cercanía extrema; el cambio de criterio carro→a pie está cubierto por los tests unitarios
  (con datos sintéticos: carro elige la barata lejos, a pie la cerca cara).

### Verificación local
| Prueba | Resultado |
|---|---|
| Sintaxis TS (`npx esbuild`) | OK |
| `supabase functions deploy gemini-chat` | OK → versión **6** activa |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **10/10 pass** |

### Estado
Las tres fases planificadas quedan funcionales con datos reales:
1. Precios por supermercado ("¿Cuánto cuesta el arroz?") ✓
2. Precios + supermercados + distancia ("¿Dónde me conviene comprar arroz?") ✓
3. Cesta múltiple + transporte + multicriterio ("arroz y leche en carro") ✓

El transporte se interpreta en Flutter (`_detectTransport`, chips + texto del mensaje) y se envía como
`transport` a la función; el diseño actual (botón `Icons.arrow_upward`, chips Carro/Bus/Bici/A pie) no se
modificó. Sin tablas nuevas, sin Firebase, sin otras APIs de IA.

---

## Entrada 9 — Transporte conversacional: la Edge Function detecta, pregunta y continúa (2026-08)

### Qué se hizo
Convertir el transporte en parte de la conversación: la Edge Function `gemini-chat` detecta el transporte
en los mensajes del usuario, pregunta por él cuando falta (solo si la consulta necesita distancia/tiempo) y,
cuando el usuario responde (p. ej. "en carro"), **continúa la consulta anterior** sin repetirla. El botón de
envío se mantiene sin cambios (`Icons.arrow_upward`); los chips ya no son necesarios funcionalmente y se retiraron.

### Archivos modificados
| Archivo | Cambio |
|---|---|
| `supabase/functions/gemini-chat/index.ts` | Reescrita parte del flujo para transporte conversacional (desplegada como versión 7) |
| `lib/features/shopping_assistant/shopping_assistant_screen.dart` | Eliminado `_transport`, `_detectTransport`, `_transportLabel` y la barra de chips; `_send()` envía el historial completo (`messages`) y no depende de chips |

### Código de la Edge Function (nuevo o modificado)
- **Stopwords ampliadas:** se agregaron `queda, quedar, quedan, cerca, lejos, distancia, cercana, cercano,
  cercanas, cercanos, cerca de` para que "¿dónde queda más cerca?" no dispare una consulta vacía.
- **`SYSTEM_PROMPT` reescrito:** reglas para preguntar transporte solo cuando la consulta requiere
  distancia/tiempo **y** el bloque dice `Transporte del usuario: no indicado`; NO preguntar en consultas de
  precio ("¿Cuánto cuesta X?", "¿Dónde está más barato X?"); usar el transporte del mensaje si ya está; al
  responder "en carro" continuar con la nueva consulta sin repetir la pregunta.
- **`detectTransport(messages)` (nueva):** regex normalizada sin tildes sobre todo el historial del usuario:
  `a pie|caminando|caminar|camine|andando` → `walking`; `bici|bicicleta` → `bike`; `bus|autobus` → `bus`;
  `carro|auto|vehiculo|manej|conduc` → `car`. `car` va **último** y usa `\b` para evitar falsos positivos
  (p. ej. "buscamos" → bus).
- **`extractKeywordsFromMessages(messages)` (nueva):** extrae y deduplica las palabras de producto de toda la
  conversación para que "en carro" continúe la consulta anterior.
- **`buildOffers(rows, supermarkets, transport)`:** sin transporte → no calcula `travelMinutes` ni `score`
  (nada inventado); con transporte → cálculo idéntico al anterior (Haversine, tiempos, pesos multicriterio).
- **`buildContext(offers, transport)`:** con transporte desconocido emite el bloque
  `Transporte del usuario: no indicado`, omite tiempos y la "Recomendación de VibeShopping"; con transporte
  usa `transportLabel(transport)` en la línea de tiempo.
- **Handler `Deno.serve` reescrito:** acepta `body.messages` (`[{role: user|assistant, text}]`, último turno
  = mensaje actual), con fallback a `body.message` para compatibilidad con llamadas viejas;
  `transport = detectTransport(messages) ?? bodyTransport`; los keywords salen de toda la conversación; los
  `contents[]` multi-vuelta para Gemini (último turno lleva `dataPart` adjunto; `assistant`→`model`,
  `user`→`user`).

### Escenarios probados (Edge Function desplegada v7, invocada con la anon key)
| # | Escenario | Resultado |
|---|---|---|
| 1 | "¿Dónde me conviene comprar arroz?" (sin transporte) | **200 OK.** Precios + km por tienda y pregunta "¿cómo te vas a transportar? Carro, bus, bici o a pie". Sin tiempos ni recomendación (no se inventan). |
| 2 | "¿Dónde me conviene comprar arroz si voy en carro?" | **200 OK.** Usa `car` directo: recomendación Mi Súper (₡1.350, 0.52 km, 2 min en carro) + alternativas con tiempo. |
| 3 | "¿Dónde me conviene comprar arroz y leche?" (sin transporte) | **200 OK.** Cesta completa por tienda y pregunta transporte. |
| 4 | Respuesta "En carro." tras la pregunta (2 turnos previos) | **200 OK.** **Continúa la cesta anterior**: Mi Súper ₡2.400 (arroz ₡1.350 + leche ₡1.050), 0.52 km, 2 min, ahorro ₡60. No repite la pregunta ni los productos. |
| 5 | "¿Cuánto cuesta el arroz?" | **200 OK.** Solo precios. **No pregunta transporte** (no requiere distancia). |
| 6 | "¿Dónde está más barato el arroz?" | **200 OK.** Solo el más barato (SVS ₡1.100). **No pregunta transporte**. |
| 7 | "…si voy caminando" | **200 OK.** Usa `walking`: Mi Súper 0.52 km, 7 min a pie, con "Recomendación de VibeShopping". |

Distancias y tiempos verificados a mano: 0.52 km a pie → 7 min (5 km/h), carro → 2 min (30 km/h);
coherentes con los de las fases anteriores.

### Verificación local
| Prueba | Resultado |
|---|---|
| Sintaxis TS (`npx esbuild`) | OK |
| `supabase functions deploy gemini-chat` | OK → versión **7** activa |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **10/10 pass** |
| `dart format` (solo `shopping_assistant_screen.dart`) | OK (0 cambios) |

### Estado
El transporte ya no depende de chips: se resuelve en la conversación. La lógica de precios, Haversine,
tiempos y puntaje multicriterio no cambió (solo se omite cuando no hay transporte, para no inventar). Los
tests del motor (`shopping_assistant_logic.dart`) no se tocaron. Sin tablas nuevas, sin Firebase, sin otras
APIs de IA.

---

## Entrada 10 — Botón de envío compacto, manejo amigable de HTTP 429 y respuestas en texto plano (2026-08)

### Qué se hizo
Tres correcciones detectadas en una prueba visual del chat:

1. **Botón de envío desproporcionado:** el `IconButton.filled` pintaba un círculo navy grande (40 px con
   ícono de 24 px). Se compactó a 38 px con ícono de 20 px, centrado y alineado con el campo de texto. El
   ícono se mantiene: `Icons.arrow_upward`. No hay contenedor circular extra detrás del botón: el círculo es
   el propio estilo `filled` de Material 3, así que se redujo el estilo en vez de eliminar capas.
2. **Error de Gemini 429 mostrado en bruto:** la Edge Function devolvía
   `Gemini respondió 429: You exceeded your current quota…` y Flutter lo mostraba tal cual. Ahora el 429 se
   traduce a un mensaje sencillo y el detalle técnico va a los logs de la función.
3. **Markdown sin procesar:** Gemini respondía con `**Arroz…**` y `* **Super Vida Saludable**`. Se eligió la
   opción A (pedir a Gemini texto plano en el `SYSTEM_PROMPT`) por ser la más sencilla y coherente con el
   MVP: cero dependencias nuevas, sin migración del renderizado.

### Archivos modificados
| Archivo | Cambio |
|---|---|
| `lib/features/shopping_assistant/shopping_assistant_screen.dart` | Botón compacto y mensaje amigable para 429 |
| `supabase/functions/gemini-chat/index.ts` | Rama 429 con código claro + detalle en logs; `SYSTEM_PROMPT` en texto plano (desplegada como versión 8) |

### Código modificado
**Flutter — botón de envío (`_buildInput`):**
```dart
IconButton.filled(
  onPressed: _loading ? null : _send,
  style: IconButton.styleFrom(
    backgroundColor: VibeColors.navy,
    foregroundColor: Colors.white,
    visualDensity: VisualDensity.compact,
    minimumSize: const Size(38, 38),
    maximumSize: const Size(38, 38),
    padding: EdgeInsets.zero,
  ),
  icon: const Icon(Icons.arrow_upward, size: 20),
),
```

**Flutter — manejo de 429 (`_describeError`):**
```dart
if (error is FunctionException) {
  if (error.status == 429) {
    return 'En este momento el asistente alcanzó el límite temporal de consultas. '
        'Intenta nuevamente en unos segundos.';
  }
  // resto de códigos sin cambios…
}
```
Solo se personaliza el 429; otros códigos (502, 500, 400, red, …) conservan el comportamiento anterior.

**Edge Function — rama 429 (antes de devolver el error genérico):**
```ts
if (geminiRes.status === 429) {
  console.error(`Gemini 429 (límite temporal de solicitudes): ${detail}`);
  return json({ error: "rate_limit_exceeded" }, 429);
}
```
El detalle técnico de Google queda en los logs de la Edge Function (dashboard) vía `console.error`;
Flutter ya no lo muestra al usuario.

**Edge Function — `SYSTEM_PROMPT` en texto plano:**
```
Responde en español, corto y claro, en texto plano (sin formato Markdown: no uses negritas
con **, asteriscos *, encabezados # ni enlaces []( )), y NUNCA inventes datos.
```

### Revisión de llamadas a Gemini en el flujo
"Quiero comprar arroz" → asistente pregunta transporte → "en carro" → recomendación final.

- **Son 2 llamadas a Gemini, una por turno del usuario** (turno 1: preguntar transporte; turno 2:
  recomendación final). Cada una es necesaria: el asistente debe responder a cada mensaje.
- **El producto se conserva entre turnos** porque el historial (`messages[]`) se reenvía completo y la Edge
  Function re-extrae las palabras de producto de toda la conversación (`extractKeywordsFromMessages`), por lo
  que "en carro" no repite el producto.
- **La Edge Function es stateless:** en cada turno re-consulta `v_products_complete` + `supermarkets`. No es
  una consulta innecesaria: es la única forma de obtener datos reales y actuales sin estado entre
  invocaciones (y evita depender de datos cacheados que podrían quedar obsoletos).

### Datos verificados (mantenidos intactos)
- `v_products_complete` y `supermarkets`, Haversine, precios reales, distancias reales, tiempos estimados y
  la lógica multicriterio. No se crearon tablas nuevas ni se cambió el motor de recomendación.

### Pruebas (Edge Function desplegada v8, invocada con la anon key)
| Prueba | Resultado |
|---|---|
| Turno 1 "Quiero comprar arroz" | **200 OK.** Texto plano (sin `**` ni `*`): opciones con precio y distancia por tienda (SVS ₡1.100 5.00 km, Súper Ahorro ₡1.175 4.20 km, Buen Día ₡1.300 1.16 km, Mi Súper ₡1.350 0.52 km) + pregunta de transporte. |
| Turno 2 "En carro." (historial completo) | La recomendación final quedó pendiente por **límite temporal real de Gemini (429)** durante la sesión; el flujo de recomendación con carro ya fue verificado en la Entrada 9 (escenario 4). |
| Invocación bajo límite de Gemini | La función devuelve **HTTP 429** con `{"error":"rate_limit_exceeded"}` y el detalle técnico va a los logs; Flutter mostrará el mensaje sencillo. Se confirmó la respuesta real del endpoint. |

### Verificación local
| Prueba | Resultado |
|---|---|
| `dart format` (`shopping_assistant_screen.dart`) | OK (0 cambios) |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **10/10 pass** |
| Sintaxis TS (`npx esbuild`) | OK |
| `supabase functions deploy gemini-chat` | OK → versión **8** activa |

### Notas
- El límite 429 (`You exceeded your current quota`, limit: 20, `gemini-3.5-flash`) es un límite temporal del
  proveedor por minuto; se agotó durante las pruebas y se recupera solo. No se tocó la lógica de precios,
  supermercados, distancia ni transporte por este error.
- No se modificaron Ubicación ni otras features.

---

## Entrada 11 — Refinamiento conversacional: regla de transporte en el prompt y verificación exhaustiva del contexto (2026-08)

### Qué se hizo
Revisar el flujo conversacional actual y confirmar dónde se conserva el contexto entre mensajes, afinar el
`SYSTEM_PROMPT` para que el asistente pregunte transporte solo cuando la recomendación requiera distancia y
el usuario responda directamente en el chat, y ejecutar una batería real de conversaciones de punta a punta
(consulta de producto, pregunta de transporte, recomendación por transporte, cesta con varios productos y
cambio de transporte dentro de la misma conversación).

### Por qué se hizo
La arquitectura conversacional (mensaje+historial → intención → transporte → datos reales → Gemini) ya
estaba implementada en las Entradas 7–10. Esta fase la refinó y la verificó de forma exhaustiva: asegurar
que el asistente **solo pregunta transporte cuando hace falta** y que **el contexto y el producto se
conservan** aunque el transporte llegue en un mensaje aparte o cambie a mitad de conversación.

### Dónde se conserva el contexto (verificado antes de editar)
- **Flutter** (`_send`): reenvía todo el historial `messages` (sin mensajes de error) en cada turno.
- **Producto**: la Edge Function junta las palabras de producto de **todos** los turnos del usuario
  (`extractKeywordsFromMessages`), por eso "En carro." o "Voy caminando." revuelven "arroz" del turno 1.
- **Transporte**: `detectTransport` examina todos los turnos; un cambio a mitad de conversación
  ("¿y si voy a pie?") se detecta en el último turno y recalcula con el transporte nuevo.

### Función modificada (qué cambió)
`SYSTEM_PROMPT` en `supabase/functions/gemini-chat/index.ts` (desplegada como versión 9). Regla de
transporte reescrita:
- Preguntar SOLO si la respuesta requiere recomendar por distancia/tiempo Y el bloque dice
  `Transporte del usuario: no indicado` ("¿Dónde me conviene comprar X?", "¿Cuál supermercado queda más
  cerca?").
- El usuario responde directamente en el chat: "en carro", "en bus", "en bici", "a pie".
- NO preguntar si la consulta es de precios o compara precios ("¿Cuánto cuesta X?", "¿Dónde está más
  barato X?", "quiero gastar lo menos posible", "lo más barato"), ni si el transporte ya está indicado.
- Al responder con transporte, continuar con la nueva consulta (no repetir la pregunta anterior).

### Archivos modificados
| Archivo | Cambio |
|---|---|
| `supabase/functions/gemini-chat/index.ts` | Solo `SYSTEM_PROMPT` (regla de transporte) → desplegada v9 |

No se modificó Flutter (la pantalla y el botón `Icons.arrow_upward` quedaron igual), ni la base de datos,
ni `shopping_assistant_logic.dart`/`shopping_assistant_data.dart` (se conservan como referencia del
algoritmo multicriterio y tienen 10 tests unitarios; la fuente viva de la recomendación es la Edge
Function).

### Pruebas reales de conversación (Edge Function v9, invocada con la anon key)
| # | Conversación | Resultado |
|---|---|---|
| 1 | "¿Cuánto cuesta el arroz?" | **200 OK.** Solo precios reales (SVS ₡1.100, S. Ahorro ₡1.175, Buen Día ₡1.300, Mi Súper ₡1.350). **No pregunta transporte.** |
| 2 | "¿Dónde me conviene comprar arroz?" | **200 OK.** Precios + km por tienda y pregunta "¿cómo te vas a transportar? (en carro, en bus, en bici o a pie)". |
| 3 | … "En carro." (mensaje separado) | **200 OK.** Recomendación en carro: Mi Súper ₡1.350, 0.52 km, 2 min; alternativas con tiempos reales. |
| 4 | "Quiero comprar arroz y leche." | **200 OK.** Cesta por tienda (ambos productos) + pregunta transporte. |
| 5 | … "Voy caminando." (mensaje separado) | **200 OK.** Cesta a pie: Mi Súper ₡2.400 (arroz ₡1.350 + leche ₡1.050), 0.52 km, 7 min, ahorro ₡60. |
| 6 | Cambio de transporte: carro → "¿Y si voy a pie?" dentro de la misma conversación | **200 OK** (tras un 503 temporal del proveedor). Mantiene "arroz" y responde con la recomendación/ distancias a pie (Mi Súper 0.52 km). |
| 7 | "¿Cuánto cuesta el caviar?" (producto inexistente) | **200 OK.** **No inventa**: "no encontré caviar en el catálogo… prefiero no inventar datos" y ofrece ayuda. |
| 8 | "Quiero comprar arroz, leche y pan." (varios productos) | **200 OK.** Reconoce la cesta (arroz, leche y los panes) y pregunta transporte. |
| 9 | "Quiero comprar arroz y leche, pero voy caminando." (transporte inline) | **200 OK.** Usa `walking` directo: Mi Súper ₡2.400, 0.52 km, 7 min a pie, ahorro ₡60; alternativas con tiempos (60/51/14 min). |

Tiempos verificados a mano (Haversine + velocidad): 0.52 km → 2 min carro (30 km/h) / 7 min a pie (5 km/h);
coherentes con las fases anteriores.

### Excepción de infraestructura observada
Durante el test 6, Gemini devolvió un **503 (high demand)** temporal que la función propagó como 502; se
reintentó y pasó. No es un defecto del código, es la política del proveedor.

### Verificación local
| Prueba | Resultado |
|---|---|
| Sintaxis TS (`npx esbuild`) | OK |
| `supabase functions deploy gemini-chat` | OK → versión **9** activa |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **10/10 pass** |

Sin tablas nuevas, sin Firebase, sin dependencias nuevas. No se modificaron `manual_lists`, Ubicación ni
otras features.

---

## Entrada 12 — Modelo deprecado corregido, reintentos 5xx y mensaje amigable para 503 (2026-10)

### Síntoma reportado
El asistente respondía error. El usuario sospechaba API vencida o modelo inexistente.

### Diagnóstico (verificado en vivo, sin tocar código)
| Verificación | Resultado |
|---|---|
| Secret `GEMINI_API_KEY` en Supabase | Presente y activo (2026-08-12) — la key **no** está vencida |
| Saludo "hola" | 200 OK en algunas llamadas → la key funciona |
| Muestreo de llamadas con producto | ~25 % de éxito; el resto **503** "This model is currently experiencing high demand" |
| Error real tras deprecación | **HTTP 404** `This model models/gemini-2.0-flash is no longer available. Please update your code to use models/gemini-3.8-flash` |
| Conclusión | **El modelo `gemini-2.0-flash` fue deprecado por Google** → 404. Además, cuando sí respondía, `gemini-3.5-flash` estaba en sobrecarga (503). El error técnico en inglés viajaba crudo hasta Flutter, que lo mostraba como si la API estuviera vencida |

### Qué se hizo (causa raíz + robustez)
1. **Modelo actualizado** en `supabase/functions/gemini-chat/index.ts`:
   `MODEL = "gemini-2.0-flash"` → **`gemini-3.8-flash`** (el nombre que Google indica explícitamente en el 404).
2. **Reintentos para errores transitorios de servidor**: nueva función `callGemini(apiKey, contents)` que
   reintenta hasta 3 veces (esperas 0 / 1.5 s / 3 s) cuando Gemini devuelve HTTP **500, 502, 503 o 504**.
   HTTP **429 no se reintenta** (se devuelve tal cual para el mensaje de límite temporal ya existente).
3. **Mensaje amigable para sobrecarga en Flutter**: tras agotar los reintentos, la EF devuelve
   **HTTP 503** con `{"error":"model_overloaded"}` (el detalle técnico se registra con `console.error`);
   la app muestra: *"El asistente está saturado en este momento. Intenta nuevamente en unos segundos."*
   (mismo patrón que el 429). Otros códigos HTTP conservan su manejo anterior (no se ocultan).

### Archivos modificados
| Archivo | Cambio |
|---|---|
| `supabase/functions/gemini-chat/index.ts` | `MODEL` → `gemini-3.8-flash`; helper `callGemini` con reintentos; normalización 429/503 (desplegada como versión 14) |
| `lib/features/shopping_assistant/shopping_assistant_provider.dart` | Rama `status == 503` en `_describeError` con el mensaje amigable (junto a la de 429) |

Nota: el manejo de errores de la pantalla vive ahora en `shopping_assistant_provider.dart`
(reestructuración previa del chat: `screen → provider → service`), por eso la corrección de Flutter se
aplicó ahí, no en la pantalla.

### Código clave (Resumen)
```ts
// Edge Function: reintentos y normalización de errores.
const GEMINI_MAX_ATTEMPTS = 3;
const GEMINI_RETRY_DELAYS_MS = [0, 1500, 3000];
// ... callGemini(): reintenta 500/502/503/504 con espera corta; 429 se devuelve igual ...
// Tras agotar reintentos de 500/502/503/504:
return json({ error: "model_overloaded" }, 503);
```
```dart
// Provider (Flutter): mensaje amigable para 503.
if (error.status == 503) {
  return 'El asistente está saturado en este momento. '
      'Intenta nuevamente en unos segundos.';
}
```

### Por qué se hizo
El modelo `gemini-2.0-flash` ya no existe en la API (404). Cambiarlo al modelo recomendado por Google
restaura el servicio; los reintentos reducen la tasa de fallo ante 503/500 transitorios y el mensaje
amigable evita confundir al usuario con texto técnico en inglés.

### Verificación local
| Prueba | Resultado |
|---|---|
| Sintaxis TS (`npx esbuild`) | OK |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **10/10 pass** |
| `supabase functions deploy gemini-chat` | OK → versión **14** activa (prompt reforzado/revocado en la sesión; estado final desplegado como versión **16**) |

### Pruebas reales (Edge Function v14, invocada con la anon key)
| Prueba | Resultado |
|---|---|
| "hola" | **200 OK.** Respuesta normal en español (texto plano). |
| "¿Dónde me conviene comprar arroz?" | **200 OK.** Precios reales + km por tienda (SVS ₡1.100 5.00 km, S. Ahorro ₡1.175 4.20 km, Buen Día ₡1.300 1.16 km, Mi Súper ₡1.350 0.52 km) y pregunta de transporte. |
| Bajo límite de cuota (20/min) | **HTTP 429** `{"error":"rate_limit_exceeded"}` → app muestra el mensaje de límite temporal (diseño previo intacto). |
| Cesta + "en carro" (confirmación final) | No ejecutada en vivo: la cuota 429 (20/min) se agotó durante la sesión de pruebas. La funcionalidad es la misma ya verificada en las Entradas 9 y 11; solo cambió el modelo (200 OK arriba). |

### Aclaración posterior: la opción "Motocicleta" del prompt era correcta
Al revisar el código a fondo, la Edge Function **sí soporta "moto" de forma completa y consistente**:
- `SPEED_KMH.moto = 35` (km/h) y `WEIGHTS.moto = { price: 0.6, distance: 0.4 }` (`index.ts:35,43`).
- `TRANSPORT_LABELS.moto = "Motocicleta"` y `detectTransport` reconoce `moto`/`motocicleta` (`index.ts:51,194`).
- La lista blanca de transportes del body incluye `"moto"` junto a car/bus/bike/walking (`index.ts:519`).

Por eso la pregunta original de Gemini "(Bus, Carro, Motocicleta, Bicicleta, Caminando)" era **coherente
con el código**. Durante la sesión se probó un refuerzo del prompt para listar solo 4 opciones (sin moto)
y se revirtió de inmediato al confirmar el soporte de "moto": el prompt quedó exactamente como estaba
(desplegado como versión **16**, idéntico en contenido y hash a la versión 14). No hubo cambios de
comportamiento: solo se evitó una restricción incorrecta.

Sin tablas nuevas, sin Firebase, sin dependencias nuevas. No se modificaron precios, distancias, transporte,
`manual_lists`, Ubicación ni otras features.

---

## Entrada 13 — "Límite alcanzado" en una sola petición: cuota diaria de 20 y cambio a `gemini-3.5-flash-lite` (2026-10)

### Síntoma reportado
La app mostraba el mensaje "el asistente alcanzó el límite" apenas se enviaba una petición. Pregunta del
usuario: ¿por qué se gasta en una sola petición?

### Diagnóstico (429 en vivo con el detalle de Google)
Se añadió temporalmente el `detail` de Google a la respuesta 429 para leer la métrica exacta:

```
Quota exceeded for metric: generativelanguage.googleapis.com/generate_content_free_tier_requests,
limit: 20, model: gemini-3.8-flash
Please retry in 23h56m30s
```

| Hallazgo | Significado |
|---|---|
| `limit: 20`, `model: gemini-3.8-flash` | El tier gratuito de **`gemini-3.8-flash` admite 20 solicitudes por día** (RPD) por proyecto |
| `Please retry in 23h56m30s` | La cuota se libera a **medianoche (hora del Pacífico)**, no en un minuto |
| Quién la agotó | **Nuestras propias pruebas de verificación** de las versiones 14–16 de hoy; no una sola petición del usuario |

Es decir: una petición **no** gasta todo el cupo. El cupo diario ya estaba consumido por las pruebas de
despliegue, y cualquier mensaje de la app dentro de esa ventana devolvía 429.

### Búsqueda de un modelo con cupo mayor
| Prueba | Resultado |
|---|---|
| Cabeceras `x-goog-quota-*` en la respuesta | **No existen** en la API de Gemini (vaciadas; se revirtió el diagnóstico) |
| `gemini-2.5-flash` | **404**: "no longer available to new users" → recomienda `gemini-3.8-flash` |
| `gemini-3.5-flash-lite` | **200 OK.** Responde correctamente. Límites publicados 2026: ~**500 solicitudes/día** (frente a 20 de `gemini-3.8-flash`) |

### Cambios realizados
| Archivo | Cambio |
|---|---|
| `supabase/functions/gemini-chat/index.ts` | `MODEL = "gemini-3.5-flash-lite"` (antes `gemini-3.8-flash`); `callGemini` reintenta **429 una sola vez** (+2 s) para absorber picos por minuto (el límite diario no se resuelve reintentando); se conserva `detail` en la respuesta 429 **solo para diagnóstico** (Flutter no lo muestra); se eliminó el diagnóstico temporal de cabeceras. Desplegada como versión **22** |

Reglas de reintento resultantes: 500/502/503/504 → hasta 3 intentos (esperas 0/1,5 s/3 s); **429 → 1
reintento a los 2 s** y si persiste se devuelve el 429 amigable ya existente en Flutter.

### Por qué se hizo
El asistente debe responder correctamente. Con `gemini-3.8-flash` (20/día) cualquier uso real más las
pruebas agotaba el cupo y rompía el chat hasta el día siguiente. `gemini-3.5-flash-lite` mantiene la
misma API y un cupo diario ~25 veces mayor; es un modelo ligero adecuado para este chat (todo el dato real
viene de Supabase y el prompt es corto).

### Verificación local
| Prueba | Resultado |
|---|---|
| Sintaxis TS (`npx esbuild`) | OK |
| `flutter analyze lib/` | **0 issues** |
| `flutter test` | **10/10 pass** |
| `supabase functions deploy gemini-chat` | OK → versión **22** activa |

### Pruebas reales (Edge Function v22, con `gemini-3.5-flash-lite`)
| Prueba | Resultado |
|---|---|
| "hola" | **200 OK.** Saludo normal en español. |
| "¿Dónde me conviene comprar arroz?" | **200 OK.** Precios reales (SVS ₡1.100, S. Ahorro ₡1.175, Buen Día ₡1.300, Mi Súper ₡1.350) y pregunta de transporte. |

### Notas
- Los límites gratuitos son **por proyecto y por modelo** y Google puede cambiarlos sin aviso; el valor
  definitivo siempre está en Google AI Studio.
- Nuestras pruebas en vivo consumen el cupo del usuario: minimizar llamadas de verificación.
- Para eliminar la restricción de cuota en producción: activar billing (Tier 1) en el proyecto de Google.
- No se modificaron precios, distancias, lógica de transporte, `manual_lists` ni otras features; Dart quedó
  intacto en esta entrada.
