# Documento Técnico Fase Final – Proyecto Pegaso

## 1. Nombre del Proyecto y Aplicación
**Nombre del Proyecto:** Proyecto Pegaso: Velocidad y Confianza en la Aviación.
**Aplicación:** Sistema Integral de Gestión Aeronáutica Pegaso Airlines.

## 2. Objetivo General
Diseñar y desarrollar un sistema integral y robusto apoyado en una base de datos relacional transaccional (MySQL), que centralice, controle y valide las transacciones operativas de la aerolínea Pegaso. El sistema busca resolver problemas críticos de concurrencia y sobreventa mediante el uso de procedimientos almacenados, bloqueos por fila (FOR UPDATE) y triggers, garantizando la integridad de la información, el manejo correcto de auditorías y la gestión eficiente de reservaciones, vuelos y check-in a través de una interfaz gráfica (Frontend web).

## 3. Funcionalidades del Sistema
El sistema cubre el ciclo operativo completo de una aerolínea a través de las siguientes funcionalidades principales:
1. **Gestión de Reservaciones y Venta Comercial:** Búsqueda dinámica de vuelos disponibles y creación de reservas (códigos PNR) junto con la emisión concurrente de boletos.
2. **Check-in y Asignación de Asientos:** Mapa visual de asientos interactivo que permite la selección de lugares, validando la disponibilidad en tiempo real para evitar la duplicidad.
3. **Gestión Operativa de Vuelos:** Tablero de control (Dashboard) y herramientas para administradores y supervisores que permiten reprogramar, cancelar o cambiar el estado de los vuelos ('Programado', 'Embarque', 'Cancelado').
4. **Registro de Equipaje:** Asignación de equipaje de cabina o bodega validando pesos máximos permitidos por tarifa y emitiendo tags de rastreo.
5. **Auditoría e Integridad (Soft Deletes):** El sistema prohíbe la eliminación física de registros críticos, manejando desactivaciones lógicas y guardando un historial de acciones mediante triggers de auditoría.

## 4. Modelo Físico de Base de Datos
La base de datos MySQL `pegaso_airlines` consta de **22 tablas** rigurosamente normalizadas. El modelo físico incluye:
- **Claves Primarias y Foráneas:** Relaciones estructuradas con reglas `ON UPDATE CASCADE` y `ON DELETE RESTRICT` (o lógicas de cascada cuando es pertinente, como cancelar boletos si se cancela una reserva).
- **Restricciones (Constraints):** Uso extensivo de `UNIQUE` (ej. para evitar boletos con el mismo asiento), `CHECK` (ej. peso de equipaje > 0), y dominios restringidos por `ENUM` para los estados.
- **Motores e Índices:** Se utiliza `InnoDB` para soportar transacciones ACID. Se crearon 10 índices optimizados (ej. sobre PNR, estados de boletos, y fechas de vuelos) para agilizar las búsquedas recurrentes.

## 5. Implementación Funcional (Frontend)
El Frontend fue desarrollado bajo una arquitectura MVC empleando **Python (Flask)**, HTML5, CSS3, y JavaScript puro. El diseño es moderno (estilo *Glassmorphism* y *Dark Mode* adaptativo) y presenta 3 operaciones CRUD completamente operativas:
1. **CRUD Reservaciones:** Creación de pasajeros, generación de código PNR y emisión de boletos con cálculo de tarifas.
2. **CRUD Check-in:** Inserción de pases de abordar actualizando visualmente un mapa de asientos (HTML grid) y validando reglas de tiempo (>48 horas no permitido).
3. **CRUD Vuelos:** Visualización y actualización del estado de la flota, reflejando "eliminaciones lógicas" (cambiando estados a Cancelado) e impactando en cascada.

## 6. Video de Demostración Funcional
*El video muestra las 3 funcionalidades anteriores en acción desde el Frontend, seguidas inmediatamente de una consulta `SELECT` en MySQL Workbench para evidenciar que las transacciones y los bloqueos funcionaron correctamente en la base de datos subyacente.*
**[Pegar aquí el Enlace de YouTube / Drive del Video]**

## 7. Procedimientos Almacenados
El núcleo de la lógica de negocio se centralizó en la base de datos utilizando transacciones completas (`START TRANSACTION` / `COMMIT` / `ROLLBACK`) y manejo de errores (`DECLARE EXIT HANDLER FOR SQLEXCEPTION`):
- `sp_crear_reservacion`: Inserta una nueva reserva, genera el PNR al azar y gestiona concurrencia.
- `sp_emitir_boleto`: Implementa `SELECT ... FOR UPDATE` sobre la tabla de vuelos para evaluar el límite de sobreventa, impidiendo boletos excedentes en caso de concurrencia masiva.
- `sp_checkin_pasajero`: Bloquea los registros del asiento y boleto simultáneamente para garantizar que un asiento seleccionado no sea tomado por dos personas al mismo tiempo.
- `sp_cancelar_reservacion` y `sp_cambiar_estado_vuelo`: Garantizan cancelaciones en cascada y actualización masiva de estados lógicos.

## 8. Disparadores (Triggers)
Se implementaron 6 triggers para control y auditoría:
1. `trg_auditoria_reservacion_insert`: Graba automáticamente el usuario de BD y los datos nuevos al hacer un INSERT.
2. `trg_auditoria_reservacion_update` y `trg_auditoria_boleto_update`: Registran el estado anterior y el nuevo al modificarse, creando un historial completo.
3. `trg_validar_capacidad_vuelo`: Valida de forma estricta (BEFORE INSERT) si un nuevo boleto excede la capacidad del avión + sobreventa, enviando `SIGNAL SQLSTATE 45000` si hay violación.
4. `trg_validar_peso_equipaje`: Bloquea inserciones de equipaje de cabina > 10kg o bodega > 50kg.
5. `trg_proteger_eliminacion_persona`: Bloquea explícitamente cualquier `DELETE` físico sobre la tabla de personas (Soft-Delete policy).

## 9. Consultas SQL y Vistas
El sistema utiliza múltiples cruces complejos (`JOIN` de hasta 8 tablas) y subconsultas de agregación. Se crearon 6 vistas representativas para el consumo eficiente de datos:
1. `vw_itinerario_vuelos`: Detalla la información del vuelo calculando en tiempo real los asientos disponibles.
2. `vw_ocupacion_vuelos`: Calcula ingresos, pasajeros chequeados y porcentajes de ocupación por avión usando funciones de agregación.
3. `vw_manifiesto_pasajeros`: Unifica la información del vuelo, el pasajero, asiento, boleto y cantidad de equipajes para generar reportes en aeropuertos.
4. `vw_estadisticas_rutas`: Agrupa las rutas por popularidad y calcula ocupación e ingresos promedios.

## 10. Organización y Documentación del Proyecto
Los scripts SQL han sido modularizados y comentados siguiendo las mejores prácticas:
- `01_pegaso_schema.sql`: Creación de la estructura base.
- `02_pegaso_indexes.sql`: Implementación y justificación técnica de índices.
- `03_pegaso_views.sql`: Extracción consolidada de datos.
- `04_pegaso_procedures.sql`: Lógica de transacciones e inserciones.
- `05_pegaso_triggers.sql`: Validaciones y auditoría.
- `06_pegaso_seed.sql`: Data semilla coherente y funcional con la realidad Ecuatoriana e Internacional.
- El proyecto en general sigue un modelo estructurado en carpetas y respeta las normativas impuestas en las guías del proyecto.
