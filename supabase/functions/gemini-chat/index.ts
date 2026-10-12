// Edge Function `gemini-chat`:
// Flutter → Edge Function → Supabase (v_products_complete + supermarkets)
// → cálculo de distancias (Haversine) y puntaje multicriterio → Gemini redacta → Flutter.
//
// Conversacional: recibe el historial de la conversación (messages[]) y detecta
// el medio de transporte en cualquier turno del usuario (sin depender de chips).
// Si el transporte es desconocido, el contexto omite tiempos y recomendación y
// Gemini pregunta el transporte antes de recomendar.
//
// Los precios vienen de la vista `v_products_complete` y las coordenadas de la
// tabla `supermarkets` (la vista NO expone latitud/longitud).
//
// Seguridad:
//   - GEMINI_API_KEY vive como secret de Supabase (Deno.env.get), nunca en Flutter.
//   - El catálogo se consulta desde aquí con SUPABASE_SERVICE_ROLE_KEY (server-side).
//   - A Gemini solo se le envía el contexto calculado (productos, precios,
//     distancias, tiempos). Nunca credenciales ni SQL.

import { createClient } from "npm:@supabase/supabase-js";

const MODEL = "gemini-3.5-flash-lite";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// Posición fija de referencia del usuario (centro de San Isidro), la misma
// que usa LocationDemoData en Flutter. En una versión real se usaría GPS.
const USER_LATITUDE = 9.376;
const USER_LONGITUDE = -83.7025;

// Velocidades (km/h) y pesos precio/distancia por transporte, igual que
// ShoppingAssistantLogic (Dart).
const SPEED_KMH: Record<string, number> = {
  car: 30,
  bus: 20,
  moto: 35,
  bike: 15,
  walking: 5,
};

const WEIGHTS: Record<string, { price: number; distance: number }> = {
  car: { price: 0.6, distance: 0.4 },
  bus: { price: 0.5, distance: 0.5 },
  moto: { price: 0.6, distance: 0.4 },
  bike: { price: 0.4, distance: 0.6 },
  walking: { price: 0.3, distance: 0.7 },
};

const TRANSPORT_LABELS: Record<string, string> = {
  car: "Carro",
  bus: "Bus",
  moto: "Motocicleta",
  bike: "Bicicleta",
  walking: "Caminando",
};

// Palabras que no son productos: artículos, pronombres, verbos de compra,
// contexto de tiendas, saludos y medios de transporte (sin tildes).
const STOPWORDS = new Set<string>([
  "el", "la", "los", "las", "un", "una", "unos", "unas",
  "de", "del", "al", "a", "en", "para", "por", "con", "sin", "sobre", "entre",
  "y", "o", "u", "e",
  "que", "cual", "cuales", "cualquier", "quien", "como", "cuando", "donde",
  "cuanto", "cuanta", "cuantos", "cuantas",
  "es", "son", "somos", "soy", "estoy", "esta", "estas", "estamos", "estan",
  "estar", "ser", "hay", "tengo", "tienes", "tiene", "tenemos", "tienen",
  "quiero", "quieres", "quiere", "queremos", "necesito", "necesitas",
  "necesita", "necesitamos",
  "me", "te", "se", "lo", "le", "les", "mi", "tu", "su", "mis", "tus", "sus",
  "nuestro", "nuestra", "nuestros", "nos", "ya", "mas", "menos", "muy",
  "bien", "tan", "todo", "toda", "todos", "todas",
  "comprar", "compre", "compras", "compra", "compraria", "vender", "venden",
  "vende", "cuesta", "cuestan", "costar", "costo", "pagar", "precio", "precios",
  "barato", "barata", "baratos", "baratas", "economico", "economica",
  "mejor", "buen", "buena", "buenos", "buenas",
  "conviene", "convienen", "conveniente", "recomienda", "recomiendan",
  "recomendado", "recomiendame", "sugiere", "sugiereme", "aconseja",
  "aconsejame", "dime", "digan", "decir", "hacer", "hago",
  "puedes", "puedo", "puede", "buscar", "busco", "encuentro", "consigo",
  "supermercado", "supermercados", "tienda", "tiendas", "abastecedor",
  "abastecedores", "catalogo",
  "carro", "carros", "auto", "autos", "carrito", "bus", "buses",
  "autobus", "autobuses", "bicicleta", "bicicletas", "bici",
  "caminando", "caminar", "camine", "pie", "manejando", "manejar", "manejo",
  "maneja", "moto", "motos", "voy", "vas", "vamos", "van", "ir",
  "porque", "entonces", "tambien", "si", "no", "pero", "aqui", "alli",
  "ahora", "hoy", "hola", "saludos", "gracias", "ayuda", "ayudame", "hey", "tal",
  "algo", "algun", "alguna", "algunos", "algunas", "nada", "nadie", "nunca",
  "siempre", "lista", "listas", "ahorro", "gastar", "gasto", "gastos",
  "casa", "hogar", "semana", "dia", "dias",
  "queda", "quedar", "quedan", "cerca", "lejos", "distancia", "cercana",
  "cercano", "cercanas", "cercanos", "cerca de",
]);

