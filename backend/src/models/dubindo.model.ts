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

const dubindoSchema = new Schema(
  {
    classify: { type: String, required: true, unique: true, index: true },
    items: { type: [dramaItemSchema], default: [] }
  },
  { collection: "dramas_dubindo", timestamps: true }
);

export type DubindoDocument = InferSchemaType<typeof dubindoSchema>;
export const DubindoModel = model("DramaDubindo", dubindoSchema);
