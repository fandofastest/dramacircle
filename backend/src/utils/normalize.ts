export type DramaNormalized = {
  bookId: string;
  title: string;
  cover: string | null;
  description: string | null;
  category: string[];
  totalEpisodes: number | null;
  source: "external_api";
};

export type EpisodeNormalized = {
  bookId: string;
  episodeNumber: number;
  encryptedUrl: string;
};

const toStringValue = (value: unknown): string => {
  if (typeof value === "string") {
    return value;
  }
  if (typeof value === "number") {
    return String(value);
  }
  return "";
};

const findEncryptedUrlFromCdnList = (value: unknown): string => {
  if (!Array.isArray(value)) {
    return "";
  }

  for (const cdn of value) {
    if (!cdn || typeof cdn !== "object") {
      continue;
    }
    const cdnObject = cdn as Record<string, unknown>;
    const videoPathList = cdnObject.videoPathList;
    if (!Array.isArray(videoPathList)) {
      continue;
    }
    const preferred = videoPathList.find((entry) => {
      if (!entry || typeof entry !== "object") {
        return false;
      }
      const record = entry as Record<string, unknown>;
      return record.isDefault === 1 || record.isDefault === true;
    });
    const first = preferred ?? videoPathList[0];
    if (first && typeof first === "object") {
      const candidate = toStringValue((first as Record<string, unknown>).videoPath);
      if (candidate.length > 0) {
        return candidate;
      }
    }
  }

  return "";
};

export const extractArrayPayload = (payload: unknown): Record<string, unknown>[] => {
  if (Array.isArray(payload)) {
    return payload.filter((item): item is Record<string, unknown> => typeof item === "object" && item !== null);
  }

  if (payload && typeof payload === "object") {
    const objectPayload = payload as Record<string, unknown>;
    const candidates = [objectPayload.data, objectPayload.result, objectPayload.results, objectPayload.items];
    for (const candidate of candidates) {
      if (Array.isArray(candidate)) {
        return candidate.filter(
          (item): item is Record<string, unknown> => typeof item === "object" && item !== null
        );
      }
    }
  }

  return [];
};

export const extractObjectPayload = (payload: unknown): Record<string, unknown> | null => {
  if (payload && typeof payload === "object" && !Array.isArray(payload)) {
    const objectPayload = payload as Record<string, unknown>;
    const candidates = [objectPayload.data, objectPayload.result, objectPayload.item];
    for (const candidate of candidates) {
      if (candidate && typeof candidate === "object" && !Array.isArray(candidate)) {
        return candidate as Record<string, unknown>;
      }
    }
    return objectPayload;
  }
  return null;
};

export const normalizeDrama = (input: Record<string, unknown>): DramaNormalized => {
  const categoryRaw = input.category ?? input.categories ?? input.tag ?? input.tags ?? input.tagNames ?? [];
  const category = Array.isArray(categoryRaw)
    ? categoryRaw.map((item) => toStringValue(item)).filter(Boolean)
    : toStringValue(categoryRaw)
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean);

  const totalEpisodesRaw = input.totalEpisodes ?? input.total_episode ?? input.episode_total ?? input.chapterCount;
  const totalEpisodesNumber =
    typeof totalEpisodesRaw === "number" ? totalEpisodesRaw : Number.parseInt(toStringValue(totalEpisodesRaw), 10);

  return {
    bookId: toStringValue(input.bookId ?? input.book_id ?? input.id),
    title: toStringValue(input.title ?? input.name ?? input.book_title ?? input.bookName),
    cover: toStringValue(input.cover ?? input.coverUrl ?? input.thumbnail ?? input.coverWap ?? input.bookCover) || null,
    description: toStringValue(input.description ?? input.desc ?? input.summary ?? input.introduction) || null,
    category,
    totalEpisodes: Number.isNaN(totalEpisodesNumber) ? null : totalEpisodesNumber,
    source: "external_api"
  };
};

export const normalizeEpisode = (bookId: string, input: Record<string, unknown>): EpisodeNormalized => {
  const episodeRaw =
    input.episodeNumber ?? input.episode ?? input.num ?? input.index ?? input.chapterIndex ?? input.chapterOrder;
  const numericEpisodeRaw =
    typeof episodeRaw === "number" ? episodeRaw : Number.parseInt(toStringValue(episodeRaw), 10) || 0;
  const episodeNumber =
    input.chapterIndex !== undefined && numericEpisodeRaw >= 0 ? numericEpisodeRaw + 1 : numericEpisodeRaw;

  return {
    bookId,
    episodeNumber,
    encryptedUrl:
      toStringValue(input.encryptedUrl ?? input.url ?? input.playUrl ?? input.streamUrl) ||
      findEncryptedUrlFromCdnList(input.cdnList)
  };
};
