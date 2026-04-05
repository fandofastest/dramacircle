import { DramaRepository } from "../repositories/drama.repository";
import { MemberModel } from "../models/member.model";
import { ApiError } from "../utils/apiError";
import {
  DramaNormalized,
  EpisodeNormalized,
  extractArrayPayload,
  extractObjectPayload,
  normalizeDrama,
  normalizeEpisode
} from "../utils/normalize";
import { ExternalDramaService } from "./externalDrama.service";

const STREAM_CACHE_TTL_MS = 1000 * 60 * 60 * 6;
const COMMENT_COOLDOWN_MS = 8000;
const streamCache = new Map<string, { payload: Record<string, unknown>; expiresAt: number }>();
const streamInFlight = new Map<string, Promise<Record<string, unknown>>>();

export class DramaService {
  constructor(
    private readonly repository: DramaRepository,
    private readonly externalService: ExternalDramaService
  ) {}

  async getForYou(page: number): Promise<{ page: number; items: DramaNormalized[] }> {
    const existing = await this.repository.getForYouByPage(page);
    if (existing && existing.length > 0) {
      return { page, items: existing };
    }

    const payload = await this.externalService.fetchForYou(page);
    const normalized = this.normalizeDramaCollection(payload);
    await this.repository.saveForYouPage(page, normalized);

    const stored = await this.repository.getForYouByPage(page);
    if (!stored) {
      throw new ApiError(500, "Failed to persist for-you data");
    }

    return { page, items: stored };
  }

  async getTrending(): Promise<DramaNormalized[]> {
    const existing = await this.repository.getTrending();
    if (existing && existing.length > 0) {
      return existing;
    }

    const payload = await this.externalService.fetchTrending();
    const normalized = this.normalizeDramaCollection(payload);
    await this.repository.saveTrending(normalized);
    return (await this.repository.getTrending()) ?? [];
  }

  async getLatest(): Promise<DramaNormalized[]> {
    const existing = await this.repository.getLatest();
    if (existing && existing.length > 0) {
      return existing;
    }

    const payload = await this.externalService.fetchLatest();
    const normalized = this.normalizeDramaCollection(payload);
    await this.repository.saveLatest(normalized);
    return (await this.repository.getLatest()) ?? [];
  }

  async getVip(): Promise<Record<string, unknown>> {
    const existing = await this.repository.getVip();
    if (existing) {
      return existing;
    }

    const payload = await this.externalService.fetchVip();
    const objectPayload = extractObjectPayload(payload);
    if (!objectPayload) {
      throw new ApiError(502, "Invalid VIP payload from external API");
    }
    await this.repository.saveVip(objectPayload);
    return (await this.repository.getVip()) ?? objectPayload;
  }

  async getDubindo(classify: string): Promise<{ classify: "terpopuler" | "terbaru"; items: DramaNormalized[] }> {
    const finalClassify = this.normalizeDubindoClassify(classify);
    const existing = await this.repository.getDubindo(finalClassify);
    if (existing && existing.length > 0) {
      return { classify: finalClassify, items: existing };
    }

    const payload = await this.externalService.fetchDubindo(finalClassify);
    const normalized = this.normalizeDramaCollection(payload);
    await this.repository.saveDubindo(finalClassify, normalized);
    return { classify: finalClassify, items: (await this.repository.getDubindo(finalClassify)) ?? [] };
  }

  async getRandomDrama(): Promise<DramaNormalized[]> {
    const existing = await this.repository.getRandomDrama();
    if (existing && existing.length > 0) {
      return existing;
    }

    const payload = await this.externalService.fetchRandomDrama();
    const normalized = this.normalizeDramaCollection(payload);
    await this.repository.saveRandomDrama(normalized);
    return (await this.repository.getRandomDrama()) ?? [];
  }

