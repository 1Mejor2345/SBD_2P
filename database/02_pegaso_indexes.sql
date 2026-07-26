USE pegaso_airlines;

-- Índice para búsqueda de vuelos por fecha y estado (muy común en el buscador de la web)
-- La fecha va primero porque la búsqueda de rango suele filtrar más, seguido del estado del vuelo.
CREATE INDEX idx_vuelos_fecha_estado ON vuelos(fecha_hora_salida, estado);

-- Índice para buscar los boletos por reservación (usado cuando el cliente busca su PNR)
CREATE INDEX idx_boletos_reservacion ON boletos(reservacion_id);

-- Índice para conteo rápido de capacidad y asientos vendidos (agrupando por vuelo y filtrando cancelados)
CREATE INDEX idx_boletos_vuelo_estado ON boletos(vuelo_id, estado);

-- Índice para historial de viajes por pasajero
CREATE INDEX idx_boletos_pasajero ON boletos(pasajero_id);

-- Índice compuesto para búsqueda de personas por su documento
CREATE INDEX idx_personas_documento ON personas(tipo_documento, numero_documento);

-- Índice para búsqueda principal de PNR (Booking)
CREATE INDEX idx_reservaciones_pnr ON reservaciones(codigo_pnr);

-- Índice para buscar equipajes de un pasajero en base a su boleto
CREATE INDEX idx_equipajes_boleto ON equipajes(boleto_id);

-- Índice para revisar si un empleado ya está asignado a un vuelo (evita cruces)
CREATE INDEX idx_tripulacion_vuelo ON tripulacion_vuelo(vuelo_id, empleado_id);

-- Índice para estadísticas y reportes por ruta
CREATE INDEX idx_vuelos_ruta ON vuelos(ruta_id);

-- Índice para búsquedas en auditoría por tabla y fecha, facilitando reportes de cambios recientes
CREATE INDEX idx_auditoria_tabla_fecha ON auditoria(tabla_afectada, fecha);
