FROM node:22-alpine AS builder

WORKDIR /app

# Copy package and config files
COPY package*.json ./
COPY tsconfig.json ./
COPY global.d.ts ./
COPY worker-configuration.d.ts ./
COPY wrangler.jsonc ./

# Install ALL dependencies (devDeps needed for build + wrangler dev runtime)
RUN npm ci

# Copy source code
COPY src/ ./src/

# Build TypeScript -> dist/
RUN npm run build

# ============================================================
# Runtime stage
# ============================================================
FROM node:22-alpine AS runtime

WORKDIR /app

# Copy everything from builder (node_modules includes wrangler)
COPY --from=builder /app /app

# Entrypoint script writes env vars to .dev.vars for wrangler
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# This MCP server is built on the Cloudflare Workers runtime
# (McpAgent, Durable Objects, KV via @cloudflare/workers-oauth-provider).
# We use `wrangler dev` which wraps workerd/miniflare to emulate
# the Workers runtime as a standalone HTTP service anywhere.
#
#   --remote=false   local-only emulation of DO / KV
#   --persist-to     keep KV + DO state across restarts
#   --ip 0.0.0.0     listen on all container interfaces
#
EXPOSE 3000

ENTRYPOINT ["/docker-entrypoint.sh"]