const SYSTEM_PROMPT =
  "Eres 'VibeShopping Assistant', un asistente de compras de supermercados de Costa Rica. " +
  "Responde en español, corto y claro, en texto plano (sin formato Markdown: no uses negritas " +
  "con **, asteriscos *, encabezados # ni enlaces []( )), y NUNCA inventes datos.\n\n" +
  "Si la conversación incluye un bloque 'Datos calculados por VibeShopping', úsalo como tu ÚNICA " +
  "fuente de información. Reglas estrictas:\n" +
  "- Usa EXACTAMENTE los productos, precios (en colones, ₡), supermercados, distancias (km) y " +
  "tiempos (minutos) del bloque. No los cambies ni los inventes.\n" +
  "- No agregues supermercados, productos, precios, distancias ni tiempos que no aparezcan en el bloque.\n" +
  "- Si el bloque indica 'Transporte del usuario: no indicado', NO menciones tiempos de traslado " +
  "ni presentes una 'Recomendación de VibeShopping' (no existen en el bloque).\n" +
  "- Si la consulta pide precios, preséntalos en lenguaje natural con los números del bloque.\n" +
  "- Si el bloque incluye 'Recomendación de VibeShopping', explícala: menciona el supermercado " +
  "recomendado y por qué conviene (precio y/o distancia con el transporte indicado).\n\n" +
  "Pregunta por el transporte solo cuando sea necesario:\n" +
  "- Pregunta '¿Cómo te vas a transportar? (Bus, Carro, Motocicleta, Bicicleta, Caminando)' SOLO si la respuesta " +
  "requiere recomendar una tienda considerando distancia o tiempo de traslado Y el bloque indica " +
  "'Transporte del usuario: no indicado'. Ejemplos que requieren preguntar: '¿Dónde me conviene " +
  "comprar X?', '¿Dónde compro X?', '¿Cuál supermercado queda mejor o más cerca?'. Sé breve.\n" +
  "- El usuario responde directamente en el chat ('Bus', 'Carro', 'Motocicleta', 'Bicicleta', 'Caminando'); en el " +
  "siguiente turno VibeShopping recalcula con ese transporte.\n" +
  "- NO preguntes transporte si la consulta solo pide precios o compara precios ('¿Cuánto cuesta X?', " +
  "'¿Dónde está más barato X?', 'quiero gastar lo menos posible', 'lo más barato'), ni si el usuario ya " +
  "indicó el transporte.\n" +
  "- Cuando el usuario responda con el transporte (por ejemplo 'Carro', 'Caminando', 'Bicicleta', 'Bus', 'Motocicleta'), usa la " +
  "nueva consulta de VibeShopping para continuar con la recomendación; no repitas la pregunta anterior.\n\n" +
  "Si NO hay bloque 'Datos calculados por VibeShopping' (por ejemplo porque no se encontró el " +
  "producto en el catálogo), conversa y orienta sobre compras, pero nunca inventes cifras ni " +
  "supermercados.";

const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

const CORS_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

interface CatalogRow {
  canonical_name: string | null;
  price: number | null;
  supermarket_id: string | null;
  supermarket_name: string | null;
}

