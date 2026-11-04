import { readFileSync } from "node:fs";
import { join } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";

describe("Supabase client factories", () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    process.env = { ...originalEnv };
    vi.resetModules();
  });

  it("browser client factory is available", async () => {
    process.env.NEXT_PUBLIC_SITE_URL = "https://travel.example.com";
    process.env.NEXT_PUBLIC_BUSINESS_TIMEZONE = "Asia/Kolkata";
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "publishable_test_key";

    const mod = await import("./client");
    expect(typeof mod.createClient).toBe("function");
  });

  it("server client factory is available", async () => {
    process.env.NEXT_PUBLIC_SITE_URL = "https://travel.example.com";
    process.env.NEXT_PUBLIC_BUSINESS_TIMEZONE = "Asia/Kolkata";
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "publishable_test_key";

    const mod = await import("./server");
    expect(typeof mod.createSupabaseServerClient).toBe("function");
  });

  it("admin client factory is server-only by contract", () => {
    const filePath = join(process.cwd(), "src", "lib", "supabase", "admin.ts");
    const source = readFileSync(filePath, "utf8");
    expect(source).toContain('import "server-only"');
    expect(source).toContain("getSupabaseAdminClient");
  });
});
