export type DramaItem = {
  bookId: string;
  title: string;
  cover: string | null;
  description: string | null;
  category: string[];
  totalEpisodes: number | null;
  source: "external_api";
};
