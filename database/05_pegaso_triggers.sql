USE pegaso_airlines;

DELIMITER //

-- 1. trg_auditoria_reservacion_insert
CREATE TRIGGER trg_auditoria_reservacion_insert
AFTER INSERT ON reservaciones
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla_afectada, registro_id, accion, datos_nuevos, usuario)
    VALUES ('reservaciones', NEW.id, 'INSERT', JSON_OBJECT('codigo_pnr', NEW.codigo_pnr, 'estado', NEW.estado), CURRENT_USER());
END //

-- 2. trg_auditoria_reservacion_update
CREATE TRIGGER trg_auditoria_reservacion_update
AFTER UPDATE ON reservaciones
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla_afectada, registro_id, accion, datos_anteriores, datos_nuevos, usuario)
    VALUES ('reservaciones', NEW.id, 'UPDATE', 
            JSON_OBJECT('estado', OLD.estado), 
            JSON_OBJECT('estado', NEW.estado, 'contacto_email', NEW.contacto_email, 'contacto_telefono', NEW.contacto_telefono), 
            CURRENT_USER());
END //

-- 3. trg_validar_capacidad_vuelo
CREATE TRIGGER trg_validar_capacidad_vuelo
BEFORE INSERT ON boletos
FOR EACH ROW
BEGIN
    DECLARE v_capacidad INT;
    DECLARE v_sobreventa INT;
    DECLARE v_vendidos INT;
    
    SELECT m.capacidad_pasajeros, v.limite_sobreventa 
    INTO v_capacidad, v_sobreventa
    FROM vuelos v
    JOIN aviones a ON v.avion_matricula = a.matricula
    JOIN modelos_avion m ON a.modelo_id = m.id
    WHERE v.id = NEW.vuelo_id;
    
    SELECT COUNT(*) INTO v_vendidos FROM boletos WHERE vuelo_id = NEW.vuelo_id AND estado NOT IN ('CANCELADO');
    
    IF v_vendidos >= (v_capacidad + v_sobreventa) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacidad máxima del vuelo excedida.';
    END IF;
END //

-- 4. trg_auditoria_boleto_update
CREATE TRIGGER trg_auditoria_boleto_update
AFTER UPDATE ON boletos
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado THEN
        INSERT INTO auditoria (tabla_afectada, registro_id, accion, datos_anteriores, datos_nuevos, usuario)
        VALUES ('boletos', NEW.id, 'UPDATE', 
                JSON_OBJECT('estado', OLD.estado), 
                JSON_OBJECT('estado', NEW.estado), 
                CURRENT_USER());
    END IF;
END //

-- 5. trg_validar_peso_equipaje
CREATE TRIGGER trg_validar_peso_equipaje
BEFORE INSERT ON equipajes
FOR EACH ROW
BEGIN
    IF NEW.peso_kg <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El peso del equipaje debe ser mayor a 0.';
    END IF;
    
    IF NEW.tipo = 'BODEGA' AND NEW.peso_kg > 50 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El peso máximo para bodega es de 50kg.';
    END IF;
    
    IF NEW.tipo = 'CABINA' AND NEW.peso_kg > 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El peso máximo para cabina es de 10kg.';
    END IF;
END //

-- 6. trg_proteger_eliminacion_persona
CREATE TRIGGER trg_proteger_eliminacion_persona
BEFORE DELETE ON personas
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite la eliminación física de personas. Use desactivación (esta_activo = FALSE)';
END //

-- 7. trg_generar_asientos_vuelo
CREATE TRIGGER trg_generar_asientos_vuelo
AFTER INSERT ON vuelos
FOR EACH ROW
BEGIN
    INSERT INTO asientos_vuelo (vuelo_id, configuracion_asiento_id, estado)
    SELECT NEW.id, c.id, 'DISPONIBLE'
    FROM aviones a
    JOIN configuracion_asientos c ON a.modelo_id = c.modelo_id
    WHERE a.matricula = NEW.avion_matricula;
END //

DELIMITER ;
