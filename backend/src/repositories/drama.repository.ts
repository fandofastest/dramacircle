import { DubindoModel } from "../models/dubindo.model";
import { EngagementModel } from "../models/engagement.model";
import { DetailModel } from "../models/detail.model";
import { EpisodesModel } from "../models/episodes.model";
import { ForYouModel } from "../models/foryou.model";
import { LatestModel } from "../models/latest.model";
import { PopulerSearchModel } from "../models/populersearch.model";
import { RandomDramaModel } from "../models/randomdrama.model";
import { SearchModel } from "../models/search.model";
import { TrendingModel } from "../models/trending.model";
import { VipModel } from "../models/vip.model";
import { DramaNormalized, EpisodeNormalized } from "../utils/normalize";

const sanitizeDramaArray = (items: unknown): DramaNormalized[] => {
  if (!Array.isArray(items)) {
    return [];
  }

  return items
    .map((item) => item as Partial<DramaNormalized>)
    .filter((item) => typeof item.bookId === "string" && typeof item.title === "string")
    .map((item) => ({
      bookId: item.bookId as string,
      title: item.title as string,
      cover: typeof item.cover === "string" ? item.cover : null,
      description: typeof item.description === "string" ? item.description : null,
      category: Array.isArray(item.category) ? item.category.filter((entry): entry is string => typeof entry === "string") : [],
      totalEpisodes: typeof item.totalEpisodes === "number" ? item.totalEpisodes : null,
      source: "external_api"
    }));
};

export class DramaRepository {
  async getForYouByPage(page: number): Promise<DramaNormalized[] | null> {
    const document = await ForYouModel.findOne({ page }).lean().exec();
    return document ? sanitizeDramaArray(document.items) : null;
  }

  async saveForYouPage(page: number, items: DramaNormalized[]): Promise<void> {
    await ForYouModel.updateOne({ page }, { $set: { page, items } }, { upsert: true }).exec();
  }

  async getTrending(): Promise<DramaNormalized[] | null> {
    const document = await TrendingModel.findOne({ key: "default" }).lean().exec();
    return document ? sanitizeDramaArray(document.items) : null;
  }

  async saveTrending(items: DramaNormalized[]): Promise<void> {
    await TrendingModel.updateOne({ key: "default" }, { $set: { key: "default", items } }, { upsert: true }).exec();
  }

  async getLatest(): Promise<DramaNormalized[] | null> {
    const document = await LatestModel.findOne({ key: "default" }).lean().exec();
    return document ? sanitizeDramaArray(document.items) : null;
  }

  async saveLatest(items: DramaNormalized[]): Promise<void> {
    await LatestModel.updateOne({ key: "default" }, { $set: { key: "default", items } }, { upsert: true }).exec();
  }

  async getVip(): Promise<Record<string, unknown> | null> {
    const document = await VipModel.findOne({ key: "default" }).lean().exec();
    if (!document || !document.payload || typeof document.payload !== "object") {
      return null;
    }
    return document.payload as Record<string, unknown>;
  }

  async saveVip(payload: Record<string, unknown>): Promise<void> {
    await VipModel.updateOne({ key: "default" }, { $set: { key: "default", payload } }, { upsert: true }).exec();
  }

  async getDubindo(classify: string): Promise<DramaNormalized[] | null> {
    const document = await DubindoModel.findOne({ classify }).lean().exec();
    return document ? sanitizeDramaArray(document.items) : null;
  }

  async saveDubindo(classify: string, items: DramaNormalized[]): Promise<void> {
    await DubindoModel.updateOne({ classify }, { $set: { classify, items } }, { upsert: true }).exec();
  }

  async getRandomDrama(): Promise<DramaNormalized[] | null> {
    const document = await RandomDramaModel.findOne({ key: "default" }).lean().exec();
    return document ? sanitizeDramaArray(document.items) : null;
  }

  async saveRandomDrama(items: DramaNormalized[]): Promise<void> {
    await RandomDramaModel.updateOne(
      { key: "default" },
      { $set: { key: "default", items } },
      { upsert: true }
    ).exec();
  }

  async getPopulerSearch(): Promise<DramaNormalized[] | null> {
    const document = await PopulerSearchModel.findOne({ key: "default" }).lean().exec();
    return document ? sanitizeDramaArray(document.items) : null;
  }

