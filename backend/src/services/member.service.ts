import bcrypt from "bcryptjs";
import { MemberRepository } from "../repositories/member.repository";
import { ApiError } from "../utils/apiError";
import { signMemberToken } from "../utils/token";

type MemberProfile = {
  id: string;
  name: string;
  email: string;
  isVip: boolean;
};

type AuthResult = {
  token: string;
  member: MemberProfile;
};

const toProfile = (input: { id: string; name: string; email: string; isVip: boolean }): MemberProfile => ({
  id: input.id,
  name: input.name,
  email: input.email,
  isVip: input.isVip
});

export class MemberService {
  constructor(private readonly memberRepository: MemberRepository) {}

  async register(name: string, email: string, password: string): Promise<AuthResult> {
    const normalizedEmail = email.trim().toLowerCase();
    const existing = await this.memberRepository.findByEmail(normalizedEmail);
    if (existing) {
      throw new ApiError(409, "Email already registered");
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const created = await this.memberRepository.create(name.trim(), normalizedEmail, passwordHash);
    const member = toProfile(created);
    const token = signMemberToken({ sub: member.id, email: member.email, isVip: member.isVip });
    return { token, member };
  }

  async login(email: string, password: string): Promise<AuthResult> {
    const normalizedEmail = email.trim().toLowerCase();
    const existing = await this.memberRepository.findByEmail(normalizedEmail);
    if (!existing) {
      throw new ApiError(401, "Invalid email or password");
    }

    const isPasswordValid = await bcrypt.compare(password, existing.passwordHash);
    if (!isPasswordValid) {
      throw new ApiError(401, "Invalid email or password");
    }

    const member = toProfile(existing);
    const token = signMemberToken({ sub: member.id, email: member.email, isVip: member.isVip });
    return { token, member };
  }

  async getProfile(memberId: string): Promise<MemberProfile> {
    const existing = await this.memberRepository.findById(memberId);
    if (!existing) {
      throw new ApiError(404, "Member not found");
    }
    return toProfile(existing);
  }

  async setVipStatus(memberId: string, isVip: boolean): Promise<AuthResult> {
    const updated = await this.memberRepository.updateVipStatus(memberId, isVip);
    if (!updated) {
      throw new ApiError(404, "Member not found");
    }
    const member = toProfile(updated);
    const token = signMemberToken({ sub: member.id, email: member.email, isVip: member.isVip });
    return { token, member };
  }
}