// Fila de la tabla `supermarkets` (coordenadas reales por supermercado).
interface SupermarketRow {
  id: string;
  name: string | null;
  latitude: number | null;
  longitude: number | null;
  address: string | null;
}

interface StoreOffer {
  storeId: string;
  storeName: string;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  distanceKm: number | null;
  travelMinutes: number | null;
  products: { name: string; price: number }[];
  total: number;
  coverage: number;
  score: number | null;
}

// Palabras candidatas a producto (sin tildes, sin stopwords, únicas, máx. 4).
function extractKeywords(message: string): string[] {
  const normalized = message
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .replace(/[^a-z0-9]+/g, " ");
  const words = normalized
    .split(" ")
    .filter((w) => w.length >= 3 && !STOPWORDS.has(w));
  return [...new Set(words)].slice(0, 4);
}

// Detecta el transporte mencionado en cualquier mensaje del usuario, o null.
// No exige una frase exacta: acepta lenguaje natural (carro, en carro, en
// vehículo, a pie, caminando, en bici, bicicleta, en bus, autobús, …).
function detectTransport(messages: { role: string; text: string }[]): string | null {
  const text = messages
    .filter((m) => m.role === "user")
    .map((m) => m.text)
    .join(" ")
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}/gu, "");

  if (/(^|\s)a pie(\s|$)|caminando|caminar|camine|andando/.test(text)) return "walking";
  if (/\bbici\b|bicicleta/.test(text)) return "bike";
  if (/\bbus(es)?\b|autobus|autobuses/.test(text)) return "bus";
  if (/\bmoto\b|motocicleta/.test(text)) return "moto";
  if (/\bcarro(s)?\b|\bauto(s)?\b|vehiculo|manej|conduc/.test(text)) return "car";
  return null;
}

// Palabras candidatas a producto en toda la conversación (solo turnos del
// usuario), para que una respuesta tipo "en carro" continúe la consulta
// anterior sin repetir el producto.
function extractKeywordsFromMessages(
  messages: { role: string; text: string }[],
): string[] {
  const unique = new Set<string>();
  for (const m of messages) {
    if (m.role !== "user") continue;
    for (const keyword of extractKeywords(m.text)) unique.add(keyword);
  }
  return [...unique].slice(0, 4);
}

// Distancia en línea recta entre dos coordenadas (Haversine).
function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const earthRadiusKm = 6371.0;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * earthRadiusKm * Math.asin(Math.sqrt(a));
}

// Tiempo estimado de traslado en minutos según la velocidad del transporte.
function travelMinutes(distanceKm: number, transport: string): number {
  const speed = SPEED_KMH[transport] ?? SPEED_KMH.car;
  return Math.ceil((distanceKm / speed) * 60);
}

function transportLabel(transport: string): string {
  return TRANSPORT_LABELS[transport] ?? "Carro";
}

function formatColones(value: number): string {
  return `₡${Math.round(value)}`;
}

