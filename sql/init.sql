-- ============================================================
-- init.sql - Script de inicialización de la base de datos
-- Se ejecuta automáticamente cuando el contenedor MySQL
-- arranca por primera vez (BD vacía)
-- ============================================================

-- Usar la base de datos del proyecto
USE proyecto_db;

-- Configurar charset correcto
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Crear tabla principal de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    nombre              VARCHAR(100)                        NOT NULL,
    email               VARCHAR(150)                        NOT NULL,
    edad                INT                                 NULL,
    fecha_creacion      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP         NOT NULL,
    estado              ENUM('activo', 'inactivo') DEFAULT 'activo' NOT NULL,

    UNIQUE INDEX idx_email   (email),
    INDEX        idx_nombre  (nombre),
    INDEX        idx_estado  (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar datos de ejemplo para verificar funcionamiento
INSERT INTO usuarios (nombre, email, edad, estado) VALUES
    ('Admin Sistema',  'admin@innovatech.cl',  30, 'activo'),
    ('Usuario Demo',   'demo@innovatech.cl',   25, 'activo'),
    ('Test Usuario',   'test@innovatech.cl',   22, 'inactivo');

SELECT 'Base de datos inicializada correctamente' AS mensaje;
