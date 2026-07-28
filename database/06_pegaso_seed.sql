USE pegaso_airlines;

-- Paises
INSERT INTO paises (codigo_iso, nombre) VALUES
('EC', 'Ecuador'), ('CO', 'Colombia'), ('PE', 'Perú'), ('US', 'Estados Unidos'), 
('MX', 'México'), ('PA', 'Panamá'), ('BR', 'Brasil'), ('CL', 'Chile'), ('AR', 'Argentina');

-- Ciudades
INSERT INTO ciudades (nombre, pais_codigo) VALUES
('Quito', 'EC'), ('Guayaquil', 'EC'), ('Cuenca', 'EC'), ('Baltra', 'EC'), 
('Manta', 'EC'), ('Loja', 'EC'), ('Bogotá', 'CO'), ('Lima', 'PE'), 
('Miami', 'US'), ('Ciudad de México', 'MX'), ('Ciudad de Panamá', 'PA'), 
('São Paulo', 'BR'), ('Santiago', 'CL'), ('Buenos Aires', 'AR');

-- Aeropuertos
INSERT INTO aeropuertos (codigo_iata, nombre, ciudad_id, elevacion_ft) VALUES
('UIO', 'Mariscal Sucre International Airport', 1, 7910),
('GYE', 'José Joaquín de Olmedo International Airport', 2, 19),
('CUE', 'Mariscal Lamar International Airport', 3, 8306),
('GPS', 'Seymour Airport', 4, 207),
('MEC', 'Eloy Alfaro International Airport', 5, 48),
('LOH', 'Camilo Ponce Enríquez Airport', 6, 4055),
('BOG', 'El Dorado International Airport', 7, 8361),
('LIM', 'Jorge Chávez International Airport', 8, 113),
('MIA', 'Miami International Airport', 9, 8),
('MEX', 'Benito Juárez International Airport', 10, 7316),
('PTY', 'Tocumen International Airport', 11, 135),
('GRU', 'Guarulhos International Airport', 12, 2459),
('SCL', 'Arturo Merino Benítez International Airport', 13, 1555),
('EZE', 'Ministro Pistarini International Airport', 14, 66);

-- Puertas de embarque
INSERT INTO puertas_embarque (aeropuerto_iata, numero) VALUES
('UIO', 'A1'), ('UIO', 'A2'), ('UIO', 'B1'), ('UIO', 'B2'), ('UIO', 'C1'),
('GYE', '1'), ('GYE', '2'), ('GYE', '3'), ('GYE', '4'), ('GYE', '5');

-- Modelos de Avion
INSERT INTO modelos_avion (fabricante, modelo, capacidad_pasajeros, alcance_km) VALUES
('Airbus', 'A320', 180, 6100),
('Airbus', 'A319', 144, 6950),
('Boeing', '737-800', 189, 5436),
('Embraer', 'E190', 100, 4537);

-- Aviones
INSERT INTO aviones (matricula, modelo_id, anio_fabricacion, estado) VALUES
('HC-CPA', 1, 2015, 'OPERATIVO'),
('HC-CPB', 1, 2016, 'OPERATIVO'),
('HC-CPC', 2, 2012, 'OPERATIVO'),
('HC-CPD', 3, 2018, 'OPERATIVO'),
('HC-CPE', 4, 2010, 'OPERATIVO'),
('HC-CPF', 1, 2017, 'OPERATIVO'),
('HC-CPG', 2, 2014, 'OPERATIVO'),
('HC-CPH', 3, 2019, 'OPERATIVO');

-- Configuracion de Asientos (A320 - modelo 1)
-- Rows 1-3 Business, 4-12 Premium, 13-30 Economy
INSERT INTO configuracion_asientos (modelo_id, fila, columna, clase_servicio)
SELECT 1, f.fila, c.columna, 
       CASE 
           WHEN f.fila <= 3 THEN 'BUSINESS'
           WHEN f.fila <= 12 THEN 'PREMIUM_ECONOMY'
           ELSE 'ECONOMY'
       END
FROM 
    (SELECT 1 as fila UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
     UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
     UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
     UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION SELECT 25
     UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29 UNION SELECT 30) f
CROSS JOIN 
    (SELECT 'A' as columna UNION SELECT 'B' UNION SELECT 'C' 
     UNION SELECT 'D' UNION SELECT 'E' UNION SELECT 'F') c;

