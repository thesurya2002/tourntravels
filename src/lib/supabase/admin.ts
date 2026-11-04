import "server-only";
import { z } from "zod";
import { createClient } from "@supabase/supabase-js";
import { publicEnv } from "@/lib/env/public";
import type { Database } from "@/types/database";

/**
 * Allowed ONLY for webhooks, cron jobs, email outbox jobs, and system tasks.
 * NEVER for ordinary user-initiated reads.
 */
export function getSupabaseAdminClient() {
  const secretKey = z
    .string()
    .min(1, { message: "SUPABASE_SECRET_KEY is required when creating the admin client." })
    .parse(process.env.SUPABASE_SECRET_KEY);

  return createClient<Database>(publicEnv.NEXT_PUBLIC_SUPABASE_URL, secretKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false
    }
  });
}
