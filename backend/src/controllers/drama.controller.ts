import { Request, Response } from "express";
import { DramaService } from "../services/drama.service";

export class DramaController {
  constructor(private readonly dramaService: DramaService) {}

  getForYou = async (req: Request, res: Response): Promise<void> => {
    const page = Number(req.query.page ?? 1);
    const data = await this.dramaService.getForYou(page);
    res.status(200).json({ success: true, data });
  };

  getTrending = async (_req: Request, res: Response): Promise<void> => {
    const data = await this.dramaService.getTrending();
    res.status(200).json({ success: true, data });
  };

  getLatest = async (_req: Request, res: Response): Promise<void> => {
    const data = await this.dramaService.getLatest();
    res.status(200).json({ success: true, data });
  };

  getVip = async (_req: Request, res: Response): Promise<void> => {
    const data = await this.dramaService.getVip();
    res.status(200).json({ success: true, data });
  };

  getDubindo = async (req: Request, res: Response): Promise<void> => {
    const classify = String(req.query.classify ?? "terpopuler");
    const data = await this.dramaService.getDubindo(classify);
    res.status(200).json({ success: true, data });
  };

  getRandomDrama = async (_req: Request, res: Response): Promise<void> => {
    const data = await this.dramaService.getRandomDrama();
    res.status(200).json({ success: true, data });
  };

  getPopulerSearch = async (_req: Request, res: Response): Promise<void> => {
    const data = await this.dramaService.getPopulerSearch();
    res.status(200).json({ success: true, data });
  };

  search = async (req: Request, res: Response): Promise<void> => {
    const query = String(req.query.query ?? "");
    const data = await this.dramaService.search(query);
    res.status(200).json({ success: true, data });
  };

  getDetail = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const data = await this.dramaService.getDetail(bookId);
    res.status(200).json({ success: true, data });
  };

  getEpisodes = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const data = await this.dramaService.getEpisodes(bookId);
    res.status(200).json({ success: true, data });
  };

  getAllEpisodeRaw = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const data = await this.dramaService.getAllEpisodeRaw(bookId);
    res.status(200).json({ success: true, data });
  };

  stream = async (req: Request, res: Response): Promise<void> => {
    const url = String(req.query.url ?? "");
    const data = await this.dramaService.stream(url);
    res.status(200).json({ success: true, data });
  };

  getEngagement = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const episodeId = String(req.params.episodeId);
    const memberId = typeof res.locals.memberId === "string" ? (res.locals.memberId as string) : undefined;
    const data = await this.dramaService.getEngagement(bookId, episodeId, memberId);
    res.status(200).json({ success: true, data });
  };

  trackPlay = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const episodeId = String(req.params.episodeId);
    const data = await this.dramaService.trackPlay(bookId, episodeId);
    res.status(200).json({ success: true, data });
  };

  toggleLike = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const episodeId = String(req.params.episodeId);
    const memberId = String(res.locals.memberId);
    const data = await this.dramaService.toggleLike(bookId, episodeId, memberId);
    res.status(200).json({ success: true, data });
  };

  addComment = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const episodeId = String(req.params.episodeId);
    const memberId = String(res.locals.memberId);
    const content = String(req.body.content ?? "");
    const data = await this.dramaService.addComment(bookId, episodeId, memberId, content);
    res.status(201).json({ success: true, data });
  };

  getComments = async (req: Request, res: Response): Promise<void> => {
    const bookId = String(req.params.bookId);
    const episodeId = String(req.params.episodeId);
    const page = Number(req.query.page ?? 1);
    const limit = Number(req.query.limit ?? 20);
    const data = await this.dramaService.getComments(bookId, episodeId, page, limit);
    res.status(200).json({ success: true, data });
  };

  getUpstreamDiagnostics = async (_req: Request, res: Response): Promise<void> => {
    const data = this.dramaService.getUpstreamDiagnostics();
    res.status(200).json({ success: true, data });
  };
}