-- Rutas
INSERT INTO rutas (id, codigo_vuelo, origen_iata, destino_iata, hora_salida, distancia_km, duracion_estimada_min) VALUES
(1, 'PG101', 'UIO', 'GYE', '10:00:00', 280, 50),
(2, 'PG102', 'UIO', 'GYE', '15:00:00', 280, 50),
(3, 'PG103', 'UIO', 'CUE', '11:00:00', 310, 55),
(4, 'PG104', 'GYE', 'GPS', '09:00:00', 1170, 110),
(5, 'PG201', 'UIO', 'BOG', '08:00:00', 730, 90),
(6, 'PG301', 'UIO', 'MIA', '07:00:00', 2880, 240),
(7, 'PG105', 'UIO', 'GYE', '06:00:00', 280, 50),
(8, 'PG106', 'UIO', 'GYE', '19:00:00', 280, 50);

-- Roles
INSERT INTO roles (nombre, descripcion) VALUES
('Administrador', 'Acceso total al sistema'),
('Supervisor', 'Gestión de vuelos y personal'),
('Agente', 'Agente de check-in y ventas'),
('Viajero', 'Cliente final portal web');

-- Personas (Nombres Ecuatorianos)
INSERT INTO personas (tipo_documento, numero_documento, nombres, apellidos, email, nacionalidad, genero) VALUES
('CEDULA', '1712345678', 'Juan Carlos', 'Pérez Torres', 'juan@test.com', 'EC', 'M'),
('CEDULA', '0912345678', 'María Fernanda', 'Gómez Jaramillo', 'maria@test.com', 'EC', 'F'),
('PASAPORTE', 'A1234567', 'Carlos Luis', 'López Mora', 'carlos@test.com', 'EC', 'M'),
('CEDULA', '0102345678', 'Ana Belén', 'Salazar Cruz', 'ana@test.com', 'EC', 'F'),
('CEDULA', '1102345678', 'Luis Eduardo', 'Mendoza Viteri', 'luis@test.com', 'EC', 'M'),
('CEDULA', '1302345678', 'Pedro', 'Castro', 'pedro.c@test.com', 'EC', 'M'),
('CEDULA', '1702345678', 'Diana', 'Ruiz', 'diana.r@test.com', 'EC', 'F'),
('CEDULA', '1723456789', 'Andrea', 'Pazmino', 'andrea.p@test.com', 'EC', 'F');

-- Persona del usuario (José Paladines)
INSERT INTO personas (tipo_documento, numero_documento, nombres, apellidos, email, telefono, fecha_nacimiento, nacionalidad, genero) VALUES
('CEDULA', '0943969386', 'José', 'Paladines', 'josepala@espol.edu.ec', '+593969495722', '2007-10-06', 'EC', 'M');

-- Empleados
INSERT INTO empleados (persona_id, codigo_empleado, cargo, numero_licencia, fecha_contratacion, salario) VALUES
(1, 'EMP001', 'ADMINISTRADOR', NULL, '2020-01-15', 2500.00),
(2, 'EMP002', 'AGENTE_CHECKIN', NULL, '2021-03-10', 800.00),
(5, 'EMP003', 'PILOTO', 'LIC-PIL-001', '2015-06-20', 4500.00),
(6, 'EMP004', 'COPILOTO', 'LIC-COP-002', '2018-09-01', 3000.00),
(7, 'EMP005', 'SOBRECARGO', NULL, '2016-11-12', 1500.00),
(8, 'EMP006', 'SOBRECARGO', NULL, '2019-02-15', 1200.00);

