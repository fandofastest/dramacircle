import cors from "cors";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import morgan from "morgan";
import { env } from "./config/env";
import { openApiDocument } from "./config/openapi";
import { errorHandler } from "./middleware/errorHandler";
import { notFoundHandler } from "./middleware/notFound";
import adminRoutes from "./routes/admin.routes";
import dramaRoutes from "./routes/drama.routes";
import healthRoutes from "./routes/health.routes";
import memberRoutes from "./routes/member.routes";
import { adminUiHtml } from "./utils/adminUi";
import { logger } from "./utils/logger";

const app = express();

const limiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.method === "GET" && req.path.startsWith("/api/drama/")
});

app.use(
  helmet({
    contentSecurityPolicy: false
  })
);
app.use(cors());
app.use(express.json({ limit: "1mb" }));
if (env.NODE_ENV !== "development") {
  app.use(limiter);
}
app.use(
  morgan("combined", {
    stream: {
      write: (message: string) => logger.info(message.trim())
    }
  })
);

app.get("/api-docs", (_req, res) => {
  res.status(200).contentType("text/html").send(`<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>ColongAPI Docs</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
  </head>
  <body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
      window.ui = SwaggerUIBundle({
        url: '/api-docs.json',
        dom_id: '#swagger-ui',
        deepLinking: true
      });
    </script>
  </body>
</html>`);
});
app.get("/api-docs/", (_req, res) => {
  res.redirect(302, "/api-docs");
});
app.get("/api-docs.json", (_req, res) => {
  res.status(200).json(openApiDocument);
});

app.use("/health", healthRoutes);
app.use("/api/drama", dramaRoutes);
app.use("/api/member", memberRoutes);
app.use("/api/admin", adminRoutes);
app.get("/admin", (_req, res) => {
  res.status(200).contentType("text/html").send(adminUiHtml);
});

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
