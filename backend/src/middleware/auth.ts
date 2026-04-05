import { NextFunction, Request, Response } from "express";
import { MemberModel } from "../models/member.model";
import { ApiError } from "../utils/apiError";
import { verifyAdminToken, verifyMemberToken } from "../utils/token";

const readBearerToken = (headerValue: string | undefined): string | null => {
  if (!headerValue) {
    return null;
  }
  const [scheme, token] = headerValue.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) {
    return null;
  }
  return token;
};

const readAuthTokenFromRequest = (req: Request): string | null => readBearerToken(req.headers.authorization);

export const requireAuth = (req: Request, res: Response, next: NextFunction): void => {
  const token = readAuthTokenFromRequest(req);
  if (!token) {
    next(new ApiError(401, "Unauthorized"));
    return;
  }

  try {
    const payload = verifyMemberToken(token);
    res.locals.memberId = payload.sub;
    res.locals.memberEmail = payload.email;
    res.locals.isVip = payload.isVip;
    next();
  } catch {
    next(new ApiError(401, "Invalid token"));
  }
};

export const optionalAuth = (req: Request, res: Response, next: NextFunction): void => {
  const token = readAuthTokenFromRequest(req);
  if (!token) {
    next();
    return;
  }
  try {
    const payload = verifyMemberToken(token);
    res.locals.memberId = payload.sub;
    res.locals.memberEmail = payload.email;
    res.locals.isVip = payload.isVip;
  } catch {
    res.locals.memberId = undefined;
  }
  next();
};

export const requireVip = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
  const memberId = String(res.locals.memberId ?? "");
  if (!memberId) {
    next(new ApiError(401, "Unauthorized"));
    return;
  }

  const member = await MemberModel.findById(memberId).lean().exec();
  if (!member) {
    next(new ApiError(404, "Member not found"));
    return;
  }
  if (!member.isVip) {
    next(new ApiError(403, "VIP access required"));
    return;
  }

  res.locals.isVip = true;
  next();
};

export const requireAdmin = (req: Request, res: Response, next: NextFunction): void => {
  const token = readAuthTokenFromRequest(req);
  if (!token) {
    next(new ApiError(401, "Unauthorized"));
    return;
  }

  try {
    const payload = verifyAdminToken(token);
    if (payload.role !== "admin") {
      next(new ApiError(403, "Admin access required"));
      return;
    }
    res.locals.adminUsername = payload.username;
    next();
  } catch {
    next(new ApiError(401, "Invalid admin token"));
  }
};
