import { z } from "zod";

export const adminLoginSchema = z.object({
  username: z.string().trim().min(1),
  password: z.string().min(1)
});

export const adminCreateMemberSchema = z.object({
  name: z.string().trim().min(2).max(80),
  email: z.string().trim().email(),
  password: z.string().min(6).max(128),
  isVip: z.boolean().default(false)
});

export const adminUpdateMemberSchema = z
  .object({
    name: z.string().trim().min(2).max(80).optional(),
    email: z.string().trim().email().optional(),
    password: z.string().min(6).max(128).optional(),
    isVip: z.boolean().optional()
  })
  .refine((value) => Object.keys(value).length > 0, "At least one field must be provided");

export const memberIdParamSchema = z.object({
  memberId: z.string().trim().min(1)
});
