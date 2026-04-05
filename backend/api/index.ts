import app from "../src/app";
import { connectDatabase } from "../src/config/database";

let initialized = false;

const handler = async (
  req: Parameters<typeof app>[0],
  res: Parameters<typeof app>[1]
): Promise<void> => {
  if (!initialized) {
    await connectDatabase();
    initialized = true;
  }
  app(req, res);
};

export default handler;
