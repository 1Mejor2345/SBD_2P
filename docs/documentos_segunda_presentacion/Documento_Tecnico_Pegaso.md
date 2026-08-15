# Documento Técnico — Proyecto Pegaso Airlines
### Grupo del Proyecto No. 6
### Sistemas de Bases de Datos — Fase Final

---

## 1. Nombre del Proyecto

**Pegaso Airlines — Sistema de Gestión de Reservas Aéreas**

---

## 2. Nombre de la Aplicación

**Pegaso** — Plataforma Integral de Gestión Aeronáutica

---

## 3. Objetivo General

Desarrollar un sistema integral de gestión de reservas aéreas que simule de manera realista las operaciones de una aerolínea ecuatoriana, abarcando el ciclo completo desde la búsqueda de vuelos y creación de reservaciones (PNR), hasta el check-in de pasajeros, registro de equipaje y emisión de pases de abordar.

**Problemática que resuelve:** La industria aeronáutica requiere sistemas robustos que manejen grandes volúmenes de datos transaccionales con alta integridad referencial, soportando operaciones concurrentes como la emisión simultánea de boletos, el control de sobreventa (overbooking) como modelo de negocio, y la trazabilidad completa de pasajeros y equipaje según normativas internacionales de aviación civil (IATA).

**Beneficios del sistema:**
- Gestión eficiente de reservaciones con código PNR estándar de 6 caracteres
- Control preciso de la capacidad de vuelos incluyendo políticas de sobreventa
- Check-in digital con selección visual de asientos y generación de pases de abordar
- Registro y tracking de equipaje siguiendo estándares IATA (tags de 10 dígitos)
- Auditoría completa de operaciones (nunca se elimina información de pasajeros por regulaciones de seguridad aeroportuaria)
- Roles diferenciados que reflejan la operación real: Agentes de mostrador, Supervisores de vuelo, Administradores y Pasajeros

---

## 4. Funcionalidades del Sistema

### 4.1 Gestión de Reservaciones
| # | Funcionalidad | Descripción |
|---|---------------|-------------|
| F01 | Búsqueda de vuelos | Buscar vuelos por origen, destino, fecha y número de pasajeros |
| F02 | Creación de reservación (PNR) | Generar código PNR único de 6 caracteres alfanuméricos |
| F03 | Emisión de boletos electrónicos | Emitir e-tickets de 13 dígitos vinculados al PNR |
| F04 | Selección de tarifa | Elegir entre familias tarifarias: Light, Standard, Full, Flex |
| F05 | Registro de pasajeros | Capturar datos del pasajero (documento, nombres, contacto) |
| F06 | Consulta de reservaciones | Ver historial y detalle de reservaciones con estado |
| F07 | Cancelación de reservaciones | Cancelación con soft-delete (cambio de estado, no eliminación) |

### 4.2 Check-in y Equipaje
| # | Funcionalidad | Descripción |
|---|---------------|-------------|
| F08 | Búsqueda para check-in | Localizar reservación por PNR o apellido del pasajero |
| F09 | Proceso de check-in | Check-in con validación de ventana de 48 horas |
| F10 | Selección visual de asientos | Mapa interactivo del avión con asientos por clase |
| F11 | Registro de equipaje | Registrar maletas con tag IATA, peso y tipo (cabina/bodega) |
| F12 | Emisión de pase de abordar | Generar boarding pass con código de barras, puerta y secuencia |

### 4.3 Gestión de Vuelos y Tripulación
| # | Funcionalidad | Descripción |
|---|---------------|-------------|
| F13 | Programación de vuelos | Crear vuelos asignando ruta, avión, horarios y puerta |
| F14 | Control de estados de vuelo | Transicionar estados: Programado → Embarque → En vuelo → Aterrizado → Arribado |
| F15 | Asignación de tripulación | Asignar pilotos y sobrecargos validando disponibilidad |
| F16 | Manifiesto de pasajeros | Visualizar lista completa de pasajeros por vuelo |
| F17 | Estadísticas de ocupación | % ocupación, ingresos y disponibilidad por vuelo |

### 4.4 Administración
| # | Funcionalidad | Descripción |
|---|---------------|-------------|
| F18 | Gestión de flota | Alta, consulta y cambio de estado de aeronaves |
| F19 | Gestión de empleados | Registro de pilotos, sobrecargos y agentes |
| F20 | Dashboard por rol | Panel con estadísticas según el rol del usuario |
| F21 | Control de acceso | Autenticación con roles (Administrador, Supervisor, Agente) |
| F22 | Auditoría de operaciones | Registro automático de cambios en tablas críticas |

