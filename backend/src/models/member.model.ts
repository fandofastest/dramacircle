import { InferSchemaType, Schema, model } from "mongoose";

const memberSchema = new Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    passwordHash: { type: String, required: true },
    isVip: { type: Boolean, required: true, default: false }
  },
  { collection: "members", timestamps: true }
);

export type MemberDocument = InferSchemaType<typeof memberSchema>;
export const MemberModel = model("Member", memberSchema);
