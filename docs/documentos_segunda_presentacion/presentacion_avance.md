# Documento Técnico — Proyecto Pegaso Airlines

### Grupo del Proyecto No. 6
### Sistemas de Bases de Datos — Fase Final

---

## 1. Nombre del Proyecto
**Pegaso Airlines — Sistema de Gestión de Reservas Aéreas**

## 2. Nombre de la Aplicación
**Pegaso** — Plataforma Integral de Gestión Aeronáutica

## 3. Objetivo General
Desarrollar un sistema integral de gestión de reservas aéreas que simule de manera realista las operaciones de una aerolínea ecuatoriana, abarcando el ciclo operativo completo y centralizando el control mediante una base de datos relacional.
*   **Problemática:** La industria aeronáutica requiere sistemas robustos para manejar grandes volúmenes de datos transaccionales con alta integridad, resolviendo problemas críticos de concurrencia y sobreventa (overbooking) mediante bloqueos por fila y procedimientos almacenados.
*   **Beneficios:** Proporciona una gestión eficiente de reservaciones con código PNR, control preciso de la capacidad de los vuelos, check-in digital interactivo sin duplicidad de asientos, auditoría estricta sin eliminación de registros críticos (soft-deletes) y trazabilidad bajo roles diferenciados.

## 4. Funcionalidades del Sistema
El sistema cubre las operaciones reales del negocio mediante las siguientes funcionalidades principales:
*   **Gestión de Reservaciones:** Búsqueda dinámica de vuelos, generación de código PNR único, autocompletado en tiempo real de datos de pasajeros frecuentes, selección de familias tarifarias, emisión de boletos electrónicos y cancelación mediante desactivación lógica.
*   **Check-in y Equipaje:** Búsqueda de reservas activas, validación de ventana de 48 horas para check-in, selección visual de asientos con bloqueo en tiempo real, registro de equipaje validando límites de peso y emisión de pases de abordar con código de barras.
*   **Gestión de Vuelos y Tripulación:** Programación de instancias de vuelo a partir de rutas maestras, control y transición de estados operativos, visualización del manifiesto completo de pasajeros y cálculo de estadísticas de ocupación.
*   **Administración:** Control de acceso y dashboards estadísticos diferenciados por roles, gestión del estado de la flota de aviones, registro de empleados y auditoría automática de las operaciones realizadas.

## 5. Modelo Físico del Sistema
El modelo físico se implementó en una base de datos MySQL relacional y transaccional conformada por **22 tablas** rigurosamente normalizadas.
*   **Scripts de Creación, Tablas y Relaciones:** El esquema incluye la creación de tablas organizadas en grupos funcionales, definiendo claves primarias y foráneas estructuradas con acciones referenciales como `ON UPDATE CASCADE` y `ON DELETE RESTRICT`.
*   **Restricciones y Valores por Defecto:** Se hace uso extensivo de restricciones `UNIQUE` (para evitar duplicidad de asientos o boletos), `CHECK` (para asegurar pesos y distancias mayores a cero) y dominios `ENUM` con valores por defecto para los estados operativos.
*   **Índices:** Se implementaron 10 índices optimizados (ej. `idx_vuelos_fecha_estado` y `idx_boletos_reservacion`) para agilizar el cruce de tablas en búsquedas recurrentes e historiales.
*   **Vistas:** Se desarrollaron 6 vistas de agregación (ej. `vw_itinerario_vuelos` y `vw_ocupacion_vuelos`) para el consumo eficiente de datos, el cálculo de asientos disponibles en tiempo real y la consolidación de ingresos.
*   **Triggers:** Se configuraron 6 disparadores para mantener la integridad operativa; incluyendo `trg_validar_capacidad_vuelo` para bloquear inserciones que excedan la sobreventa, `trg_validar_peso_equipaje` para aplicar normativas, y `trg_proteger_eliminacion_persona` para imponer el soft-delete.

## 6. Implementación Funcional (3 funcionalidades completas)
El frontend fue desarrollado bajo una arquitectura MVC empleando **Python (Flask)**, HTML5, CSS3 y JavaScript, garantizando que cada rol operativo vea únicamente la información pertinente. Se desarrollaron de forma completa las siguientes tres funcionalidades con operaciones CRUD:
*   **Gestión de Reservaciones (CRUD):** Permite buscar vuelos por origen y destino, crear reservaciones asignando el PNR, autocompletar la información del pasajero consultando la base de datos, emitir los boletos asociados y aplicar cancelaciones mediante eliminaciones lógicas.
*   **Check-in y Equipaje (CRUD):** Facilita la consulta del boleto, la inserción del pase de abordar seleccionando asientos en un mapa visual que previene colisiones concurrentes, y el registro o adición de equipaje asociado.
*   **Gestión de Vuelos y Tripulación (CRUD):** Estandariza la creación y programación de vuelos asociados a una ruta maestra, la asignación o remoción de tripulantes, y la modificación de los estados del vuelo (ej. de Programado a Cancelado).

## 7. Procedimientos Almacenados
Toda la lógica de negocio se centralizó a través de **7 procedimientos almacenados** bien estructurados, definiendo parámetros de entrada (`IN`) y salida (`OUT`), aplicando control transaccional (`START TRANSACTION` / `COMMIT` / `ROLLBACK`) y manejo de errores (`DECLARE EXIT HANDLER FOR SQLEXCEPTION`).
*   `sp_crear_reservacion`: Genera un PNR al azar, verifica su unicidad, gestiona la concurrencia e inserta una nueva reserva.
*   `sp_emitir_boleto`: Implementa bloqueos `SELECT ... FOR UPDATE` sobre la tabla de vuelos para evaluar la capacidad y el límite de sobreventa, impidiendo excesos en caso de transacciones masivas.
*   `sp_checkin_pasajero`: Bloquea los registros para garantizar que un asiento visualizado y seleccionado no sea tomado por dos usuarios simultáneamente.
*   `sp_registrar_equipaje`: Registra piezas de cabina o bodega validando que el peso se encuentre dentro de los límites de la familia tarifaria.
*   `sp_cancelar_reservacion`: Garantiza la cancelación en cascada de boletos asociados, aplicando actualizaciones masivas de estados (soft-delete).
*   `sp_cambiar_estado_vuelo`: Valida el flujo operativo y transiciona el estado de un vuelo (ej. a Embarque o Aterrizado).
*   `sp_asignar_tripulacion`: Asigna personal verificando la disponibilidad para las funciones operativas del vuelo.

## 8. Video de Demostración Funcional
> *[https://www.youtube.com/watch?v=PZ2f5dkD9Po]*
