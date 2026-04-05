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

const populerSearchSchema = new Schema(
  {
    key: { type: String, required: true, unique: true, default: "default" },
    items: { type: [dramaItemSchema], default: [] }
  },
  { collection: "dramas_populersearch", timestamps: true }
);

export type PopulerSearchDocument = InferSchemaType<typeof populerSearchSchema>;
export const PopulerSearchModel = model("DramaPopulerSearch", populerSearchSchema);
