import { z } from "zod";

const isValidTimezone = (value: string) => {
  try {
    Intl.DateTimeFormat(undefined, { timeZone: value });
    return true;
  } catch {
    return false;
  }
};

const publicEnvSchema = z.object({
  NEXT_PUBLIC_SITE_URL: z.string().url({ message: "NEXT_PUBLIC_SITE_URL must be a valid URL." }),
  NEXT_PUBLIC_BUSINESS_TIMEZONE: z
    .string()
    .min(1, { message: "NEXT_PUBLIC_BUSINESS_TIMEZONE is required." })
    .refine((value) => isValidTimezone(value), {
      message: "NEXT_PUBLIC_BUSINESS_TIMEZONE must be a valid IANA timezone."
    }),
  NEXT_PUBLIC_SUPABASE_URL: z
    .string()
    .url({ message: "NEXT_PUBLIC_SUPABASE_URL must be a valid URL." }),
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z
    .string()
    .min(1, { message: "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY is required." })
});

const rawPublicEnv = {
  NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
  NEXT_PUBLIC_BUSINESS_TIMEZONE: process.env.NEXT_PUBLIC_BUSINESS_TIMEZONE,
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
};

const parsed = publicEnvSchema.safeParse(rawPublicEnv);

if (!parsed.success) {
  const message = parsed.error.issues.map((issue) => issue.message).join("; ");
  throw new Error(`Invalid public environment variables: ${message}`);
}

export const publicEnv = parsed.data;