  async getPopulerSearch(): Promise<DramaNormalized[]> {
    const existing = await this.repository.getPopulerSearch();
    if (existing && existing.length > 0) {
      return existing;
    }

    const payload = await this.externalService.fetchPopulerSearch();
    const normalized = this.normalizeDramaCollection(payload);
    await this.repository.savePopulerSearch(normalized);
    return (await this.repository.getPopulerSearch()) ?? [];
  }

  async search(query: string): Promise<{ query: string; results: DramaNormalized[] }> {
    const normalizedQuery = query.trim().toLowerCase();
    const existing = await this.repository.getSearchByQuery(normalizedQuery);
    if (existing && existing.length > 0) {
      return { query: normalizedQuery, results: existing };
    }

    const payload = await this.externalService.searchDrama(query);
    const normalized = this.normalizeDramaCollection(payload);
    await this.repository.saveSearch(normalizedQuery, normalized);
    return { query: normalizedQuery, results: (await this.repository.getSearchByQuery(normalizedQuery)) ?? [] };
  }

  async getDetail(bookId: string): Promise<Record<string, unknown>> {
    const existing = await this.repository.getDetailByBookId(bookId);
    if (existing && typeof existing.title === "string" && existing.title.length > 0) {
      return existing;
    }

    const payload = await this.externalService.fetchDetail(bookId);
    const objectPayload = extractObjectPayload(payload);
    if (!objectPayload) {
      throw new ApiError(404, "Drama detail not found from external API");
    }

    const normalized = normalizeDrama(objectPayload);
    const finalBookId = normalized.bookId || bookId;
    if (!finalBookId) {
      throw new ApiError(422, "Invalid detail payload from external API");
    }

    await this.repository.saveDetail({ ...normalized, bookId: finalBookId, raw: objectPayload });
    const stored = await this.repository.getDetailByBookId(finalBookId);
    if (!stored) {
      throw new ApiError(500, "Failed to persist drama detail");
    }
    return stored;
  }

  async getEpisodes(bookId: string): Promise<{ bookId: string; episodes: EpisodeNormalized[] }> {
    const existing = await this.repository.getEpisodesByBookId(bookId);
    if (existing && existing.length > 0) {
      return { bookId, episodes: existing };
    }

    const payload = await this.externalService.fetchEpisodes(bookId);
    const episodesRaw = extractArrayPayload(payload);
    const normalized = episodesRaw
      .map((item) => normalizeEpisode(bookId, item))
      .filter((episode) => episode.encryptedUrl.length > 0)
      .sort((a, b) => a.episodeNumber - b.episodeNumber);

    await this.repository.saveEpisodes(bookId, normalized);
    return { bookId, episodes: (await this.repository.getEpisodesByBookId(bookId)) ?? [] };
  }

  async stream(url: string): Promise<Record<string, unknown>> {
    const key = url.trim();
    if (!key) {
      throw new ApiError(400, "Invalid stream URL");
    }

    const now = Date.now();
    const existing = streamCache.get(key);
    if (existing && existing.expiresAt > now) {
      return existing.payload;
    }

    const inFlight = streamInFlight.get(key);
    if (inFlight) {
      return inFlight;
    }

    const task = (async () => {
      const payload = await this.externalService.decryptStream(key);
      const objectPayload = extractObjectPayload(payload);
      if (!objectPayload) {
        throw new ApiError(502, "Invalid stream payload from external API");
      }
      streamCache.set(key, { payload: objectPayload, expiresAt: Date.now() + STREAM_CACHE_TTL_MS });
      return objectPayload;
    })();

    streamInFlight.set(key, task);
    try {
      return await task;
    } catch (error) {
      if (existing) {
        return existing.payload;
      }
      throw error;
    } finally {
      streamInFlight.delete(key);
    }
  }

  getUpstreamDiagnostics(): Record<string, unknown> {
    return this.externalService.getDiagnostics();
  }