// Agrupa las filas por supermercado, calcula distancia y tiempo, y aplica el
// puntaje multicriterio (igual que ShoppingAssistantLogic.buildBasketRecommendation):
// score = pesoPrecio*(másBarato/total) + pesoDistancia*(másCerca/distancia), solo
// para tiendas que tienen TODOS los productos de la consulta.
// Las coordenadas de cada tienda vienen de la tabla `supermarkets`.
function buildOffers(
  rows: CatalogRow[],
  supermarkets: Map<string, SupermarketRow>,
  transport: string | null,
): StoreOffer[] {
  const basketSize = new Set(
    rows.map((r) => r.canonical_name).filter((n): n is string => !!n),
  ).size;
  const byStore = new Map<string, StoreOffer>();
  const seen = new Set<string>();

  for (const row of rows) {
    const name = row.canonical_name;
    const price = row.price;
    if (!name || price == null || !row.supermarket_id) continue;

    const key = `${row.supermarket_id}|${name}`;
    if (seen.has(key)) continue;
    seen.add(key);

    let offer = byStore.get(row.supermarket_id);
    if (!offer) {
      const supermarket = supermarkets.get(row.supermarket_id);
      offer = {
        storeId: row.supermarket_id,
        storeName: row.supermarket_name ?? "Desconocida",
        address: supermarket?.address ?? null,
        latitude: supermarket?.latitude ?? null,
        longitude: supermarket?.longitude ?? null,
        distanceKm: null,
        travelMinutes: null,
        products: [],
        total: 0,
        coverage: 0,
        score: null,
      };
      byStore.set(row.supermarket_id, offer);
    }
    offer.products.push({ name, price });
    offer.total += price;
    offer.coverage += 1;
  }

  for (const offer of byStore.values()) {
    if (offer.latitude != null && offer.longitude != null) {
      offer.distanceKm = haversineKm(
        USER_LATITUDE, USER_LONGITUDE, offer.latitude, offer.longitude,
      );
      // Sin transporte no hay tiempo de traslado ni puntuación.
      if (transport != null) {
        offer.travelMinutes = travelMinutes(offer.distanceKm, transport);
      }
    }
  }

  // La recomendación multicriterio solo aplica cuando el transporte es conocido.
  const candidates = transport != null
    ? [...byStore.values()].filter(
        (o) => o.distanceKm != null && basketSize > 0 && o.coverage === basketSize,
      )
    : [];
  if (candidates.length > 0) {
    const minTotal = Math.min(...candidates.map((o) => o.total));
    const minDistance = Math.min(...candidates.map((o) => o.distanceKm as number));
    const weights = WEIGHTS[transport as string] ?? WEIGHTS.car;
    for (const offer of candidates) {
      offer.score = weights.price * (minTotal / offer.total) +
        weights.distance * (minDistance / (offer.distanceKm as number));
    }
  }

  return [...byStore.values()];
}

// Contexto estructurado que recibe Gemini: producto → precios por supermercado
// con distancia y tiempo, más la recomendación calculada por VibeShopping.
// Cuando el transporte es desconocido (null) se omiten tiempos y recomendación.
function buildContext(offers: StoreOffer[], transport: string | null): string {
  const lines: string[] = [
    "Datos calculados por VibeShopping (datos reales; úsalos EXACTAMENTE, no inventes ni cambies números):",
    `Transporte del usuario: ${transport == null ? "no indicado" : transportLabel(transport)}`,
    "",
  ];

  const productNames = [...new Set(
    offers.flatMap((o) => o.products.map((p) => p.name)),
  )];

  for (const productName of productNames) {
    lines.push(`Producto: ${productName}`);
    const withProduct = offers
      .filter((o) => o.products.some((p) => p.name === productName))
      .sort((a, b) => {
        const pa = a.products.find((p) => p.name === productName)!.price;
        const pb = b.products.find((p) => p.name === productName)!.price;
        return pa - pb;
      });
    for (const offer of withProduct) {
      const item = offer.products.find((p) => p.name === productName)!;
      const distance = offer.distanceKm != null
        ? `${offer.distanceKm.toFixed(2)} km`
        : "distancia no disponible";
      const time = offer.travelMinutes != null
        ? `, tiempo ${offer.travelMinutes} min en ${transportLabel(transport as string)}`
        : "";
      lines.push(
        `- ${offer.storeName}: precio ${formatColones(item.price)}, distancia ${distance}${time}`,
      );
    }
    lines.push("");
  }

  const candidates = offers.filter((o) => o.score != null);
  if (candidates.length > 0) {
    let best = candidates[0];
    for (const candidate of candidates) {
      if ((candidate.score as number) > (best.score as number)) best = candidate;
    }
    const mostExpensive = candidates.reduce(
      (a, b) => (a.total > b.total ? a : b),
    );
    const savings = mostExpensive.total - best.total;
    let rec =
      `Recomendación de VibeShopping (transporte: ${transportLabel(transport)}): ${best.storeName} ` +
      `(precio total ${formatColones(best.total)}, distancia ${(best.distanceKm as number).toFixed(2)} km, ${best.travelMinutes} min).`;
    if (savings > 0) rec += ` Ahorro estimado: ${formatColones(savings)}.`;
    lines.push(rec);
  }

  return lines.join("\n");
}

