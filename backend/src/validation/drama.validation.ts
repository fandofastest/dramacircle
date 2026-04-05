import { z } from "zod";

export const forYouQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1)
});

export const searchQuerySchema = z.object({
  query: z.string().trim().min(1)
});

export const dubindoQuerySchema = z.object({
  classify: z.enum(["terpopuler", "terbaru"]).default("terpopuler")
});

export const detailParamsSchema = z.object({
  bookId: z.string().trim().min(1)
});

export const episodesParamsSchema = z.object({
  bookId: z.string().trim().min(1)
});

export const streamQuerySchema = z.object({
  url: z.string().trim().url()
});

export const engagementParamsSchema = z.object({
  bookId: z.string().trim().min(1),
  episodeId: z.string().trim().min(1)
});

export const addCommentBodySchema = z.object({
  content: z.string().trim().min(1).max(500)
});

export const commentsQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(20)
});
