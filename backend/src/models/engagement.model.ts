import { InferSchemaType, Schema, model } from "mongoose";

const commentSchema = new Schema(
  {
    memberId: { type: String, required: true, index: true },
    memberName: { type: String, required: true },
    content: { type: String, required: true },
    createdAt: { type: Date, required: true, default: Date.now }
  },
  { _id: false }
);

const engagementSchema = new Schema(
  {
    bookId: { type: String, required: true, index: true },
    episodeId: { type: String, required: true, index: true },
    likes: { type: [String], default: [] },
    comments: { type: [commentSchema], default: [] },
    playCount: { type: Number, default: 0 }
  },
  { collection: "dramas_engagements", timestamps: true }
);

engagementSchema.index({ bookId: 1, episodeId: 1 }, { unique: true });

export type EngagementDocument = InferSchemaType<typeof engagementSchema>;
export const EngagementModel = model("DramaEngagement", engagementSchema);