---

## 5. Modelo Físico del Sistema

### 5.1 Motor de Base de Datos
**MySQL 8.0+** con charset `utf8mb4` y collation `utf8mb4_unicode_ci`.

### 5.2 Diagrama de Tablas

El modelo físico consta de **22 tablas** organizadas en 5 grupos funcionales:

#### Infraestructura Aeroportuaria
- `paises` — Catálogo ISO de países
- `ciudades` — Ciudades con referencia a país
- `aeropuertos` — Aeropuertos con código IATA
- `puertas_embarque` — Gates por aeropuerto

#### Flota y Configuración
- `modelos_avion` — Catálogo de modelos (Airbus, Boeing, Embraer)
- `aviones` — Flota registrada con matrícula ecuatoriana (HC-)
- `configuracion_asientos` — Layout de asientos por modelo

#### Personas y Accesos
- `personas` — Supertipo con documento, contacto (nunca se elimina)
- `empleados` — Subtipo: pilotos, sobrecargos, agentes
- `roles` — Roles del sistema
- `usuarios` — Credenciales de acceso

#### Operaciones de Vuelo
- `rutas` — Pares origen-destino con distancia y duración
- `vuelos` — Instancias de vuelo con estado y sobreventa
- `tripulacion_vuelo` — Asignación tripulación-vuelo

#### Comercial y Servicio
- `clases_servicio` — Economy, Premium Economy, Business, First
- `familias_tarifa` — Light, Standard, Full, Flex
- `reservaciones` — PNR con código de 6 caracteres
- `boletos` — E-tickets de 13 dígitos
- `asientos_vuelo` — Mapa de asientos por vuelo
- `equipajes` — Maletas con tag IATA de 10 dígitos
- `pases_abordar` — Boarding passes con código de barras
- `auditoria` — Log de auditoría automático

### 5.3 Scripts de Creación

> Los scripts completos se encuentran en la carpeta `database/` del proyecto, organizados por categoría.

**Archivo:** `01_pegaso_schema.sql`
- Creación de la base de datos con charset utf8mb4
- 22 tablas con `PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, `UNIQUE`, `DEFAULT`
- Convenciones de nomenclatura: `fk_`, `uq_`, `ck_` para constraints
- Referential actions: `ON UPDATE CASCADE`, `ON DELETE RESTRICT`

**Relaciones principales:**
```
reservaciones 1──N boletos N──1 vuelos
                   │              │
                   │              ├──1 rutas (origen_iata ──1 aeropuertos)
                   │              │         (destino_iata ──1 aeropuertos)
                   │              │
                   │              ├──1 aviones ──1 modelos_avion
                   │              │                    │
                   │              │              configuracion_asientos
                   │              │
                   │              └──N tripulacion_vuelo ──1 empleados ──1 personas
                   │
                   ├──1 personas (pasajero, nunca se elimina)
                   │
                   ├──N equipajes (tag IATA 10 dígitos)
                   │
                   ├──1 asientos_vuelo ──1 configuracion_asientos
                   │
                   └──1 pases_abordar (código de barras único)
