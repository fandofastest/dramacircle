import { Request, Response } from "express";
import { AdminService } from "../services/admin.service";

export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  login = async (req: Request, res: Response): Promise<void> => {
    const username = String(req.body.username ?? "");
    const password = String(req.body.password ?? "");
    const data = await this.adminService.login(username, password);
    res.status(200).json({ success: true, data });
  };

  listMembers = async (_req: Request, res: Response): Promise<void> => {
    const data = await this.adminService.listMembers();
    res.status(200).json({ success: true, data });
  };

  createMember = async (req: Request, res: Response): Promise<void> => {
    const data = await this.adminService.createMember({
      name: String(req.body.name ?? ""),
      email: String(req.body.email ?? ""),
      password: String(req.body.password ?? ""),
      isVip: Boolean(req.body.isVip)
    });
    res.status(201).json({ success: true, data });
  };

  updateMember = async (req: Request, res: Response): Promise<void> => {
    const memberId = String(req.params.memberId);
    const data = await this.adminService.updateMember(memberId, {
      name: req.body.name as string | undefined,
      email: req.body.email as string | undefined,
      password: req.body.password as string | undefined,
      isVip: req.body.isVip as boolean | undefined
    });
    res.status(200).json({ success: true, data });
  };

  deleteMember = async (req: Request, res: Response): Promise<void> => {
    const memberId = String(req.params.memberId);
    await this.adminService.deleteMember(memberId);
    res.status(200).json({ success: true, data: { deleted: true } });
  };
}
