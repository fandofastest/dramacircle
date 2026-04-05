import { Request, Response } from "express";
import { DramaService } from "../services/drama.service";
import { MemberService } from "../services/member.service";

export class MemberController {
  constructor(
    private readonly memberService: MemberService,
    private readonly dramaService: DramaService
  ) {}

  register = async (req: Request, res: Response): Promise<void> => {
    const name = String(req.body.name ?? "");
    const email = String(req.body.email ?? "");
    const password = String(req.body.password ?? "");
    const data = await this.memberService.register(name, email, password);
    res.status(201).json({ success: true, data });
  };

  login = async (req: Request, res: Response): Promise<void> => {
    const email = String(req.body.email ?? "");
    const password = String(req.body.password ?? "");
    const data = await this.memberService.login(email, password);
    res.status(200).json({ success: true, data });
  };

  me = async (_req: Request, res: Response): Promise<void> => {
    const memberId = String(res.locals.memberId);
    const data = await this.memberService.getProfile(memberId);
    res.status(200).json({ success: true, data });
  };

  setVipStatus = async (req: Request, res: Response): Promise<void> => {
    const memberId = String(res.locals.memberId);
    const isVip = Boolean(req.body.isVip);
    const data = await this.memberService.setVipStatus(memberId, isVip);
    res.status(200).json({ success: true, data });
  };

  getVipDrama = async (_req: Request, res: Response): Promise<void> => {
    const data = await this.dramaService.getVip();
    res.status(200).json({ success: true, data });
  };
}
