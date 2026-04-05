import { Router } from "express";
import { MemberController } from "../controllers/member.controller";
import { requireAuth, requireVip } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { DramaRepository } from "../repositories/drama.repository";
import { MemberRepository } from "../repositories/member.repository";
import { DramaService } from "../services/drama.service";
import { ExternalDramaService } from "../services/externalDrama.service";
import { MemberService } from "../services/member.service";
import { asyncHandler } from "../utils/asyncHandler";
import { loginSchema, registerSchema, updateVipSchema } from "../validation/member.validation";

const router = Router();
const memberRepository = new MemberRepository();
const memberService = new MemberService(memberRepository);
const dramaRepository = new DramaRepository();
const externalService = new ExternalDramaService();
const dramaService = new DramaService(dramaRepository, externalService);
const controller = new MemberController(memberService, dramaService);

router.post("/register", validate(registerSchema, "body"), asyncHandler(controller.register));
router.post("/login", validate(loginSchema, "body"), asyncHandler(controller.login));
router.get("/me", requireAuth, asyncHandler(controller.me));
router.patch("/vip", requireAuth, validate(updateVipSchema, "body"), asyncHandler(controller.setVipStatus));
router.get("/vip/content", requireAuth, requireVip, asyncHandler(controller.getVipDrama));

export default router;
