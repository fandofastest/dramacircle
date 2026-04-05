import { NextFunction, Request, Response } from "express";
import { z } from "zod";
import { ApiError } from "../utils/apiError";

type ValidationTarget = "params" | "query" | "body";

export const validate =
  (schema: z.ZodTypeAny, target: ValidationTarget = "query") =>
  (req: Request, _res: Response, next: NextFunction): void => {
    const parsed = schema.safeParse(req[target]);
    if (!parsed.success) {
      const firstError = parsed.error.errors[0];
      next(new ApiError(400, firstError?.message ?? "Validation error"));
      return;
    }
    req[target] = parsed.data as Request[ValidationTarget];
    next();
  };

export const zodObject = (shape: z.ZodRawShape): z.ZodTypeAny => z.object(shape);
