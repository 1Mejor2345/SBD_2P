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
INSERT INTO rutas (origen_iata, destino_iata, distancia_km, duracion_estimada_min) VALUES
('UIO', 'GYE', 280, 50),
('UIO', 'CUE', 310, 55),
('GYE', 'GPS', 1170, 110),
('UIO', 'MEC', 260, 45),
('UIO', 'BOG', 730, 90),
('UIO', 'LIM', 1330, 130),
('UIO', 'MIA', 2880, 240),
('GYE', 'BOG', 1000, 110),
('GYE', 'PTY', 1250, 120),
('UIO', 'MEX', 3160, 280),
('UIO', 'SCL', 3800, 310),
('UIO', 'GRU', 4320, 360),
('UIO', 'EZE', 4380, 360);

-- Roles
INSERT INTO roles (nombre, descripcion) VALUES
('Administrador', 'Acceso total al sistema'),
('Supervisor de Vuelos', 'Gestión de vuelos y personal'),
('Agente', 'Agente de check-in y ventas'),
('Pasajero', 'Cliente regular');

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
(2, 'agente', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 3); -- agente

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
INSERT INTO vuelos (numero_vuelo, ruta_id, avion_matricula, fecha_hora_salida, fecha_hora_llegada, puerta_embarque_id) VALUES
('PG101', 1, 'HC-CPA', '2026-08-01 10:00:00', '2026-08-01 10:50:00', 1),
('PG102', 1, 'HC-CPB', '2026-08-01 15:00:00', '2026-08-01 15:50:00', 2),
('PG201', 5, 'HC-CPC', '2026-08-02 08:00:00', '2026-08-02 09:30:00', 3),
('PG301', 7, 'HC-CPD', '2026-08-03 07:00:00', '2026-08-03 11:00:00', 4);

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
