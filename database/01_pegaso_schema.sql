DROP DATABASE IF EXISTS pegaso_airlines;
CREATE DATABASE pegaso_airlines CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pegaso_airlines;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. paises
CREATE TABLE paises (
    codigo_iso CHAR(2) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- 2. ciudades
CREATE TABLE ciudades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    pais_codigo CHAR(2),
    CONSTRAINT fk_ciudades_paises FOREIGN KEY (pais_codigo) REFERENCES paises(codigo_iso) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 3. aeropuertos
CREATE TABLE aeropuertos (
    codigo_iata CHAR(3) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    ciudad_id INT,
    elevacion_ft INT DEFAULT 0,
    CONSTRAINT fk_aeropuertos_ciudades FOREIGN KEY (ciudad_id) REFERENCES ciudades(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 4. puertas_embarque
CREATE TABLE puertas_embarque (
    id INT AUTO_INCREMENT PRIMARY KEY,
    aeropuerto_iata CHAR(3),
    numero VARCHAR(10) NOT NULL,
    estado ENUM('DISPONIBLE','OCUPADA','MANTENIMIENTO') DEFAULT 'DISPONIBLE',
    CONSTRAINT uq_puertas_aeropuerto UNIQUE (aeropuerto_iata, numero),
    CONSTRAINT fk_puertas_aeropuerto FOREIGN KEY (aeropuerto_iata) REFERENCES aeropuertos(codigo_iata) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 5. modelos_avion
CREATE TABLE modelos_avion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fabricante VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    capacidad_pasajeros SMALLINT NOT NULL CHECK (capacidad_pasajeros > 0),
    alcance_km INT NOT NULL,
    CONSTRAINT uq_modelos_fabricante UNIQUE (fabricante, modelo)
) ENGINE=InnoDB;

-- 6. aviones
CREATE TABLE aviones (
    matricula VARCHAR(10) PRIMARY KEY,
    modelo_id INT,
    anio_fabricacion YEAR NOT NULL,
    estado ENUM('OPERATIVO','EN_MANTENIMIENTO','RETIRADO') DEFAULT 'OPERATIVO',
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_aviones_modelo FOREIGN KEY (modelo_id) REFERENCES modelos_avion(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 7. configuracion_asientos
CREATE TABLE configuracion_asientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    modelo_id INT,
    fila SMALLINT NOT NULL,
    columna CHAR(1) NOT NULL,
    clase_servicio ENUM('ECONOMY','PREMIUM_ECONOMY','BUSINESS','FIRST') DEFAULT 'ECONOMY',
    es_salida_emergencia BOOLEAN DEFAULT FALSE,
    CONSTRAINT uq_config_asientos UNIQUE (modelo_id, fila, columna),
    CONSTRAINT fk_config_modelo FOREIGN KEY (modelo_id) REFERENCES modelos_avion(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 8. rutas
CREATE TABLE rutas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    origen_iata CHAR(3),
    destino_iata CHAR(3),
    distancia_km INT NOT NULL CHECK (distancia_km > 0),
    duracion_estimada_min INT NOT NULL CHECK (duracion_estimada_min > 0),
    esta_activa BOOLEAN DEFAULT TRUE,
    CONSTRAINT uq_rutas UNIQUE (origen_iata, destino_iata),
    CONSTRAINT fk_rutas_origen FOREIGN KEY (origen_iata) REFERENCES aeropuertos(codigo_iata) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_rutas_destino FOREIGN KEY (destino_iata) REFERENCES aeropuertos(codigo_iata) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 9. roles
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200)
) ENGINE=InnoDB;

-- 10. personas
CREATE TABLE personas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_documento ENUM('CEDULA','PASAPORTE','RUC') NOT NULL,
    numero_documento VARCHAR(20) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    nacionalidad CHAR(2),
    genero ENUM('M','F','OTRO'),
    esta_activo BOOLEAN DEFAULT TRUE,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_personas_doc UNIQUE (tipo_documento, numero_documento, nacionalidad),
    CONSTRAINT fk_personas_nacionalidad FOREIGN KEY (nacionalidad) REFERENCES paises(codigo_iso) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 11. empleados
CREATE TABLE empleados (
    persona_id INT PRIMARY KEY,
    codigo_empleado VARCHAR(10) NOT NULL UNIQUE,
    cargo ENUM('PILOTO','COPILOTO','SOBRECARGO','AGENTE_CHECKIN','AGENTE_PUERTA','SUPERVISOR_VUELOS','ADMINISTRADOR') NOT NULL,
    numero_licencia VARCHAR(30) UNIQUE,
    fecha_contratacion DATE NOT NULL,
    salario DECIMAL(10,2) CHECK (salario >= 0),
    esta_activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_empleados_persona FOREIGN KEY (persona_id) REFERENCES personas(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 12. usuarios
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    persona_id INT UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    hash_contrasena VARCHAR(255) NOT NULL,
    rol_id INT,
    esta_activo BOOLEAN DEFAULT TRUE,
    ultimo_acceso DATETIME,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_persona FOREIGN KEY (persona_id) REFERENCES personas(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_usuarios_rol FOREIGN KEY (rol_id) REFERENCES roles(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 13. clases_servicio
CREATE TABLE clases_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    factor_precio DECIMAL(4,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB;

-- 14. familias_tarifa
CREATE TABLE familias_tarifa (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    incluye_equipaje_bodega BOOLEAN DEFAULT FALSE,
    peso_equipaje_incluido_kg DECIMAL(5,2) DEFAULT 0,
    incluye_seleccion_asiento BOOLEAN DEFAULT FALSE,
    es_reembolsable BOOLEAN DEFAULT FALSE,
    permite_cambios BOOLEAN DEFAULT FALSE,
    prioridad_embarque BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB;

-- 15. vuelos
CREATE TABLE vuelos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_vuelo VARCHAR(10) NOT NULL,
    ruta_id INT,
    avion_matricula VARCHAR(10),
    fecha_hora_salida DATETIME NOT NULL,
    fecha_hora_llegada DATETIME NOT NULL,
    estado ENUM('PROGRAMADO','EMBARQUE','EN_VUELO','ATERRIZADO','ARRIBADO','CANCELADO','RETRASADO') DEFAULT 'PROGRAMADO',
    puerta_embarque_id INT,
    limite_sobreventa SMALLINT DEFAULT 0,
    observaciones TEXT,
    CONSTRAINT ck_fechas_vuelo CHECK (fecha_hora_llegada > fecha_hora_salida),
    CONSTRAINT fk_vuelos_ruta FOREIGN KEY (ruta_id) REFERENCES rutas(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_vuelos_avion FOREIGN KEY (avion_matricula) REFERENCES aviones(matricula) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_vuelos_puerta FOREIGN KEY (puerta_embarque_id) REFERENCES puertas_embarque(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 16. tripulacion_vuelo
CREATE TABLE tripulacion_vuelo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vuelo_id INT,
    empleado_id INT,
    funcion ENUM('COMANDANTE','PRIMER_OFICIAL','SOBRECARGO_JEFE','SOBRECARGO') NOT NULL,
    CONSTRAINT uq_tripulacion UNIQUE (vuelo_id, empleado_id),
    CONSTRAINT fk_tripulacion_vuelo FOREIGN KEY (vuelo_id) REFERENCES vuelos(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tripulacion_empleado FOREIGN KEY (empleado_id) REFERENCES empleados(persona_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 17. reservaciones
CREATE TABLE reservaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_pnr CHAR(6) NOT NULL UNIQUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('CONFIRMADA','PENDIENTE','CANCELADA','COMPLETADA') DEFAULT 'PENDIENTE',
    contacto_email VARCHAR(150) NOT NULL,
    contacto_telefono VARCHAR(20) NOT NULL,
    usuario_creador_id INT,
    observaciones TEXT,
    CONSTRAINT fk_reservaciones_usuario FOREIGN KEY (usuario_creador_id) REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 18. boletos
CREATE TABLE boletos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_boleto CHAR(13) NOT NULL UNIQUE,
    reservacion_id INT,
    pasajero_id INT,
    vuelo_id INT,
    clase_servicio_id INT,
    familia_tarifa_id INT,
    numero_asiento VARCHAR(4),
    precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    estado ENUM('EMITIDO','CHECKIN','ABORDADO','COMPLETADO','CANCELADO','NO_SHOW') DEFAULT 'EMITIDO',
    fecha_emision DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_boletos_vuelo_asiento UNIQUE (vuelo_id, numero_asiento),
    CONSTRAINT fk_boletos_reservacion FOREIGN KEY (reservacion_id) REFERENCES reservaciones(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_boletos_pasajero FOREIGN KEY (pasajero_id) REFERENCES personas(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_boletos_vuelo FOREIGN KEY (vuelo_id) REFERENCES vuelos(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_boletos_clase FOREIGN KEY (clase_servicio_id) REFERENCES clases_servicio(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_boletos_tarifa FOREIGN KEY (familia_tarifa_id) REFERENCES familias_tarifa(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 19. asientos_vuelo
CREATE TABLE asientos_vuelo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vuelo_id INT,
    configuracion_asiento_id INT,
    boleto_id INT,
    estado ENUM('DISPONIBLE','OCUPADO','BLOQUEADO') DEFAULT 'DISPONIBLE',
    CONSTRAINT uq_asientos_vuelo UNIQUE (vuelo_id, configuracion_asiento_id),
    CONSTRAINT fk_asientos_vuelo FOREIGN KEY (vuelo_id) REFERENCES vuelos(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_asientos_config FOREIGN KEY (configuracion_asiento_id) REFERENCES configuracion_asientos(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_asientos_boleto FOREIGN KEY (boleto_id) REFERENCES boletos(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- 20. equipajes
CREATE TABLE equipajes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    boleto_id INT,
    numero_tag CHAR(10) NOT NULL UNIQUE,
    peso_kg DECIMAL(5,2) NOT NULL CHECK (peso_kg > 0),
    tipo ENUM('CABINA','BODEGA') DEFAULT 'BODEGA',
    estado_tracking ENUM('REGISTRADO','CARGADO','EN_TRANSITO','ENTREGADO','EXTRAVIADO') DEFAULT 'REGISTRADO',
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_equipajes_boleto FOREIGN KEY (boleto_id) REFERENCES boletos(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 21. pases_abordar
CREATE TABLE pases_abordar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    boleto_id INT UNIQUE,
    asiento_vuelo_id INT,
    hora_emision DATETIME DEFAULT CURRENT_TIMESTAMP,
    codigo_barras VARCHAR(50) NOT NULL UNIQUE,
    secuencia_embarque SMALLINT,
    puerta VARCHAR(10),
    CONSTRAINT fk_pases_boleto FOREIGN KEY (boleto_id) REFERENCES boletos(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pases_asiento FOREIGN KEY (asiento_vuelo_id) REFERENCES asientos_vuelo(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 22. auditoria
CREATE TABLE auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tabla_afectada VARCHAR(50) NOT NULL,
    registro_id INT NOT NULL,
    accion ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    datos_anteriores JSON,
    datos_nuevos JSON,
    usuario VARCHAR(50),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
