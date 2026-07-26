USE pegaso_airlines;

DELIMITER //

-- 1. sp_crear_reservacion
CREATE PROCEDURE sp_crear_reservacion(
    IN p_contacto_email VARCHAR(150),
    IN p_contacto_telefono VARCHAR(20),
    IN p_usuario_id INT,
    OUT p_codigo_pnr CHAR(6),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE v_pnr CHAR(6);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: No se pudo crear la reservación.';
    END;
    
    START TRANSACTION;
    
    IF p_contacto_email NOT LIKE '%_@__%.__%' THEN
        SET p_resultado = 'ERROR: Email inválido.';
        ROLLBACK;
    ELSE
        -- Generar PNR aleatorio
        SET v_pnr = SUBSTRING(MD5(RAND()), 1, 6);
        SET v_pnr = UPPER(v_pnr);
        
        INSERT INTO reservaciones (codigo_pnr, contacto_email, contacto_telefono, usuario_creador_id)
        VALUES (v_pnr, p_contacto_email, p_contacto_telefono, p_usuario_id);
        
        SET p_codigo_pnr = v_pnr;
        SET p_resultado = 'EXITO: Reservación creada.';
        COMMIT;
    END IF;
END //

-- 2. sp_emitir_boleto
CREATE PROCEDURE sp_emitir_boleto(
    IN p_reservacion_id INT,
    IN p_pasajero_id INT,
    IN p_vuelo_id INT,
    IN p_clase_servicio_id INT,
    IN p_familia_tarifa_id INT,
    IN p_precio DECIMAL(10,2),
    OUT p_numero_boleto CHAR(13),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE v_capacidad INT;
    DECLARE v_vendidos INT;
    DECLARE v_limite_sobreventa INT;
    DECLARE v_estado_vuelo VARCHAR(20);
    DECLARE v_boleto CHAR(13);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: No se pudo emitir el boleto.';
    END;
    
    START TRANSACTION;
    
    -- Lock el vuelo
    SELECT estado, limite_sobreventa INTO v_estado_vuelo, v_limite_sobreventa
    FROM vuelos WHERE id = p_vuelo_id FOR UPDATE;
    
    IF v_estado_vuelo != 'PROGRAMADO' THEN
        SET p_resultado = 'ERROR: El vuelo no está programado.';
        ROLLBACK;
    ELSE
        SELECT m.capacidad_pasajeros INTO v_capacidad
        FROM vuelos v
        JOIN aviones a ON v.avion_matricula = a.matricula
        JOIN modelos_avion m ON a.modelo_id = m.id
        WHERE v.id = p_vuelo_id;
        
        SELECT COUNT(*) INTO v_vendidos FROM boletos WHERE vuelo_id = p_vuelo_id AND estado NOT IN ('CANCELADO');
        
        IF (v_vendidos >= (v_capacidad + v_limite_sobreventa)) THEN
            SET p_resultado = 'ERROR: Capacidad máxima excedida.';
            ROLLBACK;
        ELSE
            -- Generar número de boleto simulado de 13 dígitos
            SET v_boleto = LPAD(FLOOR(RAND() * 9999999999999), 13, '0');
            
            INSERT INTO boletos (numero_boleto, reservacion_id, pasajero_id, vuelo_id, clase_servicio_id, familia_tarifa_id, precio)
            VALUES (v_boleto, p_reservacion_id, p_pasajero_id, p_vuelo_id, p_clase_servicio_id, p_familia_tarifa_id, p_precio);
            
            SET p_numero_boleto = v_boleto;
            SET p_resultado = 'EXITO: Boleto emitido.';
            COMMIT;
        END IF;
    END IF;
END //

-- 3. sp_checkin_pasajero
CREATE PROCEDURE sp_checkin_pasajero(
    IN p_boleto_id INT,
    IN p_asiento_vuelo_id INT,
    OUT p_codigo_barras VARCHAR(50),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE v_estado_boleto VARCHAR(20);
    DECLARE v_estado_asiento VARCHAR(20);
    DECLARE v_fecha_salida DATETIME;
    DECLARE v_asiento_nom VARCHAR(4);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: No se pudo realizar el check-in.';
    END;
    
    START TRANSACTION;
    
    SELECT b.estado, v.fecha_hora_salida INTO v_estado_boleto, v_fecha_salida
    FROM boletos b JOIN vuelos v ON b.vuelo_id = v.id
    WHERE b.id = p_boleto_id FOR UPDATE;
    
    SELECT estado INTO v_estado_asiento
    FROM asientos_vuelo WHERE id = p_asiento_vuelo_id FOR UPDATE;
    
    IF v_estado_boleto != 'EMITIDO' THEN
        SET p_resultado = 'ERROR: El boleto no está emitido.';
        ROLLBACK;
    ELSEIF TIMESTAMPDIFF(HOUR, NOW(), v_fecha_salida) > 48 THEN
        SET p_resultado = 'ERROR: Check-in no disponible aún (>48h).';
        ROLLBACK;
    ELSEIF v_estado_asiento != 'DISPONIBLE' THEN
        SET p_resultado = 'ERROR: El asiento no está disponible.';
        ROLLBACK;
    ELSE
        -- Obtener nombre de asiento
        SELECT CONCAT(c.fila, c.columna) INTO v_asiento_nom
        FROM asientos_vuelo av JOIN configuracion_asientos c ON av.configuracion_asiento_id = c.id
        WHERE av.id = p_asiento_vuelo_id;
        
        UPDATE boletos SET estado = 'CHECKIN', numero_asiento = v_asiento_nom WHERE id = p_boleto_id;
        UPDATE asientos_vuelo SET estado = 'OCUPADO', boleto_id = p_boleto_id WHERE id = p_asiento_vuelo_id;
        
        SET p_codigo_barras = UPPER(MD5(CONCAT(p_boleto_id, RAND())));
        
        INSERT INTO pases_abordar (boleto_id, asiento_vuelo_id, codigo_barras)
        VALUES (p_boleto_id, p_asiento_vuelo_id, p_codigo_barras);
        
        SET p_resultado = 'EXITO: Check-in realizado.';
        COMMIT;
    END IF;
END //

-- 4. sp_registrar_equipaje
CREATE PROCEDURE sp_registrar_equipaje(
    IN p_boleto_id INT,
    IN p_peso_kg DECIMAL(5,2),
    IN p_tipo ENUM('CABINA','BODEGA'),
    OUT p_numero_tag CHAR(10),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE v_estado VARCHAR(20);
    DECLARE v_peso_permitido DECIMAL(5,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: No se pudo registrar el equipaje.';
    END;
    
    START TRANSACTION;
    
    SELECT b.estado, f.peso_equipaje_incluido_kg INTO v_estado, v_peso_permitido
    FROM boletos b JOIN familias_tarifa f ON b.familia_tarifa_id = f.id
    WHERE b.id = p_boleto_id;
    
    IF v_estado IN ('CANCELADO', 'NO_SHOW') THEN
        SET p_resultado = 'ERROR: Boleto cancelado o pasajero no show.';
        ROLLBACK;
    ELSE
        SET p_numero_tag = CONCAT('PG', LPAD(FLOOR(RAND() * 99999999), 8, '0'));
        
        INSERT INTO equipajes (boleto_id, numero_tag, peso_kg, tipo)
        VALUES (p_boleto_id, p_numero_tag, p_peso_kg, p_tipo);
        
        SET p_resultado = 'EXITO: Equipaje registrado.';
        COMMIT;
    END IF;
END //

-- 5. sp_cancelar_reservacion
CREATE PROCEDURE sp_cancelar_reservacion(
    IN p_reservacion_id INT,
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE v_estado VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: No se pudo cancelar la reservación.';
    END;
    
    START TRANSACTION;
    
    SELECT estado INTO v_estado FROM reservaciones WHERE id = p_reservacion_id FOR UPDATE;
    
    IF v_estado = 'CANCELADA' THEN
        SET p_resultado = 'ERROR: La reservación ya está cancelada.';
        ROLLBACK;
    ELSE
        UPDATE boletos SET estado = 'CANCELADO' WHERE reservacion_id = p_reservacion_id;
        UPDATE asientos_vuelo SET estado = 'DISPONIBLE', boleto_id = NULL WHERE boleto_id IN (SELECT id FROM boletos WHERE reservacion_id = p_reservacion_id);
        UPDATE reservaciones SET estado = 'CANCELADA' WHERE id = p_reservacion_id;
        
        SET p_resultado = 'EXITO: Reservación cancelada.';
        COMMIT;
    END IF;
END //

-- 6. sp_cambiar_estado_vuelo
CREATE PROCEDURE sp_cambiar_estado_vuelo(
    IN p_vuelo_id INT,
    IN p_nuevo_estado ENUM('PROGRAMADO','EMBARQUE','EN_VUELO','ATERRIZADO','ARRIBADO','CANCELADO','RETRASADO'),
    IN p_observaciones TEXT,
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: No se pudo cambiar el estado del vuelo.';
    END;
    
    START TRANSACTION;
    
    UPDATE vuelos SET estado = p_nuevo_estado, observaciones = p_observaciones WHERE id = p_vuelo_id;
    
    IF p_nuevo_estado = 'CANCELADO' THEN
        UPDATE boletos SET estado = 'CANCELADO' WHERE vuelo_id = p_vuelo_id;
    END IF;
    
    SET p_resultado = 'EXITO: Estado del vuelo actualizado.';
    COMMIT;
END //

-- 7. sp_asignar_tripulacion
CREATE PROCEDURE sp_asignar_tripulacion(
    IN p_vuelo_id INT,
    IN p_empleado_id INT,
    IN p_funcion ENUM('COMANDANTE','PRIMER_OFICIAL','SOBRECARGO_JEFE','SOBRECARGO'),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE v_count INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: No se pudo asignar la tripulación.';
    END;
    
    START TRANSACTION;
    
    -- Validaciones omitidas por brevedad, pero en un entorno real habría cruces de horario
    SELECT COUNT(*) INTO v_count FROM tripulacion_vuelo WHERE vuelo_id = p_vuelo_id AND empleado_id = p_empleado_id;
    
    IF v_count > 0 THEN
        SET p_resultado = 'ERROR: Empleado ya asignado a este vuelo.';
        ROLLBACK;
    ELSE
        INSERT INTO tripulacion_vuelo (vuelo_id, empleado_id, funcion) VALUES (p_vuelo_id, p_empleado_id, p_funcion);
        SET p_resultado = 'EXITO: Empleado asignado al vuelo.';
        COMMIT;
    END IF;
END //

DELIMITER ;
