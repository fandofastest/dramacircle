import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  MONGODB_URI: z.string().min(1).default("mongodb://127.0.0.1:27017/colongapi"),
  EXTERNAL_API_BASE_URL: z.string().url().default("https://api.sansekai.my.id/api"),
  JWT_SECRET: z.string().min(10).default("change-this-secret-key"),
  JWT_EXPIRES_IN: z.string().min(1).default("7d"),
  ADMIN_USERNAME: z.string().min(3).default("admin"),
  ADMIN_PASSWORD: z.string().min(6).default("admin123"),
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(900000),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(100)
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const message = parsed.error.issues
    .map((issue) => `${issue.path.join(".") || "unknown"}: ${issue.message}`)
    .join(", ");
  throw new Error(`Invalid environment variables: ${message}`);
}

export const env = parsed.data;
