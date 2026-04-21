import { Router } from "express";
import { DramaController } from "../controllers/drama.controller";
import { optionalAuth, requireAuth, requireVip } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { DramaRepository } from "../repositories/drama.repository";
import { DramaService } from "../services/drama.service";
import { ExternalDramaService } from "../services/externalDrama.service";
import { asyncHandler } from "../utils/asyncHandler";
import {
  dubindoQuerySchema,
  detailParamsSchema,
  engagementParamsSchema,
  episodesParamsSchema,
  forYouQuerySchema,
  searchQuerySchema,
  streamQuerySchema,
  addCommentBodySchema,
  commentsQuerySchema
} from "../validation/drama.validation";

const router = Router();
const repository = new DramaRepository();
const externalService = new ExternalDramaService();
const service = new DramaService(repository, externalService);
const controller = new DramaController(service);

router.get("/foryou", validate(forYouQuerySchema, "query"), asyncHandler(controller.getForYou));
router.get("/trending", asyncHandler(controller.getTrending));
router.get("/latest", asyncHandler(controller.getLatest));
router.get("/vip", requireAuth, requireVip, asyncHandler(controller.getVip));
router.get("/dubindo", validate(dubindoQuerySchema, "query"), asyncHandler(controller.getDubindo));
router.get("/randomdrama", asyncHandler(controller.getRandomDrama));
router.get("/populersearch", asyncHandler(controller.getPopulerSearch));
router.get("/search", validate(searchQuerySchema, "query"), asyncHandler(controller.search));
router.get("/detail/:bookId", validate(detailParamsSchema, "params"), asyncHandler(controller.getDetail));
router.get("/episodes/:bookId", validate(episodesParamsSchema, "params"), asyncHandler(controller.getEpisodes));
router.get("/allepisode/:bookId", validate(episodesParamsSchema, "params"), asyncHandler(controller.getAllEpisodeRaw));
router.get("/stream", validate(streamQuerySchema, "query"), asyncHandler(controller.stream));
router.get("/upstream-diagnostics", asyncHandler(controller.getUpstreamDiagnostics));
router.get(
  "/engagement/:bookId/:episodeId",
  optionalAuth,
  validate(engagementParamsSchema, "params"),
  asyncHandler(controller.getEngagement)
);
router.get(
  "/engagement/:bookId/:episodeId/comments",
  validate(engagementParamsSchema, "params"),
  validate(commentsQuerySchema, "query"),
  asyncHandler(controller.getComments)
);
router.post(
  "/engagement/:bookId/:episodeId/play",
  validate(engagementParamsSchema, "params"),
  asyncHandler(controller.trackPlay)
);
router.post(
  "/engagement/:bookId/:episodeId/like",
  requireAuth,
  validate(engagementParamsSchema, "params"),
  asyncHandler(controller.toggleLike)
);
router.post(
  "/engagement/:bookId/:episodeId/comment",
  requireAuth,
  validate(engagementParamsSchema, "params"),
  validate(addCommentBodySchema, "body"),
  asyncHandler(controller.addComment)
);

export default router;
