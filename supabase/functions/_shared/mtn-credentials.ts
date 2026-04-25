// Shared helper: read MTN credentials, preferring DB overrides from system_settings,
// falling back to env-var secrets. Cached in-memory per cold start (~60s TTL).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const KEYS = ["MTN_MOMO_PRIMARY_KEY", "MTN_API_USER", "MTN_API_KEY"] as const;
type Key = typeof KEYS[number];

let cache: { values: Record<Key, string>; ts: number } | null = null;
const TTL_MS = 60_000;

export async function getMtnCredentials(): Promise<Record<Key, string>> {
  if (cache && Date.now() - cache.ts < TTL_MS) {
    return cache.values;
  }

  const envValues = {
    MTN_MOMO_PRIMARY_KEY: Deno.env.get("MTN_MOMO_PRIMARY_KEY") ?? "",
    MTN_API_USER: Deno.env.get("MTN_API_USER") ?? "",
    MTN_API_KEY: Deno.env.get("MTN_API_KEY") ?? "",
  } as Record<Key, string>;

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (supabaseUrl && serviceKey) {
      const client = createClient(supabaseUrl, serviceKey);
      const { data } = await client
        .from("system_settings")
        .select("key,value")
        .in("key", KEYS as readonly string[]);
      if (data) {
        for (const row of data) {
          if (KEYS.includes(row.key as Key) && row.value) {
            envValues[row.key as Key] = row.value as string;
          }
        }
      }
    }
  } catch (_err) {
    // Swallow errors and fall back to env values
  }

  cache = { values: envValues, ts: Date.now() };
  return envValues;
}
