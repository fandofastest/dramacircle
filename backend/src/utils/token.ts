import jwt from "jsonwebtoken";
import { env } from "../config/env";

export type MemberTokenPayload = {
  sub: string;
  email: string;
  isVip: boolean;
};

export type AdminTokenPayload = {
  role: "admin";
  username: string;
};

const tokenExpiresIn = env.JWT_EXPIRES_IN as jwt.SignOptions["expiresIn"];

export const signMemberToken = (payload: MemberTokenPayload): string =>
  jwt.sign(payload, env.JWT_SECRET, { expiresIn: tokenExpiresIn });

export const verifyMemberToken = (token: string): MemberTokenPayload =>
  jwt.verify(token, env.JWT_SECRET) as MemberTokenPayload;

export const signAdminToken = (payload: AdminTokenPayload): string =>
  jwt.sign(payload, env.JWT_SECRET, { expiresIn: tokenExpiresIn });

export const verifyAdminToken = (token: string): AdminTokenPayload =>
  jwt.verify(token, env.JWT_SECRET) as AdminTokenPayload;
