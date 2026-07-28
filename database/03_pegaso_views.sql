USE pegaso_airlines;

-- 1. vw_itinerario_vuelos
CREATE OR REPLACE VIEW vw_itinerario_vuelos AS
SELECT 
    v.id AS vuelo_id,
    r.codigo_vuelo AS numero_vuelo,
    co.nombre AS ciudad_origen,
    cd.nombre AS ciudad_destino,
    v.avion_matricula,
    v.fecha_hora_salida,
    v.fecha_hora_llegada,
    v.estado,
    pe.numero AS puerta_embarque,
    (m.capacidad_pasajeros + v.limite_sobreventa - (
        SELECT COUNT(*) FROM boletos b WHERE b.vuelo_id = v.id AND b.estado NOT IN ('CANCELADO', 'NO_SHOW')
    )) AS asientos_disponibles
FROM vuelos v
JOIN rutas r ON v.ruta_id = r.id
JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
JOIN ciudades co ON ao.ciudad_id = co.id
JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
JOIN ciudades cd ON ad.ciudad_id = cd.id
LEFT JOIN aviones a ON v.avion_matricula = a.matricula
LEFT JOIN modelos_avion m ON a.modelo_id = m.id
LEFT JOIN puertas_embarque pe ON v.puerta_embarque_id = pe.id;

-- 2. vw_manifiesto_pasajeros
CREATE OR REPLACE VIEW vw_manifiesto_pasajeros AS
SELECT 
    v.id AS vuelo_id,
    r.codigo_vuelo AS numero_vuelo,
    p.nombres,
    p.apellidos,
    p.tipo_documento,
    p.numero_documento,
    b.numero_boleto,
    b.numero_asiento,
    b.estado AS estado_boleto,
    (SELECT COUNT(*) FROM equipajes e WHERE e.boleto_id = b.id) AS cantidad_equipajes
FROM boletos b
JOIN vuelos v ON b.vuelo_id = v.id
JOIN rutas r ON v.ruta_id = r.id
JOIN personas p ON b.pasajero_id = p.id
WHERE b.estado NOT IN ('CANCELADO');

-- 3. vw_ocupacion_vuelos
CREATE OR REPLACE VIEW vw_ocupacion_vuelos AS
SELECT 
    v.id AS vuelo_id,
    r.codigo_vuelo AS numero_vuelo,
    m.capacidad_pasajeros AS capacidad_total,
    COUNT(b.id) AS boletos_vendidos,
    SUM(CASE WHEN b.estado IN ('CHECKIN','ABORDADO','COMPLETADO') THEN 1 ELSE 0 END) AS pasajeros_chequeados,
    ROUND((COUNT(b.id) / m.capacidad_pasajeros) * 100, 2) AS porcentaje_ocupacion,
    SUM(b.precio) AS ingresos_totales
FROM vuelos v
JOIN rutas r ON v.ruta_id = r.id
JOIN aviones a ON v.avion_matricula = a.matricula
JOIN modelos_avion m ON a.modelo_id = m.id
LEFT JOIN boletos b ON v.id = b.vuelo_id AND b.estado NOT IN ('CANCELADO', 'NO_SHOW')
GROUP BY v.id, r.codigo_vuelo, m.capacidad_pasajeros;

-- 4. vw_historial_reservaciones
CREATE OR REPLACE VIEW vw_historial_reservaciones AS
SELECT 
    r.id AS reservacion_id,
    r.codigo_pnr,
    r.fecha_creacion,
    r.estado AS estado_reservacion,
    p.nombres,
    p.apellidos,
    b.numero_boleto,
    ru.codigo_vuelo AS numero_vuelo,
    v.fecha_hora_salida,
    b.estado AS estado_boleto
FROM reservaciones r
JOIN boletos b ON r.id = b.reservacion_id
JOIN personas p ON b.pasajero_id = p.id
JOIN vuelos v ON b.vuelo_id = v.id
JOIN rutas ru ON v.ruta_id = ru.id;

-- 5. vw_disponibilidad_tripulacion
CREATE OR REPLACE VIEW vw_disponibilidad_tripulacion AS
SELECT 
    e.persona_id,
    p.nombres,
    p.apellidos,
    e.cargo,
    e.codigo_empleado
FROM empleados e
JOIN personas p ON e.persona_id = p.id
WHERE e.esta_activo = TRUE;

-- 6. vw_estadisticas_rutas
CREATE OR REPLACE VIEW vw_estadisticas_rutas AS
SELECT 
    r.id AS ruta_id,
    CONCAT(r.origen_iata, '-', r.destino_iata) AS ruta,
    COUNT(v.id) AS frecuencia_vuelos,
    ROUND(AVG((SELECT COUNT(*) FROM boletos b WHERE b.vuelo_id = v.id AND b.estado NOT IN ('CANCELADO')) / 
        (SELECT capacidad_pasajeros FROM modelos_avion m JOIN aviones a ON a.modelo_id = m.id WHERE a.matricula = v.avion_matricula) * 100), 2) AS ocupacion_promedio,
    SUM((SELECT SUM(precio) FROM boletos b WHERE b.vuelo_id = v.id AND b.estado NOT IN ('CANCELADO'))) AS ingresos_totales
FROM rutas r
LEFT JOIN vuelos v ON r.id = v.ruta_id
GROUP BY r.id, ruta;
