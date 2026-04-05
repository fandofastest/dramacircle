import axios from "axios";
import { externalApiClient } from "../config/externalApiClient";
import { ApiError } from "../utils/apiError";
import { logger } from "../utils/logger";

export class ExternalDramaService {
  private readonly diagnostics = new Map<string, { total: number; errors: number; rateLimited: number; lastStatus?: number }>();

  async fetchForYou(page: number): Promise<unknown> {
    return this.fetch("/dramabox/foryou", { page });
  }

  async fetchTrending(): Promise<unknown> {
    return this.fetch("/dramabox/trending");
  }

  async fetchLatest(): Promise<unknown> {
    return this.fetch("/dramabox/latest");
  }

  async fetchVip(): Promise<unknown> {
    return this.fetch("/dramabox/vip");
  }

  async fetchDubindo(classify: "terpopuler" | "terbaru"): Promise<unknown> {
    return this.fetch("/dramabox/dubindo", { classify });
  }

  async fetchRandomDrama(): Promise<unknown> {
    return this.fetch("/dramabox/randomdrama");
  }

  async fetchPopulerSearch(): Promise<unknown> {
    return this.fetch("/dramabox/populersearch");
  }

  async searchDrama(query: string): Promise<unknown> {
    return this.fetch("/dramabox/search", { query });
  }

  async fetchDetail(bookId: string): Promise<unknown> {
    return this.fetch("/dramabox/detail", { bookId });
  }

  async fetchEpisodes(bookId: string): Promise<unknown> {
    return this.fetch("/dramabox/allepisode", { bookId });
  }

  async decryptStream(url: string): Promise<unknown> {
    return this.fetch("/dramabox/decrypt", { url });
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
