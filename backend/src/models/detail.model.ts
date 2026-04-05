import { InferSchemaType, Schema, model } from "mongoose";

const detailSchema = new Schema(
  {
    bookId: { type: String, required: true, unique: true, index: true },
    title: { type: String, required: true },
    cover: { type: String, default: null },
    description: { type: String, default: null },
    category: { type: [String], default: [] },
    totalEpisodes: { type: Number, default: null },
    source: { type: String, required: true, enum: ["external_api"], default: "external_api" },
    raw: { type: Schema.Types.Mixed, default: null }
  },
  { collection: "dramas_detail", timestamps: true }
);

export type DetailDocument = InferSchemaType<typeof detailSchema>;
export const DetailModel = model("DramaDetail", detailSchema);
