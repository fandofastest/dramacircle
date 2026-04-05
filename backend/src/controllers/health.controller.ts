import { Request, Response } from "express";

export const healthController = (_req: Request, res: Response): void => {
  res.status(200).json({
    success: true,
    status: "ok",
    timestamp: new Date().toISOString()
  });
};