```

---

## 6. Implementación Funcional (Frontend)

### Tecnologías Utilizadas
- **Backend:** Python 3.11+ con Flask
- **Frontend:** HTML5, CSS3 (Vanilla), JavaScript ES6
- **Templating:** Jinja2 con herencia de templates
- **Conexión BD:** mysql-connector-python con pool de conexiones
- **Autenticación:** Sessions + werkzeug.security para hashing de contraseñas

### 6.1 Funcionalidad 1: Gestión de Reservaciones (CRUD Completo)

| Operación | Ruta | Acción |
|-----------|------|--------|
| **Create** | `POST /reservaciones/nueva` | Crea PNR via `sp_crear_reservacion`, emite boleto via `sp_emitir_boleto` |
| **Read** | `GET /reservaciones`, `GET /reservaciones/<id>` | Lista y detalle de reservaciones |
| **Update** | `POST /reservaciones/boleto/<id>` | Agregar pasajeros/boletos a la reservación |
| **Delete** | `POST /reservaciones/cancelar/<id>` | Cancelación via `sp_cancelar_reservacion` (soft-delete) |

### 6.2 Funcionalidad 2: Check-in y Equipaje (CRUD Completo)

| Operación | Ruta | Acción |
|-----------|------|--------|
| **Create** | `POST /checkin/proceso/<boleto_id>` | Check-in + asiento via `sp_checkin_pasajero`, pase de abordar |
| **Read** | `GET /checkin/buscar`, `GET /checkin/pase/<id>` | Buscar y ver pase de abordar |
| **Update** | `POST /checkin/equipaje/<boleto_id>` | Registrar equipaje via `sp_registrar_equipaje` |
| **Delete** | N/A | No se permite eliminar check-in (regulación de seguridad) |

### 6.3 Funcionalidad 3: Gestión de Vuelos y Tripulación (CRUD Completo)

| Operación | Ruta | Acción |
|-----------|------|--------|
| **Create** | `POST /vuelos/nuevo` | Programar nuevo vuelo con ruta y avión |
| **Read** | `GET /vuelos`, `GET /vuelos/<id>` | Lista y detalle con manifiesto |
| **Update** | `POST /vuelos/estado/<id>`, `POST /vuelos/tripulacion/<id>` | Cambiar estado, asignar crew |
| **Delete** | `POST /vuelos/tripulacion/eliminar` | Remover tripulante de vuelo |

---

## 7. Video del Front-end Funcional

> **[LINK DEL VIDEO PENDIENTE]**
>
> El video demuestra las 3 funcionalidades implementadas. Después de cada operación CRUD, se ejecuta una consulta `SELECT` directamente en MySQL Workbench para verificar que los datos se modificaron correctamente en las tablas relacionadas.

---

## 8. Procedimientos Almacenados

Se implementaron **7 procedimientos almacenados**, todos con:
- Parámetros de entrada (`IN`) y salida (`OUT`)
- Control transaccional (`START TRANSACTION` / `COMMIT` / `ROLLBACK`)
- Manejo de errores (`DECLARE EXIT HANDLER FOR SQLEXCEPTION`)
- Control de bloqueo (`SELECT ... FOR UPDATE`)

### SP1: `sp_crear_reservacion`
**Propósito:** Crear una nueva reservación con código PNR único de 6 caracteres.
- **Parámetros IN:** email de contacto, teléfono, ID usuario creador
- **Parámetros OUT:** código PNR generado, mensaje resultado
- **Validaciones:** Formato de email, campos obligatorios
- **Transaccionalidad:** Genera código PNR aleatorio, verifica unicidad, inserta registro

### SP2: `sp_emitir_boleto`
**Propósito:** Emitir boleto electrónico con número de 13 dígitos.
- **Parámetros IN:** reservación ID, pasajero ID, vuelo ID, clase servicio, familia tarifa, precio
- **Parámetros OUT:** número de boleto generado, mensaje resultado
- **Validaciones:** Capacidad del vuelo + límite de sobreventa (`SELECT ... FOR UPDATE`), pasajero activo, vuelo programado

### SP3: `sp_checkin_pasajero`
**Propósito:** Realizar check-in del pasajero con asignación de asiento.
- **Parámetros IN:** boleto ID, asiento vuelo ID
- **Parámetros OUT:** código de barras del pase, mensaje resultado
- **Validaciones:** Ventana de check-in (48 horas antes), estado del boleto, disponibilidad del asiento

### SP4: `sp_registrar_equipaje`
**Propósito:** Registrar pieza de equipaje con tag IATA.
- **Parámetros IN:** boleto ID, peso en kg, tipo (cabina/bodega)
- **Parámetros OUT:** número de tag generado, mensaje resultado
- **Validaciones:** Boleto existe, peso dentro de límites según familia tarifaria

### SP5: `sp_cancelar_reservacion`
**Propósito:** Cancelar reservación y todos sus boletos asociados (soft-delete).
- **Parámetros IN:** reservación ID
- **Parámetros OUT:** mensaje resultado

### SP6: `sp_cambiar_estado_vuelo`
**Propósito:** Transicionar el estado de un vuelo con validación de flujo.
- **Parámetros IN:** vuelo ID, nuevo estado, observaciones
- **Parámetros OUT:** mensaje resultado

### SP7: `sp_asignar_tripulacion`
**Propósito:** Asignar tripulante a un vuelo verificando disponibilidad.
- **Parámetros IN:** vuelo ID, empleado ID, función
- **Parámetros OUT:** mensaje resultado

---

## 9. Disparadores (Triggers)

Se implementaron **6 triggers** orientados a validación de estados, auditoría e integridad:

| # | Trigger | Evento | Acción | Justificación |
|---|---------|--------|--------|---------------|
| 1 | `trg_auditoria_reservacion_insert` | AFTER INSERT ON reservaciones | Registra en auditoria | Trazabilidad comercial |
| 2 | `trg_auditoria_reservacion_update` | AFTER UPDATE ON reservaciones | Registra cambios de estado | Cumplimiento regulatorio |
| 3 | `trg_validar_capacidad_vuelo` | BEFORE INSERT ON boletos | Valida capacidad + overbooking | Integridad del negocio |
| 4 | `trg_auditoria_boleto_update` | AFTER UPDATE ON boletos | Registra cambios de boleto | Ciclo de vida del ticket |
| 5 | `trg_validar_peso_equipaje` | BEFORE INSERT ON equipajes | Valida peso (≤50kg bodega, ≤10kg cabina) | Normativa IATA |
| 6 | `trg_proteger_eliminacion_persona` | BEFORE DELETE ON personas | SIGNAL error, impide DELETE | Seguridad aeroportuaria |

---

## 10. Consultas SQL y Vistas

### 10.1 Vistas Implementadas (6)

| # | Vista | Descripción | Índices que utiliza |
|---|-------|-------------|---------------------|
| 1 | `vw_itinerario_vuelos` | Vuelos con ruta, avión, asientos disponibles | idx_vuelos_fecha_estado, idx_vuelos_ruta |
| 2 | `vw_manifiesto_pasajeros` | Pasajeros por vuelo con check-in y equipaje | idx_boletos_vuelo_estado |
| 3 | `vw_ocupacion_vuelos` | % ocupación e ingresos por vuelo | idx_boletos_vuelo_estado |
| 4 | `vw_historial_reservaciones` | PNRs con boletos, pasajeros y vuelos | idx_boletos_reservacion, idx_reservaciones_pnr |
| 5 | `vw_disponibilidad_tripulacion` | Crew disponible por cargo | idx_tripulacion_vuelo |
| 6 | `vw_estadisticas_rutas` | Frecuencia y revenue por ruta | idx_vuelos_ruta |

### 10.2 Justificación de Índices

| Índice | Campos | Query que lo usa | Justificación del orden |
|--------|--------|------------------|------------------------|
| `idx_vuelos_fecha_estado` | (fecha_hora_salida, estado) | Búsqueda de vuelos disponibles | Fecha filtra rango, estado refina |
| `idx_boletos_reservacion` | (reservacion_id) | JOIN reservaciones→boletos | FK más consultada |
| `idx_boletos_vuelo_estado` | (vuelo_id, estado) | Conteo asientos vendidos | vuelo_id filtra, estado excluye cancelados |
| `idx_boletos_pasajero` | (pasajero_id) | Historial del pasajero | Búsqueda directa por FK |
| `idx_personas_documento` | (tipo_documento, numero_documento) | Búsqueda por documento | Tipo discrimina formato |
| `idx_reservaciones_pnr` | (codigo_pnr) | Check-in por PNR | Búsqueda directa |
| `idx_equipajes_boleto` | (boleto_id) | JOIN boleto→equipajes | FK para equipaje |
| `idx_tripulacion_vuelo` | (vuelo_id, empleado_id) | Verificar asignación crew | Compuesto para verificar existencia |
| `idx_vuelos_ruta` | (ruta_id) | Estadísticas por ruta | FK para agrupación |
| `idx_auditoria_tabla_fecha` | (tabla_afectada, fecha) | Consulta auditoría | Tabla filtra entidad, fecha rango |

---

## 11. Organización del Proyecto

### Estructura de Carpetas
```
pegaso/
├── database/
│   ├── 01_pegaso_schema.sql          -- DDL: Tablas, PKs, FKs, Constraints
│   ├── 02_pegaso_indexes.sql         -- Índices con justificación
│   ├── 03_pegaso_views.sql           -- 6 Vistas
│   ├── 04_pegaso_procedures.sql      -- 7 Stored Procedures
│   ├── 05_pegaso_triggers.sql        -- 6 Triggers
│   └── 06_pegaso_seed.sql            -- Datos iniciales (Ecuador)
├── templates/                         -- Plantillas Jinja2
├── static/css/style.css              -- Diseño CSS
├── static/js/app.js                  -- JavaScript
├── app.py                            -- Flask principal
├── requirements.txt                  -- Dependencias
└── .env                              -- Configuración MySQL
```

### Convenciones de Nomenclatura
| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Tablas | snake_case plural | `reservaciones` |
| PKs | `id` o natural key | `codigo_iata` |
| FKs | `fk_tabla_ref` | `fk_vuelos_rutas` |
| Índices | `idx_tabla_campos` | `idx_vuelos_fecha_estado` |
| SPs | `sp_accion` | `sp_crear_reservacion` |
| Triggers | `trg_accion_tabla` | `trg_auditoria_reservacion_insert` |
| Vistas | `vw_descripcion` | `vw_itinerario_vuelos` |

> **Nota:** El link del video demostrativo será agregado una vez grabado.
