import { InferSchemaType, Schema, model } from "mongoose";

const vipSchema = new Schema(
  {
    key: { type: String, required: true, unique: true, default: "default" },
    payload: { type: Schema.Types.Mixed, required: true }
  },
  { collection: "dramas_vip", timestamps: true }
);

export type VipDocument = InferSchemaType<typeof vipSchema>;
export const VipModel = model("DramaVip", vipSchema);
