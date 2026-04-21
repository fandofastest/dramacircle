import axios from "axios";
import { env } from "../config/env";
import { externalApiClient } from "../config/externalApiClient";
import { ApiError } from "../utils/apiError";
import { logger } from "../utils/logger";

export class ExternalDramaService {
  private readonly diagnostics = new Map<string, { total: number; errors: number; rateLimited: number; lastStatus?: number }>();
  private readonly defaultLang = env.EXTERNAL_API_LANG;
  private readonly detailCode = env.EXTERNAL_API_CODE;

  async fetchForYou(page: number): Promise<unknown> {
    // Upstream foryou does not expose stable pagination; keep page in signature for compatibility.
    return this.fetch("/foryou", { lang: this.defaultLang, page });
  }

  async fetchTrending(): Promise<unknown> {
    const payload = await this.fetch("/homepage", { page: 1, lang: this.defaultLang });
    const records =
      payload &&
      typeof payload === "object" &&
      (payload as Record<string, unknown>).recommendList &&
      typeof (payload as Record<string, unknown>).recommendList === "object"
        ? ((payload as Record<string, unknown>).recommendList as Record<string, unknown>).records
        : [];
    return records;
  }

  async fetchLatest(): Promise<unknown> {
    return this.fetch("/latest", { lang: this.defaultLang });
  }

  async fetchVip(): Promise<unknown> {
    const dubbed = await this.fetch("/dubbed", { classify: "terpopuler", page: 1, lang: this.defaultLang });
    return { items: dubbed };
  }

  async fetchDubindo(classify: "terpopuler" | "terbaru"): Promise<unknown> {
    return this.fetch("/dubbed", { classify, page: 1, lang: this.defaultLang });
  }

  async searchDrama(query: string): Promise<unknown> {
    return this.fetch("/search", { query, lang: this.defaultLang });
  }

  async fetchDetail(bookId: string): Promise<unknown> {
    return this.fetch("/detail", { bookId, lang: this.defaultLang, code: this.detailCode });
  }

  async fetchEpisodes(bookId: string): Promise<unknown> {
    return this.fetch("/allepisode", { bookId, lang: this.defaultLang, code: this.detailCode });
  }

  async fetchAllEpisodeRaw(bookId: string): Promise<unknown> {
    return this.fetchEpisodes(bookId);
  }

  getDiagnostics(): Record<string, unknown> {
    const result: Record<string, unknown> = {};
    for (const [endpoint, value] of this.diagnostics.entries()) {
      result[endpoint] = value;
    }
    return result;
  }

  private async fetch(endpoint: string, params?: Record<string, unknown>): Promise<unknown> {
    const metric = this.diagnostics.get(endpoint) ?? { total: 0, errors: 0, rateLimited: 0, lastStatus: undefined };
    metric.total += 1;
    try {
      const startedAt = Date.now();
      const response = await externalApiClient.get(endpoint, { params });
      metric.lastStatus = response.status;
      this.diagnostics.set(endpoint, metric);
      logger.info("External API request success", {
        endpoint,
        status: response.status,
        durationMs: Date.now() - startedAt
      });
      return response.data;
    } catch (error) {
      metric.errors += 1;
      if (axios.isAxiosError(error)) {
        const status = error.response?.status;
        metric.lastStatus = status;
        if (status === 429) {
          metric.rateLimited += 1;
        }
        this.diagnostics.set(endpoint, metric);
        logger.warn("External API request failed", {
          endpoint,
          status,
          message: error.message
        });
        if (status === 401 || status === 403) {
          throw new ApiError(503, `External API rejected request at ${endpoint} (status ${status})`);
        }
        if (status === 429) {
          throw new ApiError(503, `External API rate limited at ${endpoint}`);
        }
      } else {
        this.diagnostics.set(endpoint, metric);
      }
      throw new ApiError(502, `External API request failed for ${endpoint}`);
    }
  }
}