-- Usuarios (hash sha256 para demostracion. Nota: flask usara bcrypt o werkzeug hash)
INSERT INTO usuarios (persona_id, username, hash_contrasena, rol_id) VALUES
(1, 'admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 1), -- admin
(2, 'agente', 'afb812d3ea7146079bebf27a371a3b30d695c8e7a5f532170fca6dc2068267ec', 3), -- agente
(7, 'supervisor', '0834c2d60725ac5902257b3b78dd161ad26d1c0290dbf1e47cc14add5b8c8142', 2), -- supervisor
(3, 'viajero', 'f32a42cd7d3c2ffcc000ac7bda94c85701bf7a204e1e2a9b6354ef81c2fa212f', 4); -- viajero

-- Clases
INSERT INTO clases_servicio (nombre, factor_precio) VALUES 
('Economy', 1.00), ('Premium Economy', 1.50), ('Business', 2.50), ('First', 4.00);

-- Familias
INSERT INTO familias_tarifa (nombre, incluye_equipaje_bodega, peso_equipaje_incluido_kg, incluye_seleccion_asiento, es_reembolsable, permite_cambios, prioridad_embarque) VALUES
('Light', FALSE, 0, FALSE, FALSE, FALSE, FALSE), 
('Standard', TRUE, 23, FALSE, FALSE, FALSE, FALSE),
('Full', TRUE, 46, TRUE, FALSE, TRUE, FALSE),
('Flex', TRUE, 64, TRUE, TRUE, TRUE, TRUE);

-- Vuelos
INSERT INTO vuelos (ruta_id, fecha_vuelo, avion_matricula, fecha_hora_salida, fecha_hora_llegada, puerta_embarque_id) VALUES
-- PG101 (Ruta 1) 10:00
(1, '2026-07-27', 'HC-CPA', '2026-07-27 10:00:00', '2026-07-27 10:50:00', 1),
(1, '2026-07-28', 'HC-CPA', '2026-07-28 10:00:00', '2026-07-28 10:50:00', 1),
(1, '2026-07-29', 'HC-CPA', '2026-07-29 10:00:00', '2026-07-29 10:50:00', 1),
(1, '2026-07-30', 'HC-CPA', '2026-07-30 10:00:00', '2026-07-30 10:50:00', 1),
(1, '2026-07-31', 'HC-CPA', '2026-07-31 10:00:00', '2026-07-31 10:50:00', 1),
(1, '2026-08-01', 'HC-CPA', '2026-08-01 10:00:00', '2026-08-01 10:50:00', 1),
(1, '2026-08-02', 'HC-CPA', '2026-08-02 10:00:00', '2026-08-02 10:50:00', 1),
(1, '2026-08-03', 'HC-CPA', '2026-08-03 10:00:00', '2026-08-03 10:50:00', 1),
(1, '2026-08-04', 'HC-CPA', '2026-08-04 10:00:00', '2026-08-04 10:50:00', 1),
(1, '2026-08-05', 'HC-CPA', '2026-08-05 10:00:00', '2026-08-05 10:50:00', 1),
(1, '2026-08-06', 'HC-CPA', '2026-08-06 10:00:00', '2026-08-06 10:50:00', 1),
(1, '2026-08-07', 'HC-CPA', '2026-08-07 10:00:00', '2026-08-07 10:50:00', 1),

-- PG102 (Ruta 2) 15:00
(2, '2026-07-27', 'HC-CPB', '2026-07-27 15:00:00', '2026-07-27 15:50:00', 2),
(2, '2026-07-28', 'HC-CPB', '2026-07-28 15:00:00', '2026-07-28 15:50:00', 2),
(2, '2026-07-29', 'HC-CPB', '2026-07-29 15:00:00', '2026-07-29 15:50:00', 2),
(2, '2026-07-30', 'HC-CPB', '2026-07-30 15:00:00', '2026-07-30 15:50:00', 2),
(2, '2026-07-31', 'HC-CPB', '2026-07-31 15:00:00', '2026-07-31 15:50:00', 2),
(2, '2026-08-01', 'HC-CPB', '2026-08-01 15:00:00', '2026-08-01 15:50:00', 2),
(2, '2026-08-02', 'HC-CPB', '2026-08-02 15:00:00', '2026-08-02 15:50:00', 2),
(2, '2026-08-03', 'HC-CPB', '2026-08-03 15:00:00', '2026-08-03 15:50:00', 2),
(2, '2026-08-04', 'HC-CPB', '2026-08-04 15:00:00', '2026-08-04 15:50:00', 2),
(2, '2026-08-05', 'HC-CPB', '2026-08-05 15:00:00', '2026-08-05 15:50:00', 2),
(2, '2026-08-06', 'HC-CPB', '2026-08-06 15:00:00', '2026-08-06 15:50:00', 2),
(2, '2026-08-07', 'HC-CPB', '2026-08-07 15:00:00', '2026-08-07 15:50:00', 2),

-- PG105 (Ruta 7) 06:00
(7, '2026-07-27', 'HC-CPF', '2026-07-27 06:00:00', '2026-07-27 06:50:00', 3),
(7, '2026-07-28', 'HC-CPF', '2026-07-28 06:00:00', '2026-07-28 06:50:00', 3),
(7, '2026-07-29', 'HC-CPF', '2026-07-29 06:00:00', '2026-07-29 06:50:00', 3),
(7, '2026-07-30', 'HC-CPF', '2026-07-30 06:00:00', '2026-07-30 06:50:00', 3),
(7, '2026-07-31', 'HC-CPF', '2026-07-31 06:00:00', '2026-07-31 06:50:00', 3),
(7, '2026-08-01', 'HC-CPF', '2026-08-01 06:00:00', '2026-08-01 06:50:00', 3),
(7, '2026-08-02', 'HC-CPF', '2026-08-02 06:00:00', '2026-08-02 06:50:00', 3),
(7, '2026-08-03', 'HC-CPF', '2026-08-03 06:00:00', '2026-08-03 06:50:00', 3),
(7, '2026-08-04', 'HC-CPF', '2026-08-04 06:00:00', '2026-08-04 06:50:00', 3),
(7, '2026-08-05', 'HC-CPF', '2026-08-05 06:00:00', '2026-08-05 06:50:00', 3),
(7, '2026-08-06', 'HC-CPF', '2026-08-06 06:00:00', '2026-08-06 06:50:00', 3),
(7, '2026-08-07', 'HC-CPF', '2026-08-07 06:00:00', '2026-08-07 06:50:00', 3),

-- PG106 (Ruta 8) 19:00
(8, '2026-07-27', 'HC-CPG', '2026-07-27 19:00:00', '2026-07-27 19:50:00', 4),
(8, '2026-07-28', 'HC-CPG', '2026-07-28 19:00:00', '2026-07-28 19:50:00', 4),
(8, '2026-07-29', 'HC-CPG', '2026-07-29 19:00:00', '2026-07-29 19:50:00', 4),
(8, '2026-07-30', 'HC-CPG', '2026-07-30 19:00:00', '2026-07-30 19:50:00', 4),
(8, '2026-07-31', 'HC-CPG', '2026-07-31 19:00:00', '2026-07-31 19:50:00', 4),
(8, '2026-08-01', 'HC-CPG', '2026-08-01 19:00:00', '2026-08-01 19:50:00', 4),
(8, '2026-08-02', 'HC-CPG', '2026-08-02 19:00:00', '2026-08-02 19:50:00', 4),
(8, '2026-08-03', 'HC-CPG', '2026-08-03 19:00:00', '2026-08-03 19:50:00', 4),
(8, '2026-08-04', 'HC-CPG', '2026-08-04 19:00:00', '2026-08-04 19:50:00', 4),
(8, '2026-08-05', 'HC-CPG', '2026-08-05 19:00:00', '2026-08-05 19:50:00', 4),
(8, '2026-08-06', 'HC-CPG', '2026-08-06 19:00:00', '2026-08-06 19:50:00', 4),
(8, '2026-08-07', 'HC-CPG', '2026-08-07 19:00:00', '2026-08-07 19:50:00', 4),

-- Otros vuelos base
(5, '2026-08-02', 'HC-CPC', '2026-08-02 08:00:00', '2026-08-02 09:30:00', 3),
(6, '2026-08-03', 'HC-CPD', '2026-08-03 07:00:00', '2026-08-03 11:00:00', 4);

-- Tripulacion Vuelo PG101
INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, funcion) VALUES
(1, 5, 'COMANDANTE'),
(1, 6, 'PRIMER_OFICIAL'),
(1, 7, 'SOBRECARGO_JEFE'),
(1, 8, 'SOBRECARGO');

-- Reservacion
INSERT INTO reservaciones (codigo_pnr, contacto_email, contacto_telefono, usuario_creador_id) VALUES
('ABC123', 'carlos@test.com', '0991234567', 2);

-- Boletos para reservación ABC123
INSERT INTO boletos (numero_boleto, reservacion_id, pasajero_id, vuelo_id, clase_servicio_id, familia_tarifa_id, precio) VALUES
('0011234567890', 1, 3, 1, 1, 2, 120.00),
('0011234567891', 1, 4, 1, 1, 2, 120.00);