// Consulta el catálogo real por palabra clave (ilike sobre canonical_name).
async function queryCatalog(
  keywords: string[],
  supabase: ReturnType<typeof createClient>,
): Promise<CatalogRow[]> {
  const orFilter = keywords.map((k) => `canonical_name.ilike.%${k}%`).join(",");
  const { data, error } = await supabase
    .from("v_products_complete")
    .select("canonical_name,price,supermarket_id,supermarket_name")
    .or(orFilter);
  if (error) throw error;
  return (data ?? []) as CatalogRow[];
}

// Coordenadas reales de los supermercados (tabla `supermarkets`).
async function querySupermarkets(
  supabase: ReturnType<typeof createClient>,
): Promise<Map<string, SupermarketRow>> {
  const { data, error } = await supabase
    .from("supermarkets")
    .select("id,name,latitude,longitude,address");
  if (error) throw error;
  const byId = new Map<string, SupermarketRow>();
  for (const row of (data ?? []) as SupermarketRow[]) {
    byId.set(row.id, row);
  }
  return byId;
}

// Número máximo de intentos y espera (ms) entre reintentos cuando Gemini
// devuelve errores transitorios de servidor (HTTP 500, 502, 503, 504).
const GEMINI_MAX_ATTEMPTS = 3;
const GEMINI_RETRY_DELAYS_MS = [0, 1500, 3000];

// Resultado normalizado de una llamada a Gemini: texto generado o error con
// status HTTP y detalle técnico (para logs; nunca se envía crudo a Flutter).
interface GeminiResult {
  ok: boolean;
  text?: string;
  status?: number;
  detail?: string;
}

