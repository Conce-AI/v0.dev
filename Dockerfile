# =============================================================================
# Node.js Dockerfile for v0-mcp-ts - Smithery Compatible
# Using official Node.js image for maximum deployment platform compatibility
# =============================================================================

FROM node:25-alpine

# Install system dependencies for security and signal handling
RUN apk add --no-cache \
    dumb-init \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Install Bun for building (but run with Node.js)
RUN npm install -g bun@latest

# Copy package files first
COPY package.json bun.lock* ./

# Copy source code (needed for build)
COPY . .

# Install dependencies with Bun
RUN bun install --production

# Set production environment
ENV NODE_ENV=production \
    PORT=3000 \
    LOG_LEVEL=info

# Change ownership to nodejs user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:'+process.env.PORT+'/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start the HTTP server with Node.js for maximum compatibility
CMD ["node", "dist/http-server.js"]

# -----------------------------------------------------------------------------
# Metadata
# -----------------------------------------------------------------------------
LABEL maintainer="Nicolas Torres <nicotordev@gmail.com>" \
      description="v0-mcp-ts: Node.js compatible MCP server for v0.dev AI integration" \
      version="2.0.0" \
      repository="https://github.com/nicotordev/v0-mcp-ts" \
      license="MIT" 