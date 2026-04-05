import { InferSchemaType, Schema, model } from "mongoose";

const episodeItemSchema = new Schema(
  {
    bookId: { type: String, required: true, index: true },
    episodeNumber: { type: Number, required: true },
    encryptedUrl: { type: String, required: true }
  },
  { _id: false }
);

const episodesSchema = new Schema(
  {
    bookId: { type: String, required: true, unique: true, index: true },
    episodes: { type: [episodeItemSchema], default: [] }
  },
  { collection: "dramas_episodes", timestamps: true }
);

export type EpisodesDocument = InferSchemaType<typeof episodesSchema>;
export const EpisodesModel = model("DramaEpisodes", episodesSchema);
