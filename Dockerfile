# ============================================================
# STAGE 1 - Builder: instala todas las dependencias (incluye devDeps)
# ============================================================
FROM node:18-slim AS builder

WORKDIR /build

# Copiar archivos de dependencias primero (optimiza cache de capas)
COPY package*.json ./

# Instalar TODAS las dependencias (incluyendo devDependencies para build)
RUN npm ci --include=dev

# Copiar código fuente
COPY . .

# ============================================================
# STAGE 2 - Runtime: imagen final mínima y segura
# ============================================================
FROM node:18-slim AS runtime

# Metadatos de la imagen
LABEL maintainer="Innovatech Chile" \
      app="backend-node" \
      version="1.0"

# Crear usuario no-root (mínimo privilegio)
RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid appgroup --no-create-home --shell /bin/false appuser

WORKDIR /app

# Copiar solo las dependencias de producción desde builder
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copiar el código fuente desde el builder
COPY --from=builder --chown=appuser:appgroup /build/server.js ./server.js

# Eliminar archivos innecesarios
RUN rm -f .env.example

# Exponer el puerto del servidor Express
EXPOSE 3000

# Cambiar al usuario sin privilegios
USER appuser

# Variables de entorno por defecto
ENV PORT=3000 \
    NODE_ENV=production

# Healthcheck para monitoreo del contenedor
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/usuarios', (r) => r.statusCode < 500 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))"

# Comando de inicio (producción: sin nodemon)
CMD ["node", "server.js"]