  async getEngagement(bookId: string, episodeId: string, memberId?: string): Promise<{
    bookId: string;
    episodeId: string;
    likeCount: number;
    commentCount: number;
    playCount: number;
    likedByMe: boolean;
    comments: Array<{ memberId: string; memberName: string; content: string; createdAt: Date }>;
  }> {
    const existing = await this.repository.getEngagement(bookId, episodeId);
    if (!existing) {
      return {
        bookId,
        episodeId,
        likeCount: 0,
        commentCount: 0,
        playCount: 0,
        likedByMe: false,
        comments: []
      };
    }
    return {
      bookId,
      episodeId,
      likeCount: existing.likes.length,
      commentCount: existing.comments.length,
      playCount: existing.playCount,
      likedByMe: memberId ? existing.likes.includes(memberId) : false,
      comments: existing.comments
    };
  }

  async trackPlay(bookId: string, episodeId: string): Promise<{ playCount: number }> {
    await this.repository.incrementPlayCount(bookId, episodeId);
    const updated = await this.repository.getEngagement(bookId, episodeId);
    return { playCount: updated?.playCount ?? 0 };
  }

  async toggleLike(bookId: string, episodeId: string, memberId: string): Promise<{
    likedByMe: boolean;
    likeCount: number;
  }> {
    const likedByMe = await this.repository.toggleLike(bookId, episodeId, memberId);
    const updated = await this.repository.getEngagement(bookId, episodeId);
    return { likedByMe, likeCount: updated?.likes.length ?? 0 };
  }

  async addComment(bookId: string, episodeId: string, memberId: string, content: string): Promise<{
    commentCount: number;
    comments: Array<{ memberId: string; memberName: string; content: string; createdAt: Date }>;
  }> {
    const member = await MemberModel.findById(memberId).lean().exec();
    if (!member) {
      throw new ApiError(404, "Member not found");
    }

    const existing = await this.repository.getEngagement(bookId, episodeId);
    if (existing) {
      const lastByMember = existing.comments
        .filter((item) => item.memberId === memberId)
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())[0];
      if (lastByMember) {
        const elapsed = Date.now() - new Date(lastByMember.createdAt).getTime();
        if (elapsed < COMMENT_COOLDOWN_MS) {
          const remainingMs = COMMENT_COOLDOWN_MS - elapsed;
          const remainingSeconds = Math.max(1, Math.ceil(remainingMs / 1000));
          throw new ApiError(429, `Tunggu ${remainingSeconds} detik sebelum komentar lagi`);
        }
      }
    }

    await this.repository.addComment(bookId, episodeId, {
      memberId,
      memberName: member.name,
      content: content.trim(),
      createdAt: new Date()
    });
    const updated = await this.repository.getEngagement(bookId, episodeId);
    return {
      commentCount: updated?.comments.length ?? 0,
      comments: updated?.comments ?? []
    };
  }

  async getComments(bookId: string, episodeId: string, page: number, limit: number): Promise<{
    bookId: string;
    episodeId: string;
    page: number;
    limit: number;
    total: number;
    items: Array<{ memberId: string; memberName: string; content: string; createdAt: Date }>;
  }> {
    const finalPage = Number.isFinite(page) && page > 0 ? page : 1;
    const finalLimit = Number.isFinite(limit) ? Math.min(50, Math.max(1, limit)) : 20;
    const result = await this.repository.getCommentsPage(bookId, episodeId, finalPage, finalLimit);
    return {
      bookId,
      episodeId,
      page: finalPage,
      limit: finalLimit,
      total: result.total,
      items: result.comments
    };
  }

  private normalizeDramaCollection(payload: unknown): DramaNormalized[] {
    return extractArrayPayload(payload)
      .map((item) => normalizeDrama(item))
      .filter((item) => item.bookId.length > 0 && item.title.length > 0);
  }

  private normalizeDubindoClassify(classify: string): "terpopuler" | "terbaru" {
    const normalized = classify.trim().toLowerCase();
    return normalized === "terbaru" ? "terbaru" : "terpopuler";
  }
}
