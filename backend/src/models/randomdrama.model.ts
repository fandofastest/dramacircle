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

const randomDramaSchema = new Schema(
  {
    key: { type: String, required: true, unique: true, default: "default" },
    items: { type: [dramaItemSchema], default: [] }
  },
  { collection: "dramas_randomdrama", timestamps: true }
);

export type RandomDramaDocument = InferSchemaType<typeof randomDramaSchema>;
export const RandomDramaModel = model("DramaRandomDrama", randomDramaSchema);
