import { InferSchemaType, Schema, model } from "mongoose";

const dramaItemSchema = new Schema(
  {
    bookId: { type: String, required: true, index: true },
    title: { type: String, required: true },
    cover: { type: String, default: null },
    description: { type: String, default: null },
    category: { type: [String], default: [] },
    totalEpisodes: { type: Number, default: null },
    source: { type: String, required: true, enum: ["external_api"], default: "external_api" }
  },
  { _id: false }
);

const trendingSchema = new Schema(
  {
    key: { type: String, required: true, unique: true, default: "default" },
    items: { type: [dramaItemSchema], default: [] }
  },
  { collection: "dramas_trending", timestamps: true }
);

export type TrendingDocument = InferSchemaType<typeof trendingSchema>;
export const TrendingModel = model("DramaTrending", trendingSchema);
