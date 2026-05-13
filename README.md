# ⚙️ Backend – Innovatech Chile (Node.js + MySQL + Docker + CI/CD)

API REST desarrollada en **Node.js/Express** para gestión de usuarios con base de datos **MySQL**. Desplegada en AWS EC2 mediante contenedores Docker con pipeline CI/CD automatizado.

---

## 📋 Tabla de contenidos

- [Stack tecnológico](#stack-tecnológico)
- [Arquitectura](#arquitectura)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Endpoints de la API](#endpoints-de-la-api)
- [Configuración de variables de entorno](#configuración-de-variables-de-entorno)
- [Ejecución local (sin Docker)](#ejecución-local-sin-docker)
- [Ejecución con Docker](#ejecución-con-docker)
- [Ejecución con Docker Compose](#ejecución-con-docker-compose)
- [Persistencia de datos (Volúmenes)](#persistencia-de-datos-volúmenes)
- [Pipeline CI/CD](#pipeline-cicd)
- [Secrets requeridos en GitHub](#secrets-requeridos-en-github)
- [Despliegue en AWS EC2](#despliegue-en-aws-ec2)

---

## 🛠 Stack tecnológico

| Componente | Tecnología | Versión |
|---|---|---|
| Lenguaje | JavaScript (Node.js) | 18 LTS |
| Framework web | Express | ^4.18.2 |
| Driver MySQL | mysql2 | ^3.6.0 |
| Variables de entorno | dotenv | ^16.3.1 |
| CORS | cors | ^2.8.5 |
| Base de datos | MySQL | 8.0 |
| Contenedor | Docker | 24+ |
| Registry | Docker Hub | - |
| CI/CD | GitHub Actions | - |
| Infraestructura | AWS EC2 | - |

---

## 🏗 Arquitectura

```
[EC2 Frontend - Subred Pública]
  Contenedor: innovatech-frontend (puerto 5000)
    │
    │  HTTP → puerto 3000 (IP privada de EC2 Backend)
    ▼
[EC2 Backend - Subred Privada]  ← Solo accesible desde Frontend (Security Group)
  Red Docker interna: innovatech-backend-network
    │
    ├── Contenedor: innovatech-backend (puerto 3000, expuesto en host)
    │     └── Se conecta a MySQL por nombre de servicio interno
    │
    └── Contenedor: innovatech-mysql (puerto 3306, solo red interna Docker)
          └── Volumen: innovatech-mysql-data (named volume → persistencia)
```

---

## 📁 Estructura del proyecto

```
backend/
├── .github/
│   └── workflows/
│       └── deploy-backend.yml    # Pipeline CI/CD
├── server.js                     # Servidor Express principal
├── package.json                  # Dependencias y scripts npm
├── Dockerfile                    # Multi-stage build
├── docker-compose.yml            # Stack backend + MySQL
├── .env.example                  # Plantilla de variables de entorno
├── .gitignore
└── README.md
```

---

## 🔌 Endpoints de la API

Base URL: `http://<host>:3000`

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/usuarios` | Obtener todos los usuarios |
| POST | `/api/usuarios` | Crear un nuevo usuario |
| PUT | `/api/usuarios/:id` | Actualizar un usuario |
| DELETE | `/api/usuarios/:id` | Eliminar un usuario |

### Ejemplos de uso

```bash
# Obtener todos los usuarios
curl http://localhost:3000/api/usuarios

# Crear usuario
curl -X POST http://localhost:3000/api/usuarios \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Ana López","email":"ana@ejemplo.com","edad":28}'

# Actualizar usuario
curl -X PUT http://localhost:3000/api/usuarios/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Ana López Actualizada","email":"ana@ejemplo.com","edad":29}'

# Eliminar usuario
curl -X DELETE http://localhost:3000/api/usuarios/1
```

---

## ⚙️ Configuración de variables de entorno

```bash
cp .env.example .env
nano .env
```

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `PORT` | Puerto del servidor Express | `3000` |
| `NODE_ENV` | Entorno de ejecución | `production` |
| `DB_HOST` | Host de MySQL (nombre del servicio) | `mysql` |
| `DB_PORT` | Puerto de MySQL | `3306` |
| `DB_NAME` | Nombre de la base de datos | `proyecto_db` |
| `DB_USER` | Usuario de la base de datos | `app_user` |
| `DB_PASSWORD` | Contraseña del usuario | *(requerida)* |
| `MYSQL_ROOT_PASSWORD` | Contraseña root MySQL (solo compose) | *(requerida)* |

---

## 🟢 Ejecución local (sin Docker)

```bash
# 1. Instalar dependencias
npm install

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con credenciales de MySQL local

# 3. Iniciar la API
npm start              # Producción
npm run dev            # Desarrollo (nodemon)

# Disponible en: http://localhost:3000
```

---

## 🐳 Ejecución con Docker

```bash
# Construir imagen (multi-stage)
docker build -t innovatech-backend:latest .

# Ejecutar contenedor (requiere MySQL ya corriendo)
docker run -d \
  --name innovatech-backend \
  -p 3000:3000 \
  -e DB_HOST=<host-mysql> \
  -e DB_USER=app_user \
  -e DB_PASSWORD=mi_password \
  -e DB_NAME=proyecto_db \
  innovatech-backend:latest

# Ver logs
docker logs -f innovatech-backend
```

---

## 🐙 Ejecución con Docker Compose

```bash
# Configurar variables de entorno
cp .env.example .env
nano .env  # Completar contraseñas

# Levantar backend + MySQL
docker compose up -d

# Ver logs
docker compose logs -f

# Ver logs solo del backend
docker compose logs -f backend

# Ver logs solo de MySQL
docker compose logs -f mysql

# Detener (conserva volúmenes y datos)
docker compose down

# Detener y eliminar datos (¡irreversible!)
docker compose down -v
```

---

## 💾 Persistencia de datos (Volúmenes)

Se usa un **named volume** (`innovatech-mysql-data`) para persistir los datos de MySQL.

### ¿Por qué named volume y no bind mount?

| Característica | Named Volume ✅ | Bind Mount ❌ |
|---|---|---|
| Gestión | Docker la administra | Depende del host |
| Portabilidad | Alta (cualquier host) | Baja (ruta específica) |
| Rendimiento I/O | Alto en Linux | Variable |
| Permisos | Gestionados por Docker | Problemas frecuentes |
| Respaldo | `docker volume` commands | Manual |

```bash
# Ver el volumen creado
docker volume ls | grep innovatech

# Inspeccionar el volumen
docker volume inspect innovatech-mysql-data

# Hacer backup del volumen
docker run --rm \
  -v innovatech-mysql-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mysql-backup.tar.gz /data
```

---

## 🔄 Pipeline CI/CD

Se activa automáticamente con cada `push` a la rama **`deploy`**.

### Flujo del pipeline

```
Push → rama deploy
        │
        ▼
   [Job 1: build-and-push]
   ├── Checkout código
   ├── Setup Docker Buildx
   ├── Login Docker Hub
   ├── Build imagen multi-stage
   └── Push a Docker Hub (:latest + :sha-XXXXX)
        │
        ▼ (solo si Job 1 exitoso)
   [Job 2: deploy-to-ec2]
   ├── SSH a EC2 Backend
   ├── Login Docker Hub en EC2
   ├── Pull imagen más reciente
   ├── Detener contenedor anterior
   ├── Asegurar red Docker interna
   ├── Levantar/verificar MySQL (si no corre)
   ├── Iniciar nuevo contenedor Backend
   └── Verificar estado + limpiar imágenes viejas
```

### Activar el pipeline

```bash
git checkout main
git add .
git commit -m "feat: nueva funcionalidad en backend"

git checkout deploy
git merge main
git push origin deploy
# ↑ Activa el pipeline automáticamente
```

---

## 🔐 Secrets requeridos en GitHub

Configurar en: `Repositorio → Settings → Secrets and variables → Actions`

| Secret | Descripción |
|---|---|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Access Token de Docker Hub |
| `EC2_BACKEND_HOST` | IP de la instancia EC2 Backend |
| `EC2_USERNAME` | Usuario SSH (`ec2-user` o `ubuntu`) |
| `EC2_SSH_PRIVATE_KEY` | Contenido completo de la clave `.pem` |
| `DB_NAME` | Nombre de la base de datos |
| `DB_USER` | Usuario de MySQL |
| `DB_PASSWORD` | Contraseña del usuario MySQL |
| `MYSQL_ROOT_PASSWORD` | Contraseña root de MySQL |

---

## ☁️ Despliegue en AWS EC2

### Requisitos previos en la instancia

```bash
# Instalar Docker (Amazon Linux 2)
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

### Configuración Security Group (AWS)

| Tipo | Puerto | Protocolo | Origen |
|---|---|---|---|
| SSH | 22 | TCP | Tu IP |
| HTTP personalizado | 3000 | TCP | Security Group del Frontend |

> **Importante**: El puerto 3000 solo debe ser accesible desde el Security Group de la instancia Frontend, **no** desde Internet.

---

## 📝 Notas sobre el Dockerfile (multi-stage)

- **Stage `builder`**: Instala todas las dependencias (incluyendo devDependencies)
- **Stage `runtime`**: Solo instala dependencias de producción (`npm ci --omit=dev`)

Optimizaciones aplicadas:
- ✅ **Usuario no-root** (`appuser`) — mínimo privilegio
- ✅ **Solo deps de producción** en imagen final
- ✅ **Cache limpiada** (`npm cache clean --force`)
- ✅ **Healthcheck** integrado para monitoreo
- ✅ **Restart policy** `unless-stopped` para alta disponibilidad

---

## 🔍 Troubleshooting

```bash
# Ver logs del backend
docker logs innovatech-backend

# Ver logs de MySQL
docker logs innovatech-mysql

# Verificar conectividad Backend → MySQL
docker exec innovatech-backend \
  node -e "const m=require('mysql2');const c=m.createConnection({host:'innovatech-mysql',user:'app_user',password:'pass',database:'proyecto_db'});c.connect(e=>console.log(e||'✅ Conectado'))"

# Entrar al contenedor
docker exec -it innovatech-backend /bin/sh

# Verificar variables de entorno
docker exec innovatech-backend env
```
