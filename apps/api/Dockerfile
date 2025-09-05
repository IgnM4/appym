# syntax=docker/dockerfile:1
FROM node:20-alpine AS base
WORKDIR /app

FROM base AS deps
COPY package*.json ./
RUN npm ci --omit=optional --include=dev

FROM deps AS build
COPY . .
RUN npm run build

FROM base AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
RUN npm prune --omit=dev
COPY --from=build /app/dist ./dist
HEALTHCHECK --interval=30s --timeout=5s CMD node -e "require('http').get('http://localhost:4000/ready',r=>r.statusCode===200?process.exit(0):process.exit(1)).on('error',()=>process.exit(1))"
USER node
EXPOSE 4000
CMD ["node","dist/app.js"]
