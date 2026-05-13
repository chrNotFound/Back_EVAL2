FROM node:18-slim AS builder

WORKDIR /build

COPY package*.json ./

RUN npm install

COPY . .

FROM node:18-slim AS runtime

LABEL maintainer="Innovatech Chile" \
      app="backend-node" \
      version="1.0"

RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid appgroup --no-create-home --shell /bin/false appuser

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

COPY --from=builder --chown=appuser:appgroup /build/server.js ./server.js

RUN rm -f .env.example

EXPOSE 3000

USER appuser

ENV PORT=3000 \
    NODE_ENV=production

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/usuarios', (r) => r.statusCode < 500 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))"

CMD ["node", "server.js"]