  async savePopulerSearch(items: DramaNormalized[]): Promise<void> {
    await PopulerSearchModel.updateOne(
      { key: "default" },
      { $set: { key: "default", items } },
      { upsert: true }
    ).exec();
  }

  async getSearchByQuery(query: string): Promise<DramaNormalized[] | null> {
    const document = await SearchModel.findOne({ query }).lean().exec();
    return document ? sanitizeDramaArray(document.results) : null;
  }

  async saveSearch(query: string, results: DramaNormalized[]): Promise<void> {
    await SearchModel.updateOne({ query }, { $set: { query, results } }, { upsert: true }).exec();
  }

  async getDetailByBookId(bookId: string): Promise<Record<string, unknown> | null> {
    const document = await DetailModel.findOne({ bookId }).lean().exec();
    if (!document) {
      return null;
    }
    const detail = { ...document } as Record<string, unknown>;
    delete detail._id;
    delete detail.__v;
    delete detail.createdAt;
    delete detail.updatedAt;
    return detail as Record<string, unknown>;
  }

  async saveDetail(detail: DramaNormalized & { raw: Record<string, unknown>; bookId: string }): Promise<void> {
    await DetailModel.updateOne({ bookId: detail.bookId }, { $set: detail }, { upsert: true }).exec();
  }

  async getEpisodesByBookId(bookId: string): Promise<EpisodeNormalized[] | null> {
    const document = await EpisodesModel.findOne({ bookId }).lean().exec();
    return document?.episodes ?? null;
  }

  async saveEpisodes(bookId: string, episodes: EpisodeNormalized[]): Promise<void> {
    await EpisodesModel.updateOne({ bookId }, { $set: { bookId, episodes } }, { upsert: true }).exec();
  }

  async getEngagement(bookId: string, episodeId: string): Promise<{
    bookId: string;
    episodeId: string;
    likes: string[];
    comments: Array<{ memberId: string; memberName: string; content: string; createdAt: Date }>;
    playCount: number;
  } | null> {
    const document = await EngagementModel.findOne({ bookId, episodeId }).lean().exec();
    if (!document) {
      return null;
    }
    return {
      bookId: document.bookId,
      episodeId: document.episodeId,
      likes: Array.isArray(document.likes) ? document.likes : [],
      comments: Array.isArray(document.comments) ? document.comments : [],
      playCount: typeof document.playCount === "number" ? document.playCount : 0
    };
  }

  async ensureEngagement(bookId: string, episodeId: string): Promise<void> {
    await EngagementModel.updateOne(
      { bookId, episodeId },
      { $setOnInsert: { bookId, episodeId, likes: [], comments: [], playCount: 0 } },
      { upsert: true }
    ).exec();
  }

  async incrementPlayCount(bookId: string, episodeId: string): Promise<void> {
    await this.ensureEngagement(bookId, episodeId);
    await EngagementModel.updateOne({ bookId, episodeId }, { $inc: { playCount: 1 } }).exec();
  }

  async toggleLike(bookId: string, episodeId: string, memberId: string): Promise<boolean> {
    await this.ensureEngagement(bookId, episodeId);
    const existing = await EngagementModel.findOne({ bookId, episodeId, likes: memberId }).lean().exec();
    if (existing) {
      await EngagementModel.updateOne({ bookId, episodeId }, { $pull: { likes: memberId } }).exec();
      return false;
    }
    await EngagementModel.updateOne({ bookId, episodeId }, { $addToSet: { likes: memberId } }).exec();
    return true;
  }

  async addComment(
    bookId: string,
    episodeId: string,
    comment: { memberId: string; memberName: string; content: string; createdAt: Date }
  ): Promise<void> {
    await this.ensureEngagement(bookId, episodeId);
    await EngagementModel.updateOne({ bookId, episodeId }, { $push: { comments: comment } }).exec();
  }

  async getCommentsPage(
    bookId: string,
    episodeId: string,
    page: number,
    limit: number
  ): Promise<{
    comments: Array<{ memberId: string; memberName: string; content: string; createdAt: Date }>;
    total: number;
  }> {
    const document = await this.getEngagement(bookId, episodeId);
    const all = document?.comments ?? [];
    const total = all.length;
    const start = Math.max(0, total - page * limit);
    const end = Math.max(0, total - (page - 1) * limit);
    const pageItems = all.slice(start, end).reverse();
    return { comments: pageItems, total };
  }
}
