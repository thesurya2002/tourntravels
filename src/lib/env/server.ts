import "server-only";
import { z } from "zod";

const serverEnvSchema = z.object({
  ENABLE_DESIGN_SYSTEM_PAGE: z
    .string()
    .optional()
    .transform((value) => value === "true")
    .default(false),
  SUPABASE_JWKS_URL: z.string().url().optional().or(z.literal("")),
  RAZORPAY_KEY_ID: z.string().optional(),
  RAZORPAY_KEY_SECRET: z.string().optional(),
  RAZORPAY_WEBHOOK_SECRET: z.string().optional(),
  ADMIN_PATH_SLUG: z.string().optional(),
  RESEND_API_KEY: z.string().optional(),
  EMAIL_FROM: z.string().optional()
});

const parsed = serverEnvSchema.safeParse(process.env);

if (!parsed.success) {
  throw new Error(
    `Invalid server environment variables: ${parsed.error.issues.map((issue) => issue.message).join("; ")}`
  );
}

export const serverEnv = parsed.data;