// Llama a Gemini con reintentos (espera corta) cuando el proveedor devuelve
// 500/502/503/504 (sobrecarga o fallo transitorio). HTTP 429 se reintenta UNA
// sola vez tras 2 s: si el límite es por minuto, la ventana se libera en
// segundos; si es diario, no conviene gastar más cupo reintentando.
async function callGemini(
  apiKey: string,
  contents: { role: string; parts: { text: string }[] }[],
): Promise<GeminiResult> {
  let lastStatus = 0;
  let lastDetail = "";
  for (let attempt = 0; attempt < GEMINI_MAX_ATTEMPTS; attempt++) {
    if (attempt > 0) {
      const delay =
        lastStatus === 429 ? 2000 : (GEMINI_RETRY_DELAYS_MS[attempt] ?? 0);
      if (delay > 0) await new Promise((resolve) => setTimeout(resolve, delay));
    }

    let status = 0;
    let detail = "";
    try {
      const res = await fetch(GEMINI_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
          contents,
          generationConfig: { temperature: 0.7, maxOutputTokens: 2048 },
        }),
      });
      status = res.status;
      if (res.ok) {
        const data = await res.json().catch(() => null) as
          | { candidates?: { content?: { parts?: { text?: string }[] }[] }[] }
          | null;
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text) return { ok: true, text };
        status = 502;
        detail = "Gemini devolvió una respuesta vacía";
      } else {
        const errBody = await res.json().catch(() => null) as
          | { error?: { message?: string } }
          | null;
        detail = errBody?.error?.message ?? "";
      }
    } catch (err) {
      status = 500;
      detail = err instanceof Error ? err.message : String(err);
    }

    lastStatus = status;
    lastDetail = detail;
    const transient =
      status === 500 || status === 502 || status === 503 || status === 504;
    const rateLimited = status === 429;
    const canRetry = transient || (rateLimited && attempt === 0);
    if (!canRetry) return { ok: false, status, detail };
  }
  return { ok: false, status: lastStatus, detail: lastDetail };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "Método no permitido" }, 405);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return json({ error: "Falta GEMINI_API_KEY" }, 500);
  }

  const body = (await req.json().catch(() => null)) as
    | Record<string, unknown>
    | null;

  // Conversación: lista de turnos {role: "user"|"assistant", text}.
  // El último turno es siempre el mensaje actual del usuario.
  const rawMessages = body?.messages;
  let messages: { role: string; text: string }[];
  if (Array.isArray(rawMessages) && rawMessages.length > 0) {
    messages = (rawMessages as { role?: unknown; text?: unknown }[])
      .filter(
        (m) =>
          m != null &&
          typeof m.text === "string" &&
          m.text.trim().length > 0,
      )
      .map((m) => ({
        role: m.role === "assistant" ? "assistant" : "user",
        text: (m.text as string).trim(),
      }));
  } else if (typeof body?.message === "string" && body.message.trim() !== "") {
    // Compatibilidad: un solo mensaje sin historial.
    messages = [{ role: "user", text: body.message.trim() }];
  } else {
    return json({ error: "Falta el campo messages" }, 400);
  }
  if (messages.length === 0) {
    return json({ error: "Falta el campo messages" }, 400);
  }

  // Transporte: se detecta en la conversación (cualquier turno del usuario).
  // Fallback al campo `transport` por compatibilidad con llamadas anteriores.
  const rawTransport = typeof body?.transport === "string" ? body.transport : "";
  const bodyTransport = ["car", "bus", "moto", "bike", "walking"].includes(
    rawTransport,
  )
    ? rawTransport
    : null;
  const transport = detectTransport(messages) ?? bodyTransport;

  let dataPart = "";
  const keywords = extractKeywordsFromMessages(messages);
  if (keywords.length > 0) {
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      return json(
        { error: "Configuración de Supabase incompleta en la Edge Function" },
        500,
      );
    }
    try {
      const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
      const [rows, supermarkets] = await Promise.all([
        queryCatalog(keywords, supabase),
        querySupermarkets(supabase),
      ]);
      if (rows.length > 0) {
        const offers = buildOffers(rows, supermarkets, transport);
        if (offers.length > 0) {
          dataPart = `\n\n${buildContext(offers, transport)}`;
        }
      }
      if (!dataPart) {
        dataPart =
          `\n\nNo se encontraron productos en el catálogo que coincidan con "${keywords.join('", "')}". ` +
          `No inventes precios ni supermercados; indícalo amablemente y ofrece ayuda.`;
      }
    } catch (err) {
      return json(
        {
          error: `Error al consultar el catálogo: ${err instanceof Error ? err.message : String(err)}`,
        },
        500,
      );
    }
  }

  // Contexto de Gemini: el bloque de datos se adjunta al último turno del usuario.
  const contents: { role: string; parts: { text: string }[] }[] = [];
  for (let i = 0; i < messages.length; i++) {
    const m = messages[i];
    let text = m.text;
    if (i === messages.length - 1 && dataPart) text += dataPart;
    contents.push({
      role: m.role === "user" ? "user" : "model",
      parts: [{ text }],
    });
  }

  const gemini = await callGemini(apiKey, contents);

  if (!gemini.ok) {
    const status = gemini.status ?? 502;
    const detail = gemini.detail ?? "";
    // Límite de solicitudes de Gemini (HTTP 429) tras el reintento: se devuelve
    // un código claro para que Flutter muestre un mensaje sencillo. El detalle
    // (métrica, límite, cuándo se libera) queda en `detail` solo para
    // diagnóstico técnico: Flutter no lo muestra al usuario.
    if (status === 429) {
      console.error(`Gemini 429 (límite de solicitudes): ${detail}`);
      return json(
        { error: "rate_limit_exceeded", detail: detail.slice(0, 700) },
        429,
      );
    }
    // Tras los reintentos, los errores transitorios de servidor/sobrecarga
    // (500, 502, 503, 504) se traducen a un mensaje sencillo; el detalle
    // técnico se registra en los logs.
    if (status === 500 || status === 502 || status === 503 || status === 504) {
      console.error(
        `Gemini ${status} tras ${GEMINI_MAX_ATTEMPTS} intentos: ${detail}`,
      );
      return json({ error: "model_overloaded" }, 503);
    }
    const msg = detail ? `: ${detail.slice(0, 400)}` : "";
    return json({ error: `Gemini respondió ${status}${msg}` }, 502);
  }

  return json({ response: gemini.text }, 200);
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: CORS_HEADERS });
}
