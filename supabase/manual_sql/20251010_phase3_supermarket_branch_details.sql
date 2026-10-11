-- ============================================================================
-- Fase 3 · VibeShopping
-- Columnas opcionales para sucursales en public.supermarkets
--
-- Idempotente: usa ADD COLUMN IF NOT EXISTS y COMMENT ON COLUMN (repetible sin
-- error). No modifica, renombra ni elimina columnas existentes; conserva
-- name, logo_url, latitude, longitude, address, parking, delivery y pickup.
--
-- Ejecutar manualmente desde el SQL Editor de Supabase. NO usar supabase db
-- push. No se incluyen valores ficticios: los campos quedan NULL hasta que
-- exista información verificada de cada sucursal.
-- ============================================================================

ALTER TABLE public.supermarkets
  ADD COLUMN IF NOT EXISTS branch_name text,
  ADD COLUMN IF NOT EXISTS photo_url text,
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS opening_hours jsonb;

-- branch_name: localidad o identificación de la sucursal (p. ej.
--   "Buenos Aires", "Boston"). NULL si no está registrada.
COMMENT ON COLUMN public.supermarkets.branch_name IS
  'Nombre de la localidad o identificación de la sucursal. NULL si no está registrado.';

-- photo_url: fotografía real del establecimiento (NO el logo). La interfaz no
--   usa logo_url como sustituto de la fotografía. NULL si no está registrada.
COMMENT ON COLUMN public.supermarkets.photo_url IS
  'URL de la fotografía del establecimiento. NULL si no está registrada.';

-- phone: teléfono de contacto de esa sucursal. NULL si no está registrado.
COMMENT ON COLUMN public.supermarkets.phone IS
  'Teléfono de contacto de la sucursal. NULL si no está registrado.';

-- opening_hours: horarios propios de la sucursal (no asumir los de la cadena).
--
-- Formato JSONB:
--   Claves estables en inglés: monday, tuesday, wednesday, thursday, friday,
--   saturday, sunday. Las etiquetas en español se traducen SOLO en la interfaz
--   de Flutter.
--   Cada clave es una lista de intervalos con hora local de 24 horas en
--   formato "HH:mm" (p. ej. "06:00", "22:00"):
--     {
--       "monday": [
--         { "open": "06:00", "close": "10:00" },
--         { "open": "14:00", "close": "22:00" }
--       ],
--       "tuesday": [],
--       "wednesday": null
--     }
--
--   Semántica de tres casos bien diferenciados:
--     - Clave inexistente o valor nulo ... horario DESCONOCIDO.
--     - Lista vacía ("tuesday": []) ........ día confirmado como CERRADO.
--     - Lista con uno o más intervalos .... horarios conocidos para ese día.
--
--   Los intervalos pertenecen al mismo día natural (sin cruce de medianoche);
--   una jornada que cruce la medianoche se documenta en dos intervalos.
COMMENT ON COLUMN public.supermarkets.opening_hours IS
  'Horarios de apertura por día. JSONB con claves en inglés (monday..sunday); '
  'cada valor es una lista de intervalos {open, close} en formato HH:mm (24 h). '
  'Lista vacía = día confirmado cerrado; clave ausente o nula = horario '
  'desconocido. Sin cruzamiento de medianoche; jornadas nocturnas en dos '
  'intervalos.';