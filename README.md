# 🛫 Pegaso Airlines — Sistema Integral de Gestión Aeronáutica

Este repositorio contiene el proyecto **Pegaso Airlines**, desarrollado como trabajo final para la materia **Sistemas de Bases de Datos (Fase Final)** en ESPOL (I PAO 2026).

El sistema simula el ecosistema operativo completo de una aerolínea comercial, implementando funcionalidades complejas bajo estrictas regulaciones aeronáuticas. Se ha diseñado siguiendo una arquitectura MVC utilizando **Python (Flask)** para el frontend y **MySQL (InnoDB)** como motor de base de datos relacional y transaccional.

---

## 📌 Enlaces Importantes

- 🎥 **Video de Demostración:** [Ver en YouTube](https://youtu.be/90jEkCeoxRs)
- 💻 **Repositorio en GitHub:** [https://github.com/1Mejor2345/SBD_2P](https://github.com/1Mejor2345/SBD_2P)
- 📄 **Documentación Técnica:** [Grupo6_Documento_Final.pdf](./Grupo6_Documento_Final.pdf) (Ubicado en la raíz del repositorio). Toda la documentación de desarrollo (código Overleaf, diagramas) se encuentra en la carpeta [`docs/overleaf_final/`](docs/overleaf_final/).

---

## 🚀 Características Principales

1. **Gestión de Reservaciones:** Búsqueda de vuelos, generación de PNR únicos (6 caracteres) y cálculo dinámico de precios (según clase y distancia).
2. **Check-in y Equipajes (Regulaciones IATA):** Restricciones de 32 kg por pieza, autogeneración de etiquetas y control de sobreventa.
3. **Módulo de Vuelos y Tripulación:** Instanciación estricta de vuelos a partir de una "Ruta Maestra", manejo de estados (Programado, Embarque, En Vuelo, etc.) y asignación de tripulación técnica.
4. **Seguridad y Auditoría Transaccional:** Uso intensivo de `SELECT ... FOR UPDATE` (bloqueos por fila), 7 Procedimientos Almacenados, 7 Triggers para trazabilidad y soft-delete de pasajeros para cumplimiento regulatorio.

---

## 🛠️ Requisitos Previos

Asegúrate de tener instalado lo siguiente en tu sistema:
- **MySQL Server 8.0+** y MySQL Workbench.
- **Python 3.11+**
- (Opcional pero recomendado) Entorno virtual de Python (`venv`).

---

## ⚙️ Instrucciones de Ejecución

El despliegue está dividido en dos partes: la **Base de Datos** y el **Servidor Web**.

### Paso 1: Configurar la Base de Datos (MySQL)
La base de datos consta de 7 scripts secuenciales que construyen la arquitectura completa de forma modular. 

Abre **MySQL Workbench**, conéctate a tu servidor local y ejecuta los scripts de la carpeta `database/` **en este orden exacto**:
1. `01_pegaso_schema.sql`: Crea la BD `pegaso_airlines` y la estructura de las 22 tablas.
2. `02_pegaso_indexes.sql`: Construye los 10 índices optimizados.
3. `03_pegaso_views.sql`: Despliega las 6 vistas para análisis y consultas.
4. `04_pegaso_procedures.sql`: Crea los 7 procedimientos almacenados.
5. `05_pegaso_triggers.sql`: Crea los 7 triggers de auditoría y validación.
6. `06_pegaso_seed.sql`: Inserta la data semilla (países, flota, y vuelos de prueba).
7. `07_pegaso_pruebas.sql`: (Opcional) Script con consultas para pruebas en vivo y demostración.

### Paso 2: Configurar la Aplicación (Python/Flask)
Abre una terminal en la raíz del proyecto (`SBD_2P`) y sigue estos pasos:

1. **Crea y activa un entorno virtual (recomendado):**
   ```bash
   python -m venv venv
   # En Windows:
   venv\Scripts\activate
   # En Mac/Linux:
   source venv/bin/activate
   ```

2. **Instala las dependencias necesarias:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configura las variables de entorno:**
   Verifica que existe un archivo `.env` en la raíz del proyecto. Este archivo contiene las credenciales de tu base de datos local:
   ```env
   DB_HOST=localhost
   DB_USER=tu_usuario_de_mysql
   DB_PASS=tu_contraseña_de_mysql
   DB_NAME=pegaso_airlines
   ```
   *(Asegúrate de actualizar `DB_USER` y `DB_PASS` con tus credenciales de MySQL locales).*

4. **Inicia el servidor:**
   ```bash
   python app.py
   ```

### Paso 3: Acceder al Sistema
Una vez que el servidor esté corriendo, abre tu navegador web e ingresa a:
👉 **[http://localhost:5000](http://localhost:5000)**

Puedes utilizar los usuarios predefinidos en la data semilla para probar los diferentes roles (Administrador, Supervisor, Agente, Viajero).

---

## 👥 Equipo de Desarrollo (Grupo 6)
- Santiago Rubén Gómez Medina
- Fanny Marcela López Ramos
- José Luis Paladines Sánchez
- Bruno Alejandro Román Torres
- Matías Ariel Sánchez Baldeón

**Docente:** Ph.D. Patricia Suárez Riofrío  
**Materia:** Sistemas de Bases de Datos (Paralelo 4)  
**Institución:** Escuela Superior Politécnica del Litoral (ESPOL)
