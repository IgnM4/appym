import { writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { z } from "zod";
import {
  OpenAPIRegistry,
  OpenApiGeneratorV3,
  extendZodWithOpenApi,
} from "@asteasolutions/zod-to-openapi";
import type { OpenAPIObjectConfig } from "@asteasolutions/zod-to-openapi/dist/v3.0/openapi-generator";

import pkg from "../package.json";
import {
  clienteBodySchema,
  clienteIdParamsSchema,
} from "./dto/clientes.dto.js";
import { ventaBodySchema } from "./dto/ventas.dto.js";
import {
  loginBodySchema,
  refreshBodySchema,
  apiKeyBodySchema,
} from "./dto/auth.dto.js";

extendZodWithOpenApi(z);

const port = Number(process.env.PORT) || 3000;

const registry = new OpenAPIRegistry();

const tokensSchema = registry.register(
  "AuthTokens",
  z.object({ accessToken: z.string(), refreshToken: z.string() })
);
const apiKeyResponseSchema = registry.register(
  "ApiKeyResponse",
  z.object({ apiKey: z.string() })
);

registry.registerPath({
  method: "post",
  path: "/auth/login",
  request: {
    body: {
      content: {
        "application/json": { schema: loginBodySchema },
      },
    },
  },
  responses: {
    200: {
      description: "Tokens",
      content: { "application/json": { schema: tokensSchema } },
    },
  },
});

registry.registerPath({
  method: "post",
  path: "/auth/refresh",
  request: {
    body: {
      content: {
        "application/json": { schema: refreshBodySchema },
      },
    },
  },
  responses: {
    200: {
      description: "Tokens",
      content: { "application/json": { schema: tokensSchema } },
    },
  },
});

registry.registerPath({
  method: "post",
  path: "/auth/logout",
  request: {
    body: {
      content: {
        "application/json": { schema: refreshBodySchema },
      },
    },
  },
  responses: {
    200: {
      description: "Logout",
      content: { "application/json": { schema: z.object({ ok: z.boolean() }) } },
    },
  },
});

registry.registerPath({
  method: "post",
  path: "/auth/apikey",
  request: {
    body: {
      content: {
        "application/json": { schema: apiKeyBodySchema },
      },
    },
  },
  security: [{ bearerAuth: [] }],
  responses: {
    201: {
      description: "API key",
      content: { "application/json": { schema: apiKeyResponseSchema } },
    },
  },
});
const clienteSchema = registry.register(
  "Cliente",
  clienteBodySchema.extend({ id: z.number().int().positive() })
);

registry.registerPath({
  method: "get",
  path: "/api/clientes",
  security: [{ bearerAuth: [] }, { apiKeyAuth: [] }],
  responses: {
    200: {
      description: "Lista de clientes",
      content: {
        "application/json": {
          schema: z.array(clienteSchema),
        },
      },
    },
  },
});

registry.registerPath({
  method: "post",
  path: "/api/clientes",
  security: [{ bearerAuth: [] }, { apiKeyAuth: [] }],
  request: {
    body: {
      content: {
        "application/json": { schema: clienteBodySchema },
      },
    },
  },
  responses: {
    201: {
      description: "Cliente creado",
      content: {
        "application/json": { schema: clienteSchema },
      },
    },
  },
});

registry.registerPath({
  method: "get",
  path: "/api/clientes/{id}",
  security: [{ bearerAuth: [] }, { apiKeyAuth: [] }],
  request: { params: clienteIdParamsSchema },
  responses: {
    200: {
      description: "Cliente",
      content: {
        "application/json": { schema: clienteSchema },
      },
    },
    404: { description: "No encontrado" },
  },
});

const ventaResponseSchema = registry.register(
  "VentaResponse",
  z.object({
    ok: z.literal(true),
    idBoleta: z.number().int(),
    numero: z.string(),
    idCliente: z.number().int(),
    origenUbicacion: z.number().int(),
    items: z.array(
      z.object({ idProducto: z.number().int(), cantidad: z.number().int() })
    ),
    totales: z.object({
      neto: z.number(),
      iva: z.number(),
      total: z.number(),
    }),
  })
);

registry.registerPath({
  method: "post",
  path: "/api/ventas",
  security: [{ bearerAuth: [] }, { apiKeyAuth: [] }],
  request: {
    headers: z.object({ "Idempotency-Key": z.string().optional() }),
    body: {
      content: {
        "application/json": { schema: ventaBodySchema },
      },
    },
  },
  responses: {
    201: {
      description: "Venta creada",
      content: {
        "application/json": { schema: ventaResponseSchema },
      },
    },
  },
});

const generator = new OpenApiGeneratorV3(registry.definitions);
const document = generator.generateDocument({
  openapi: "3.0.0",
  info: {
    title: "API",
    version: pkg.version,
  },
  servers: [{ url: `http://localhost:${port}` }],
} as OpenAPIObjectConfig);
document.components = {
  ...document.components,
  securitySchemes: {
    bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
    apiKeyAuth: { type: "apiKey", in: "header", name: "x-api-key" },
  },
};

export function generateOpenApi(): void {
  const outDir = join(process.cwd(), "dist");
  mkdirSync(outDir, { recursive: true });
  writeFileSync(join(outDir, "openapi.json"), JSON.stringify(document, null, 2));
}

if (require.main === module) {
  generateOpenApi();
}
