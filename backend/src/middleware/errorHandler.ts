import { ErrorRequestHandler } from "express";
import { ApiError } from "../utils/apiError";
import { logger } from "../utils/logger";

export const errorHandler: ErrorRequestHandler = (error, req, res, next) => {
  const statusCode = error instanceof ApiError ? error.statusCode : 500;
  const message = error instanceof Error ? error.message : "Internal Server Error";

  if (statusCode >= 500) {
    logger.error(message, { path: req.path, method: req.method });
  } else {
    logger.warn(message, { path: req.path, method: req.method });
  }

  res.status(statusCode).json({
    success: false,
    message
  });
  void next;
};
