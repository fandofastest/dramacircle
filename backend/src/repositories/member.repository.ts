import { MemberModel } from "../models/member.model";

export type MemberEntity = {
  id: string;
  name: string;
  email: string;
  passwordHash: string;
  isVip: boolean;
};

const toEntity = (value: Record<string, unknown>): MemberEntity => ({
  id: String(value._id),
  name: String(value.name ?? ""),
  email: String(value.email ?? ""),
  passwordHash: String(value.passwordHash ?? ""),
  isVip: Boolean(value.isVip)
});

export class MemberRepository {
  async listMembers(): Promise<MemberEntity[]> {
    const documents = await MemberModel.find().sort({ createdAt: -1 }).lean().exec();
    return documents.map((item) => toEntity(item as unknown as Record<string, unknown>));
  }

  async findByEmail(email: string): Promise<MemberEntity | null> {
    const document = await MemberModel.findOne({ email }).lean().exec();
    if (!document) {
      return null;
    }
    return toEntity(document as unknown as Record<string, unknown>);
  }

  async findById(id: string): Promise<MemberEntity | null> {
    const document = await MemberModel.findById(id).lean().exec();
    if (!document) {
      return null;
    }
    return toEntity(document as unknown as Record<string, unknown>);
  }

  async create(name: string, email: string, passwordHash: string): Promise<MemberEntity> {
    const created = await MemberModel.create({ name, email, passwordHash, isVip: false });
    return {
      id: created._id.toString(),
      name: created.name,
      email: created.email,
      passwordHash: created.passwordHash,
      isVip: created.isVip
    };
  }

  async createByAdmin(name: string, email: string, passwordHash: string, isVip: boolean): Promise<MemberEntity> {
    const created = await MemberModel.create({ name, email, passwordHash, isVip });
    return {
      id: created._id.toString(),
      name: created.name,
      email: created.email,
      passwordHash: created.passwordHash,
      isVip: created.isVip
    };
  }

  async updateVipStatus(id: string, isVip: boolean): Promise<MemberEntity | null> {
    const updated = await MemberModel.findByIdAndUpdate(id, { $set: { isVip } }, { new: true }).lean().exec();
    if (!updated) {
      return null;
    }
    return toEntity(updated as unknown as Record<string, unknown>);
  }

  async updateMember(
    id: string,
    payload: { name?: string; email?: string; passwordHash?: string; isVip?: boolean }
  ): Promise<MemberEntity | null> {
    const updated = await MemberModel.findByIdAndUpdate(id, { $set: payload }, { new: true }).lean().exec();
    if (!updated) {
      return null;
    }
    return toEntity(updated as unknown as Record<string, unknown>);
  }

  async deleteMember(id: string): Promise<boolean> {
    const deleted = await MemberModel.findByIdAndDelete(id).exec();
    return Boolean(deleted);
  }
}
