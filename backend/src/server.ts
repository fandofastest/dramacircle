import app from "./app";
import { connectDatabase } from "./config/database";
import { env } from "./config/env";
import { logger } from "./utils/logger";

const bootstrap = async (): Promise<void> => {
  await connectDatabase();
  app.listen(env.PORT, () => {
    logger.info(`Server running on port ${env.PORT}`, { env: env.NODE_ENV });
  });
};

bootstrap().catch((error) => {
  logger.error("Failed to bootstrap server", { error: error instanceof Error ? error.message : String(error) });
  process.exit(1);
});
