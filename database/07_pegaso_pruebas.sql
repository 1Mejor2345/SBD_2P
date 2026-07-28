USE pegaso_airlines;

-- ==============================================================================
-- SCRIPT 07: PRUEBAS PARA LA PRESENTACIÓN EN VIVO (DEMOSTRACIÓN BACKEND)
-- ==============================================================================
-- Instrucciones: Ejecute estas consultas una por una DURANTE la presentación
-- para demostrarle a la profesora que los cambios del Frontend (Web) 
-- impactan directamente y de manera correcta en el Backend (Base de Datos).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PRUEBA 1: DEMOSTRAR "RUTA VS VUELO"
-- ------------------------------------------------------------------------------
-- 1A. Mostrar que la RUTA es maestra y estática (Ejemplo: PG101 siempre sale a las 10:00)
SELECT id AS ruta_id, codigo_vuelo, origen_iata, destino_iata, hora_salida 
FROM rutas 
WHERE codigo_vuelo = 'PG101';

-- 1B. Mostrar que los VUELOS son instancias de la ruta en diferentes días
-- (Demuestra exactamente lo que pidió la profesora en el audio)
SELECT v.id AS vuelo_id, r.codigo_vuelo AS ruta, v.fecha_vuelo, v.estado
FROM vuelos v
JOIN rutas r ON v.ruta_id = r.id
WHERE r.codigo_vuelo = 'PG101'
ORDER BY v.fecha_vuelo;


-- ------------------------------------------------------------------------------
-- PRUEBA 2: DEMOSTRAR CREACIÓN DE VUELO EN EL FRONTEND
-- ------------------------------------------------------------------------------
-- *ACCIÓN PREVIA EN LA WEB*: Ingrese como Administrador, vaya a "Vuelos" -> "+ Programar Vuelo".
-- Seleccione una ruta y programe el vuelo para un día lejano (ej. 15 de Octubre 2026).
-- Luego, ejecute la siguiente consulta en Workbench para verificar que se creó:

SELECT v.id, r.codigo_vuelo, v.fecha_vuelo, v.fecha_hora_salida, v.estado 
FROM vuelos v
JOIN rutas r ON v.ruta_id = r.id
WHERE v.fecha_vuelo >= '2026-10-01' -- Filtrar por el mes que acaban de crear
ORDER BY v.id DESC;


-- ------------------------------------------------------------------------------
-- PRUEBA 3: VERIFICACIÓN DEL AUTOCOMPLETADO DE PASAJERO (JOSÉ PALACIOS)
-- ------------------------------------------------------------------------------
-- Mostrar en la base de datos que la información de José existe previamente, 
-- lo que permite que el API la consulte al escribir la cédula en la web.
SELECT tipo_documento, numero_documento, nombres, apellidos, email, telefono, fecha_nacimiento 
FROM personas 
WHERE numero_documento = '0943969386';


-- ------------------------------------------------------------------------------
-- PRUEBA 4: DEMOSTRAR CREACIÓN DE RESERVACIÓN
-- ------------------------------------------------------------------------------
-- *ACCIÓN PREVIA EN LA WEB*: Ingrese a la web, busque un vuelo, seleccione una tarifa 
-- y complete una nueva reservación usando su cédula.
-- Luego, ejecute la siguiente consulta para ver el último PNR (reservación) generado:

SELECT id AS reservacion_id, codigo_pnr, fecha_creacion, contacto_email, estado 
FROM reservaciones 
ORDER BY id DESC LIMIT 1;

-- 4B. Verificar los boletos y precios asociados a la reservación anterior
SELECT b.numero_boleto, p.nombres, p.apellidos, cs.nombre AS clase, ft.nombre AS tarifa, b.precio, b.estado
FROM boletos b
JOIN personas p ON b.pasajero_id = p.id
JOIN clases_servicio cs ON b.clase_servicio_id = cs.id
JOIN familias_tarifa ft ON b.familia_tarifa_id = ft.id
WHERE b.reservacion_id = (SELECT MAX(id) FROM reservaciones);
