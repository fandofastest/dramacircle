import { Router } from "express";
import { AdminController } from "../controllers/admin.controller";
import { requireAdmin } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { MemberRepository } from "../repositories/member.repository";
import { AdminService } from "../services/admin.service";
import { asyncHandler } from "../utils/asyncHandler";
import {
  adminCreateMemberSchema,
  adminLoginSchema,
  adminUpdateMemberSchema,
  memberIdParamSchema
} from "../validation/admin.validation";

const router = Router();
const memberRepository = new MemberRepository();
const adminService = new AdminService(memberRepository);
const controller = new AdminController(adminService);

router.post("/login", validate(adminLoginSchema, "body"), asyncHandler(controller.login));
router.get("/members", requireAdmin, asyncHandler(controller.listMembers));
router.post("/members", requireAdmin, validate(adminCreateMemberSchema, "body"), asyncHandler(controller.createMember));
router.patch(
  "/members/:memberId",
  requireAdmin,
  validate(memberIdParamSchema, "params"),
  validate(adminUpdateMemberSchema, "body"),
  asyncHandler(controller.updateMember)
);
router.delete(
  "/members/:memberId",
  requireAdmin,
  validate(memberIdParamSchema, "params"),
  asyncHandler(controller.deleteMember)
);

export default router;
