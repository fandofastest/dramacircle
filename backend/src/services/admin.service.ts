import bcrypt from "bcryptjs";
import { env } from "../config/env";
import { MemberRepository } from "../repositories/member.repository";
import { ApiError } from "../utils/apiError";
import { signAdminToken } from "../utils/token";

type MemberProfile = {
  id: string;
  name: string;
  email: string;
  isVip: boolean;
};

const toProfile = (input: { id: string; name: string; email: string; isVip: boolean }): MemberProfile => ({
  id: input.id,
  name: input.name,
  email: input.email,
  isVip: input.isVip
});

export class AdminService {
  constructor(private readonly memberRepository: MemberRepository) {}

  async login(username: string, password: string): Promise<{ token: string; username: string }> {
    if (username !== env.ADMIN_USERNAME || password !== env.ADMIN_PASSWORD) {
      throw new ApiError(401, "Invalid admin credentials");
    }
    const token = signAdminToken({ role: "admin", username: env.ADMIN_USERNAME });
    return { token, username: env.ADMIN_USERNAME };
  }

  async listMembers(): Promise<MemberProfile[]> {
    const members = await this.memberRepository.listMembers();
    return members.map((item) => toProfile(item));
  }

  async createMember(input: { name: string; email: string; password: string; isVip: boolean }): Promise<MemberProfile> {
    const email = input.email.trim().toLowerCase();
    const existing = await this.memberRepository.findByEmail(email);
    if (existing) {
      throw new ApiError(409, "Email already registered");
    }
    const passwordHash = await bcrypt.hash(input.password, 10);
    const created = await this.memberRepository.createByAdmin(input.name.trim(), email, passwordHash, input.isVip);
    return toProfile(created);
  }

  async updateMember(
    memberId: string,
    input: { name?: string; email?: string; password?: string; isVip?: boolean }
  ): Promise<MemberProfile> {
    const payload: { name?: string; email?: string; passwordHash?: string; isVip?: boolean } = {};

    if (typeof input.name === "string") {
      payload.name = input.name.trim();
    }
    if (typeof input.email === "string") {
      const normalizedEmail = input.email.trim().toLowerCase();
      const existing = await this.memberRepository.findByEmail(normalizedEmail);
      if (existing && existing.id !== memberId) {
        throw new ApiError(409, "Email already registered");
      }
      payload.email = normalizedEmail;
    }
    if (typeof input.password === "string" && input.password.length > 0) {
      payload.passwordHash = await bcrypt.hash(input.password, 10);
    }
    if (typeof input.isVip === "boolean") {
      payload.isVip = input.isVip;
    }

    const updated = await this.memberRepository.updateMember(memberId, payload);
    if (!updated) {
      throw new ApiError(404, "Member not found");
    }
    return toProfile(updated);
  }

  async deleteMember(memberId: string): Promise<void> {
    const deleted = await this.memberRepository.deleteMember(memberId);
    if (!deleted) {
      throw new ApiError(404, "Member not found");
    }
  }
}
