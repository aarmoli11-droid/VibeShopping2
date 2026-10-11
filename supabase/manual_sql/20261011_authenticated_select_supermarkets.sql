-- ============================================================================
-- VibeShopping · Documentación de la política RLS de supermercados
-- public.authenticated_select_supermarkets
--
-- Propósito: permitir a los usuarios autenticados leer public.supermarkets.
-- El explorador y el mapa leen esta tabla con el SDK de Supabase usando la
-- clave anónima, y sin esta política SELECT las filas quedan ocultas (RLS
-- activo con la tabla vacía a ojos del cliente, pese a estar poblada en la
-- base).
--
-- Idempotente: el bloque DO $$ crea la política SOLO si no existe todavía
-- (consulta pg_policies). No habilita ni deshabilita RLS, no otorga permisos
-- de escritura (INSERT/UPDATE/DELETE) y no toca otras políticas.
--
-- Ejecutar manualmente desde el SQL Editor de Supabase. NO usar supabase db
-- push. NOTA: si la regla ya fue creada a mano, este script no genera cambios
-- (diseñado como referencia reproducible y verificable).
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'supermarkets'
      AND policyname = 'authenticated_select_supermarkets'
  ) THEN
    CREATE POLICY authenticated_select_supermarkets
      ON public.supermarkets
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END
$$;