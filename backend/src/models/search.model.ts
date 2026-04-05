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

const searchSchema = new Schema(
  {
    query: { type: String, required: true, unique: true, index: true },
    results: { type: [dramaItemSchema], default: [] }
  },
  { collection: "dramas_search", timestamps: true }
);

export type SearchDocument = InferSchemaType<typeof searchSchema>;
export const SearchModel = model("DramaSearch", searchSchema);
