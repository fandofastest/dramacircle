export const openApiDocument = {
  openapi: "3.1.0",
  info: {
    title: "ColongAPI Backend",
    version: "1.0.0",
    description: "Backend service for drama data with MongoDB persistence-first strategy."
  },
  servers: [
    {
      url: "/"
    }
  ],
  tags: [
    { name: "Health" },
    { name: "Drama" },
    { name: "Member" },
    { name: "Admin" }
  ],
  paths: {
    "/health": {
      get: {
        tags: ["Health"],
        summary: "Health check",
        responses: {
          "200": {
            description: "Service is healthy"
          }
        }
      }
    },
    "/api/drama/foryou": {
      get: {
        tags: ["Drama"],
        summary: "Get for-you drama list",
        parameters: [
          {
            name: "page",
            in: "query",
            required: false,
            schema: { type: "integer", minimum: 1, default: 1 }
          }
        ],
        responses: {
          "200": { description: "For-you data returned" }
        }
      }
    },
    "/api/drama/trending": {
      get: {
        tags: ["Drama"],
        summary: "Get trending dramas",
        responses: {
          "200": { description: "Trending data returned" }
        }
      }
    },
    "/api/drama/latest": {
      get: {
        tags: ["Drama"],
        summary: "Get latest dramas",
        responses: {
          "200": { description: "Latest data returned" }
        }
      }
    },
    "/api/drama/vip": {
      get: {
        tags: ["Drama"],
        summary: "Get VIP page payload",
        security: [{ bearerAuth: [] }],
        responses: {
          "200": { description: "VIP data returned" }
        }
      }
    },
    "/api/drama/dubindo": {
      get: {
        tags: ["Drama"],
        summary: "Get dub indo drama list",
        parameters: [
          {
            name: "classify",
            in: "query",
            required: false,
            schema: { type: "string", enum: ["terpopuler", "terbaru"], default: "terpopuler" }
          }
        ],
        responses: {
          "200": { description: "Dub indo data returned" }
        }
      }
    },
    "/api/drama/randomdrama": {
      get: {
        tags: ["Drama"],
        summary: "Get random drama list",
        responses: {
          "200": { description: "Random drama data returned" }
        }
      }
    },
    "/api/drama/populersearch": {
      get: {
        tags: ["Drama"],
        summary: "Get populer search list",
        responses: {
          "200": { description: "Populer search data returned" }
        }
      }
    },
    "/api/drama/search": {
      get: {
        tags: ["Drama"],
        summary: "Search dramas",
        parameters: [
          {
            name: "query",
            in: "query",
            required: true,
            schema: { type: "string" }
          }
        ],
        responses: {
          "200": { description: "Search data returned" }
        }
      }
    },
    "/api/drama/detail/{bookId}": {
      get: {
        tags: ["Drama"],
        summary: "Get drama detail by bookId",
        parameters: [
          {
            name: "bookId",
            in: "path",
            required: true,
            schema: { type: "string" }
          }
        ],
        responses: {
          "200": { description: "Detail data returned" }
        }
      }
    },
    "/api/drama/episodes/{bookId}": {
      get: {
        tags: ["Drama"],
        summary: "Get encrypted episode list by bookId",
        parameters: [
          {
            name: "bookId",
            in: "path",
            required: true,
            schema: { type: "string" }
          }
        ],
        responses: {
          "200": { description: "Episodes data returned" }
        }
      }
    },
    "/api/drama/stream": {
      get: {
        tags: ["Drama"],
        summary: "Decrypt and return stream URL",
        parameters: [
          {
            name: "url",
            in: "query",
            required: true,
            schema: { type: "string", format: "uri" }
          }
        ],
        responses: {
          "200": { description: "Decrypted stream data returned" }
        }
      }
    },
    "/api/member/register": {
      post: {
        tags: ["Member"],
        summary: "Register member account",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  email: { type: "string", format: "email" },
                  password: { type: "string" }
                },
                required: ["name", "email", "password"]
              }
            }
          }
        },
        responses: {
          "201": { description: "Member registered" }
        }
      }
    },
    "/api/member/login": {
      post: {
        tags: ["Member"],
        summary: "Login member account",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  email: { type: "string", format: "email" },
                  password: { type: "string" }
                },
                required: ["email", "password"]
              }
            }
          }
        },
        responses: {
          "200": { description: "Login success" }
        }
      }
    },
    "/api/member/me": {
      get: {
        tags: ["Member"],
        summary: "Get profile member",
        security: [{ bearerAuth: [] }],
        responses: {
          "200": { description: "Profile data returned" }
        }
      }
    },
    "/api/member/vip": {
      patch: {
        tags: ["Member"],
        summary: "Change member VIP status",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  isVip: { type: "boolean" }
                },
                required: ["isVip"]
              }
            }
          }
        },
        responses: {
          "200": { description: "VIP status updated" }
        }
      }
    },
    "/api/member/vip/content": {
      get: {
        tags: ["Member"],
        summary: "Get drama VIP content for VIP member",
        security: [{ bearerAuth: [] }],
        responses: {
          "200": { description: "VIP drama data returned" }
        }
      }
    },
    "/api/admin/login": {
      post: {
        tags: ["Admin"],
        summary: "Login admin from env credentials",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  username: { type: "string" },
                  password: { type: "string" }
                },
                required: ["username", "password"]
              }
            }
          }
        },
        responses: {
          "200": { description: "Admin login success" }
        }
      }
    },
    "/api/admin/members": {
      get: {
        tags: ["Admin"],
        summary: "List all members",
        security: [{ bearerAuth: [] }],
        responses: {
          "200": { description: "Member list returned" }
        }
      },
      post: {
        tags: ["Admin"],
        summary: "Create member by admin",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  email: { type: "string", format: "email" },
                  password: { type: "string" },
                  isVip: { type: "boolean" }
                },
                required: ["name", "email", "password", "isVip"]
              }
            }
          }
        },
        responses: {
          "201": { description: "Member created" }
        }
      }
    },
    "/api/admin/members/{memberId}": {
      patch: {
        tags: ["Admin"],
        summary: "Edit member by admin",
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: "memberId",
            in: "path",
            required: true,
            schema: { type: "string" }
          }
        ],
        responses: {
          "200": { description: "Member updated" }
        }
      },
      delete: {
        tags: ["Admin"],
        summary: "Delete member by admin",
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: "memberId",
            in: "path",
            required: true,
            schema: { type: "string" }
          }
        ],
        responses: {
          "200": { description: "Member deleted" }
        }
      }
    },
    "/admin": {
      get: {
        tags: ["Admin"],
        summary: "Admin UI page",
        responses: {
          "200": { description: "HTML page returned" }
        }
      }
    }
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT"
      }
    }
  }
};
