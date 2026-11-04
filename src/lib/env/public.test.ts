import { afterEach, describe, expect, it, vi } from "vitest";

describe("public env validation", () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    process.env = { ...originalEnv };
    vi.resetModules();
  });

  it("accepts valid Supabase and app configuration", async () => {
    process.env.NEXT_PUBLIC_SITE_URL = "https://travel.example.com";
    process.env.NEXT_PUBLIC_BUSINESS_TIMEZONE = "Asia/Kolkata";
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "publishable_test_key";

    const { publicEnv } = await import("./public");

    expect(publicEnv.NEXT_PUBLIC_SITE_URL).toBe("https://travel.example.com");
    expect(publicEnv.NEXT_PUBLIC_BUSINESS_TIMEZONE).toBe("Asia/Kolkata");
    expect(publicEnv.NEXT_PUBLIC_SUPABASE_URL).toBe("https://example.supabase.co");
    expect(publicEnv.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY).toBe("publishable_test_key");
  });

  it("rejects missing or invalid values", async () => {
    process.env.NEXT_PUBLIC_SITE_URL = "not-a-url";
    process.env.NEXT_PUBLIC_BUSINESS_TIMEZONE = "Mars/Phobos";
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "";

    await expect(import("./public")).rejects.toThrow();
  });
});
