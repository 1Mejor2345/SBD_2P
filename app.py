import os
import string
import random
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, session, flash
import mysql.connector
from mysql.connector import pooling
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'pegaso-secret-2026')

# ─── Conexión MySQL con Pool ─────────────────────────────────────
dbconfig = {
    "host": os.getenv('MYSQL_HOST', 'localhost'),
    "user": os.getenv('MYSQL_USER', 'root'),
    "password": os.getenv('MYSQL_PASSWORD', ''),
    "database": os.getenv('MYSQL_DATABASE', 'pegaso_airlines'),
}

try:
    pool = pooling.MySQLConnectionPool(pool_name="pegaso_pool", pool_size=5, **dbconfig)
except mysql.connector.Error:
    pool = None
    print("Warning: No se pudo conectar a MySQL. Ejecutando en modo demo.")

def get_db():
    if not pool:
        return None
    try:
        return pool.get_connection()
    except mysql.connector.Error as err:
        print(f"Error conexión: {err}")
        return None

def execute_query(query, params=None, fetchone=False, fetchall=False):
    conn = get_db()
    if not conn:
        return [] if fetchall else None
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        if fetchone:
            return cursor.fetchone()
        elif fetchall:
            return cursor.fetchall()
        else:
            conn.commit()
            return cursor.rowcount
    except mysql.connector.Error as err:
        print(f"Error query: {err}")
        if not fetchone and not fetchall:
            conn.rollback()
        return [] if fetchall else None
    finally:
        cursor.close()
        conn.close()

def call_procedure(proc_name, params):
    """Llama un stored procedure y retorna los parámetros OUT."""
    conn = get_db()
    if not conn:
        return None
    cursor = conn.cursor()
    try:
        result_args = cursor.callproc(proc_name, params)
        conn.commit()
        # Fetch any result sets to clear them
        for result in cursor.stored_results():
            result.fetchall()
        return result_args
    except mysql.connector.Error as err:
        print(f"Error procedure {proc_name}: {err}")
        conn.rollback()
        return None
    finally:
        cursor.close()
        conn.close()

# ─── Decoradores ─────────────────────────────────────────────────
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Inicie sesión para continuar.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

def role_required(roles):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if session.get('user_role') not in roles:
                flash('No tiene permisos para esta sección.', 'danger')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated
    return decorator

# ─── AUTENTICACIÓN ───────────────────────────────────────────────
@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        
        if not username or not password:
            flash('Complete todos los campos.', 'danger')
            return render_template('login.html')
        
        user = execute_query(
            """SELECT u.id, u.username, u.hash_contrasena, u.esta_activo,
                      r.nombre AS rol_nombre, p.nombres, p.apellidos
               FROM usuarios u
               JOIN roles r ON u.rol_id = r.id
               JOIN personas p ON u.persona_id = p.id
               WHERE u.username = %s""",
            (username,), fetchone=True
        )
        
        import hashlib
        
        def verify_password(stored_hash, provided_password):
            if stored_hash.startswith(('pbkdf2:', 'scrypt:')):
                return check_password_hash(stored_hash, provided_password)
            return stored_hash == hashlib.sha256(provided_password.encode()).hexdigest()
        
        if user and user['esta_activo'] and verify_password(user['hash_contrasena'], password):
            session['user_id'] = user['id']
            session['user_role'] = user['rol_nombre']
            session['user_name'] = f"{user['nombres']} {user['apellidos']}"
            session['username'] = user['username']
            # Actualizar último acceso
            execute_query("UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = %s", (user['id'],))
            flash(f'Bienvenido, {session["user_name"]}', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Usuario o contraseña incorrectos.', 'danger')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('Sesión cerrada correctamente.', 'success')
    return redirect(url_for('login'))

# ─── DASHBOARD ───────────────────────────────────────────────────
@app.route('/dashboard')
@login_required
def dashboard():
    stats = {}
    role = session.get('user_role')
    
    if role == 'Agente':
        stats['reservaciones_hoy'] = execute_query(
            "SELECT COUNT(*) AS c FROM reservaciones WHERE DATE(fecha_creacion) = CURDATE()",
            fetchone=True
        ) or {'c': 0}
        stats['checkins_pendientes'] = execute_query(
            "SELECT COUNT(*) AS c FROM boletos b JOIN vuelos v ON b.vuelo_id = v.id WHERE b.estado = 'EMITIDO' AND DATE(v.fecha_hora_salida) = CURDATE()",
            fetchone=True
        ) or {'c': 0}
        stats['vuelos_hoy'] = execute_query(
            "SELECT COUNT(*) AS c FROM vuelos WHERE DATE(fecha_hora_salida) = CURDATE()",
            fetchone=True
        ) or {'c': 0}
    elif role == 'Supervisor':
        stats['vuelos_activos'] = execute_query(
            "SELECT COUNT(*) AS c FROM vuelos WHERE estado IN ('PROGRAMADO','EMBARQUE','EN_VUELO')",
            fetchone=True
        ) or {'c': 0}
        stats['tripulantes_asignados'] = execute_query(
            "SELECT COUNT(DISTINCT empleado_id) AS c FROM tripulacion_vuelo tv JOIN vuelos v ON tv.vuelo_id = v.id WHERE v.estado IN ('PROGRAMADO','EMBARQUE')",
            fetchone=True
        ) or {'c': 0}
    elif role == 'Administrador':
        stats['aviones_operativos'] = execute_query(
            "SELECT COUNT(*) AS c FROM aviones WHERE estado = 'OPERATIVO'",
            fetchone=True
        ) or {'c': 0}
        stats['empleados_activos'] = execute_query(
            "SELECT COUNT(*) AS c FROM empleados WHERE esta_activo = TRUE",
            fetchone=True
        ) or {'c': 0}
        stats['total_rutas'] = execute_query(
            "SELECT COUNT(*) AS c FROM rutas WHERE esta_activa = TRUE",
            fetchone=True
        ) or {'c': 0}
    
    # Próximos vuelos para todos los roles
    proximos_vuelos = execute_query(
        """SELECT v.id, v.numero_vuelo, v.fecha_hora_salida, v.fecha_hora_llegada, v.estado,
                  ao.codigo_iata AS origen, ad.codigo_iata AS destino,
                  co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino
           FROM vuelos v
           JOIN rutas r ON v.ruta_id = r.id
           JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
           JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
           JOIN ciudades co ON ao.ciudad_id = co.id
           JOIN ciudades cd ON ad.ciudad_id = cd.id
           WHERE v.fecha_hora_salida >= NOW()
           ORDER BY v.fecha_hora_salida LIMIT 10""",
        fetchall=True
    ) or []
    
    return render_template('dashboard.html', stats=stats, proximos_vuelos=proximos_vuelos)

# ─── CRUD 1: RESERVACIONES ───────────────────────────────────────
@app.route('/reservaciones/buscar')
@login_required
@role_required(['Agente', 'Administrador', 'Supervisor'])
def buscar_vuelos():
    aeropuertos = execute_query(
        """SELECT a.codigo_iata, a.nombre, c.nombre AS ciudad
           FROM aeropuertos a JOIN ciudades c ON a.ciudad_id = c.id
           ORDER BY c.nombre""",
        fetchall=True
    ) or []
    return render_template('reservaciones/buscar_vuelos.html', aeropuertos=aeropuertos)

@app.route('/reservaciones/resultados', methods=['POST'])
@login_required
def resultados_vuelos():
    origen = request.form.get('origen')
    destino = request.form.get('destino')
    fecha = request.form.get('fecha')
    pasajeros = int(request.form.get('pasajeros', 1))
    
    vuelos = execute_query(
        """SELECT v.id, v.numero_vuelo, v.fecha_hora_salida, v.fecha_hora_llegada,
                  ao.codigo_iata AS origen_iata, ad.codigo_iata AS destino_iata,
                  co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino,
                  r.duracion_estimada_min, ma.modelo AS avion_modelo,
                  ma.capacidad_pasajeros,
                  (SELECT COUNT(*) FROM boletos b WHERE b.vuelo_id = v.id AND b.estado NOT IN ('CANCELADO','NO_SHOW')) AS boletos_vendidos,
                  v.limite_sobreventa
           FROM vuelos v
           JOIN rutas r ON v.ruta_id = r.id
           JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
           JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
           JOIN ciudades co ON ao.ciudad_id = co.id
           JOIN ciudades cd ON ad.ciudad_id = cd.id
           JOIN aviones a ON v.avion_matricula = a.matricula
           JOIN modelos_avion ma ON a.modelo_id = ma.id
           WHERE r.origen_iata = %s AND r.destino_iata = %s
             AND DATE(v.fecha_hora_salida) = %s
             AND v.estado = 'PROGRAMADO'
           ORDER BY v.fecha_hora_salida""",
        (origen, destino, fecha), fetchall=True
    ) or []
    
    tarifas = execute_query("SELECT * FROM familias_tarifa ORDER BY id", fetchall=True) or []
    clases = execute_query("SELECT * FROM clases_servicio ORDER BY id", fetchall=True) or []
    
    return render_template('reservaciones/resultados.html',
                           vuelos=vuelos, pasajeros=pasajeros, tarifas=tarifas, clases=clases,
                           origen=origen, destino=destino, fecha=fecha)

@app.route('/reservaciones/nueva', methods=['GET', 'POST'])
@login_required
@role_required(['Agente', 'Administrador'])
def nueva_reservacion():
    if request.method == 'POST':
        email = request.form.get('email')
        telefono = request.form.get('telefono')
        vuelo_id = request.form.get('vuelo_id')
        clase_id = request.form.get('clase_servicio_id', 1)
        tarifa_id = request.form.get('familia_tarifa_id', 1)
        precio = request.form.get('precio', 0)
        
        # Datos del pasajero
        tipo_doc = request.form.get('tipo_documento')
        num_doc = request.form.get('numero_documento')
        nombres = request.form.get('nombres')
        apellidos = request.form.get('apellidos')
        pasajero_email = request.form.get('pasajero_email')
        pasajero_tel = request.form.get('pasajero_telefono')
        fecha_nac = request.form.get('fecha_nacimiento') or None
        nacionalidad = request.form.get('nacionalidad') or 'EC'
        genero = request.form.get('genero') or 'M'
        
        # 1. Verificar si pasajero existe, si no crearlo
        pasajero = execute_query(
            "SELECT id FROM personas WHERE tipo_documento = %s AND numero_documento = %s",
            (tipo_doc, num_doc), fetchone=True
        )
        
        if not pasajero:
            execute_query(
                """INSERT INTO personas (tipo_documento, numero_documento, nombres, apellidos, email, telefono, fecha_nacimiento, nacionalidad, genero)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                (tipo_doc, num_doc, nombres, apellidos, pasajero_email, pasajero_tel, fecha_nac, nacionalidad, genero)
            )
            pasajero = execute_query(
                "SELECT id FROM personas WHERE tipo_documento = %s AND numero_documento = %s",
                (tipo_doc, num_doc), fetchone=True
            )
        
        if not pasajero:
            flash('Error al registrar pasajero.', 'danger')
            return redirect(url_for('buscar_vuelos'))
        
        pasajero_id = pasajero['id']
        
        # 2. Crear reservación
        result = call_procedure('sp_crear_reservacion', [
            email, telefono, session['user_id'], '', ''
        ])
        
        if result and 'EXITO' in str(result[4]):
            codigo_pnr = result[3]
            # Obtener ID de la reservación
            res = execute_query(
                "SELECT id FROM reservaciones WHERE codigo_pnr = %s", (codigo_pnr,), fetchone=True
            )
            if res:
                reservacion_id = res['id']
                # 3. Emitir boleto
                result2 = call_procedure('sp_emitir_boleto', [
                    reservacion_id, pasajero_id, int(vuelo_id),
                    int(clase_id), int(tarifa_id), float(precio), '', ''
                ])
                
                if result2 and 'EXITO' in str(result2[7]):
                    # Actualizar reservación a CONFIRMADA
                    execute_query(
                        "UPDATE reservaciones SET estado = 'CONFIRMADA' WHERE id = %s",
                        (reservacion_id,)
                    )
                    flash(f'✅ Reservación {codigo_pnr} creada. Boleto: {result2[6]}', 'success')
                    return redirect(url_for('detalle_reservacion', id=reservacion_id))
                else:
                    error_msg = result2[7] if result2 else 'Error desconocido'
                    flash(f'Error al emitir boleto: {error_msg}', 'danger')
            else:
                flash('Error al obtener reservación.', 'danger')
        else:
            error_msg = result[4] if result else 'Error desconocido'
            flash(f'Error al crear reservación: {error_msg}', 'danger')
        
        return redirect(url_for('buscar_vuelos'))
    
    # GET: mostrar formulario
    vuelo_id = request.args.get('vuelo_id')
    tarifa_id = request.args.get('tarifa_id', 1)
    clase_id = request.args.get('clase_id', 1)
    
    vuelo = None
    if vuelo_id:
        vuelo = execute_query(
            """SELECT v.*, r.origen_iata, r.destino_iata, r.duracion_estimada_min,
                      ao.nombre AS aero_origen, ad.nombre AS aero_destino,
                      co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino,
                      ma.modelo AS avion_modelo
               FROM vuelos v
               JOIN rutas r ON v.ruta_id = r.id
               JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
               JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
               JOIN ciudades co ON ao.ciudad_id = co.id
               JOIN ciudades cd ON ad.ciudad_id = cd.id
               JOIN aviones a ON v.avion_matricula = a.matricula
               JOIN modelos_avion ma ON a.modelo_id = ma.id
               WHERE v.id = %s""",
            (vuelo_id,), fetchone=True
        )
    
    tarifa = execute_query("SELECT * FROM familias_tarifa WHERE id = %s", (tarifa_id,), fetchone=True)
    clase = execute_query("SELECT * FROM clases_servicio WHERE id = %s", (clase_id,), fetchone=True)
    paises = execute_query("SELECT codigo_iso, nombre FROM paises ORDER BY nombre", fetchall=True) or []
    
    return render_template('reservaciones/nueva.html',
                           vuelo=vuelo, tarifa=tarifa, clase=clase, paises=paises)

@app.route('/reservaciones')
@login_required
def lista_reservaciones():
    reservaciones = execute_query(
        """SELECT r.id, r.codigo_pnr, r.fecha_creacion, r.estado, r.contacto_email,
                  COUNT(b.id) AS num_boletos,
                  GROUP_CONCAT(DISTINCT CONCAT(ao.codigo_iata, '→', ad.codigo_iata) SEPARATOR ', ') AS rutas
           FROM reservaciones r
           LEFT JOIN boletos b ON r.id = b.reservacion_id
           LEFT JOIN vuelos v ON b.vuelo_id = v.id
           LEFT JOIN rutas ru ON v.ruta_id = ru.id
           LEFT JOIN aeropuertos ao ON ru.origen_iata = ao.codigo_iata
           LEFT JOIN aeropuertos ad ON ru.destino_iata = ad.codigo_iata
           GROUP BY r.id
           ORDER BY r.fecha_creacion DESC
           LIMIT 50""",
        fetchall=True
    ) or []
    return render_template('reservaciones/lista.html', reservaciones=reservaciones)

@app.route('/reservaciones/<int:id>')
@login_required
def detalle_reservacion(id):
    reservacion = execute_query(
        "SELECT * FROM reservaciones WHERE id = %s", (id,), fetchone=True
    )
    boletos = execute_query(
        """SELECT b.*, p.nombres, p.apellidos, p.numero_documento,
                  v.numero_vuelo, v.fecha_hora_salida, v.fecha_hora_llegada,
                  r.origen_iata, r.destino_iata,
                  cs.nombre AS clase, ft.nombre AS tarifa
           FROM boletos b
           JOIN personas p ON b.pasajero_id = p.id
           JOIN vuelos v ON b.vuelo_id = v.id
           JOIN rutas r ON v.ruta_id = r.id
           JOIN clases_servicio cs ON b.clase_servicio_id = cs.id
           JOIN familias_tarifa ft ON b.familia_tarifa_id = ft.id
           WHERE b.reservacion_id = %s""",
        (id,), fetchall=True
    ) or []
    return render_template('reservaciones/detalle.html', reservacion=reservacion, boletos=boletos)

@app.route('/reservaciones/cancelar/<int:id>', methods=['POST'])
@login_required
def cancelar_reservacion(id):
    result = call_procedure('sp_cancelar_reservacion', [id, ''])
    if result and 'EXITO' in str(result[1]):
        flash('Reservación cancelada exitosamente.', 'success')
    else:
        flash(f'Error: {result[1] if result else "desconocido"}', 'danger')
    return redirect(url_for('lista_reservaciones'))

# ─── CRUD 2: CHECK-IN Y EQUIPAJE ────────────────────────────────
@app.route('/checkin/buscar', methods=['GET', 'POST'])
@login_required
@role_required(['Agente', 'Administrador'])
def buscar_checkin():
    resultados = None
    if request.method == 'POST':
        busqueda = request.form.get('busqueda', '').strip()
        tipo = request.form.get('tipo_busqueda', 'pnr')
        
        if tipo == 'pnr':
            resultados = execute_query(
                """SELECT r.id, r.codigo_pnr, r.estado,
                          v.numero_vuelo, v.fecha_hora_salida,
                          ao.codigo_iata AS origen, ad.codigo_iata AS destino
                   FROM reservaciones r
                   JOIN boletos b ON r.id = b.reservacion_id
                   JOIN vuelos v ON b.vuelo_id = v.id
                   JOIN rutas ru ON v.ruta_id = ru.id
                   JOIN aeropuertos ao ON ru.origen_iata = ao.codigo_iata
                   JOIN aeropuertos ad ON ru.destino_iata = ad.codigo_iata
                   WHERE r.codigo_pnr = %s AND r.estado != 'CANCELADA'
                   GROUP BY r.id, v.id""",
                (busqueda.upper(),), fetchall=True
            ) or []
        else:
            resultados = execute_query(
                """SELECT r.id, r.codigo_pnr, r.estado,
                          v.numero_vuelo, v.fecha_hora_salida,
                          ao.codigo_iata AS origen, ad.codigo_iata AS destino
                   FROM reservaciones r
                   JOIN boletos b ON r.id = b.reservacion_id
                   JOIN personas p ON b.pasajero_id = p.id
                   JOIN vuelos v ON b.vuelo_id = v.id
                   JOIN rutas ru ON v.ruta_id = ru.id
                   JOIN aeropuertos ao ON ru.origen_iata = ao.codigo_iata
                   JOIN aeropuertos ad ON ru.destino_iata = ad.codigo_iata
                   WHERE p.apellidos LIKE %s AND r.estado != 'CANCELADA'
                   GROUP BY r.id, v.id""",
                (f'%{busqueda}%',), fetchall=True
            ) or []
        
        if not resultados:
            flash('No se encontraron reservaciones.', 'warning')
    
    return render_template('checkin/buscar.html', resultados=resultados)

@app.route('/checkin/pasajeros/<int:reservacion_id>')
@login_required
def pasajeros_checkin(reservacion_id):
    reservacion = execute_query(
        "SELECT * FROM reservaciones WHERE id = %s", (reservacion_id,), fetchone=True
    )
    boletos = execute_query(
        """SELECT b.id, b.numero_boleto, b.estado, b.numero_asiento,
                  p.nombres, p.apellidos, p.numero_documento,
                  v.numero_vuelo, v.fecha_hora_salida, v.fecha_hora_llegada,
                  r.origen_iata, r.destino_iata,
                  cs.nombre AS clase, ft.nombre AS tarifa
           FROM boletos b
           JOIN personas p ON b.pasajero_id = p.id
           JOIN vuelos v ON b.vuelo_id = v.id
           JOIN rutas r ON v.ruta_id = r.id
           JOIN clases_servicio cs ON b.clase_servicio_id = cs.id
           JOIN familias_tarifa ft ON b.familia_tarifa_id = ft.id
           WHERE b.reservacion_id = %s""",
        (reservacion_id,), fetchall=True
    ) or []
    return render_template('checkin/pasajeros.html', reservacion=reservacion, boletos=boletos)

@app.route('/checkin/proceso/<int:boleto_id>', methods=['GET', 'POST'])
@login_required
def proceso_checkin(boleto_id):
    if request.method == 'POST':
        asiento_id = request.form.get('asiento_vuelo_id')
        if not asiento_id:
            flash('Seleccione un asiento.', 'warning')
            return redirect(url_for('proceso_checkin', boleto_id=boleto_id))
        
        result = call_procedure('sp_checkin_pasajero', [boleto_id, int(asiento_id), '', ''])
        if result and 'EXITO' in str(result[3]):
            flash(f'✅ Check-in exitoso. Pase de abordar generado.', 'success')
            return redirect(url_for('pase_abordar', boleto_id=boleto_id))
        else:
            flash(f'Error: {result[3] if result else "desconocido"}', 'danger')
    
    boleto = execute_query(
        """SELECT b.*, p.nombres, p.apellidos, p.numero_documento,
                  v.id AS vuelo_id, v.numero_vuelo, v.fecha_hora_salida,
                  r.origen_iata, r.destino_iata,
                  cs.nombre AS clase
           FROM boletos b
           JOIN personas p ON b.pasajero_id = p.id
           JOIN vuelos v ON b.vuelo_id = v.id
           JOIN rutas r ON v.ruta_id = r.id
           JOIN clases_servicio cs ON b.clase_servicio_id = cs.id
           WHERE b.id = %s""",
        (boleto_id,), fetchone=True
    )
    
    asientos = []
    if boleto:
        asientos = execute_query(
            """SELECT av.id, av.estado, c.fila, c.columna, c.clase_servicio, c.es_salida_emergencia,
                      CONCAT(c.fila, c.columna) AS nombre_asiento
               FROM asientos_vuelo av
               JOIN configuracion_asientos c ON av.configuracion_asiento_id = c.id
               WHERE av.vuelo_id = %s
               ORDER BY c.fila, c.columna""",
            (boleto['vuelo_id'],), fetchall=True
        ) or []
    
    return render_template('checkin/proceso.html', boleto=boleto, asientos=asientos)

@app.route('/checkin/equipaje/<int:boleto_id>', methods=['GET', 'POST'])
@login_required
def registrar_equipaje(boleto_id):
    if request.method == 'POST':
        peso = float(request.form.get('peso_kg', 0))
        tipo = request.form.get('tipo', 'BODEGA')
        
        result = call_procedure('sp_registrar_equipaje', [boleto_id, peso, tipo, '', ''])
        if result and 'EXITO' in str(result[4]):
            flash(f'✅ Equipaje registrado. Tag: {result[3]}', 'success')
        else:
            flash(f'Error: {result[4] if result else "desconocido"}', 'danger')
    
    boleto = execute_query(
        """SELECT b.*, p.nombres, p.apellidos, v.numero_vuelo,
                  r.origen_iata, r.destino_iata, ft.nombre AS tarifa,
                  ft.incluye_equipaje_bodega, ft.peso_equipaje_incluido_kg
           FROM boletos b
           JOIN personas p ON b.pasajero_id = p.id
           JOIN vuelos v ON b.vuelo_id = v.id
           JOIN rutas r ON v.ruta_id = r.id
           JOIN familias_tarifa ft ON b.familia_tarifa_id = ft.id
           WHERE b.id = %s""",
        (boleto_id,), fetchone=True
    )
    
    equipajes = execute_query(
        "SELECT * FROM equipajes WHERE boleto_id = %s ORDER BY fecha_registro",
        (boleto_id,), fetchall=True
    ) or []
    
    return render_template('checkin/equipaje.html', boleto=boleto, equipajes=equipajes)

@app.route('/checkin/pase/<int:boleto_id>')
@login_required
def pase_abordar(boleto_id):
    pase = execute_query(
        """SELECT pa.*, b.numero_boleto, b.numero_asiento, b.precio,
                  p.nombres, p.apellidos, p.numero_documento,
                  v.numero_vuelo, v.fecha_hora_salida, v.fecha_hora_llegada,
                  r.origen_iata, r.destino_iata,
                  ao.nombre AS aero_origen, ad.nombre AS aero_destino,
                  co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino,
                  cs.nombre AS clase, ft.nombre AS tarifa,
                  pe.numero AS puerta_num
           FROM pases_abordar pa
           JOIN boletos b ON pa.boleto_id = b.id
           JOIN personas p ON b.pasajero_id = p.id
           JOIN vuelos v ON b.vuelo_id = v.id
           JOIN rutas r ON v.ruta_id = r.id
           JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
           JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
           JOIN ciudades co ON ao.ciudad_id = co.id
           JOIN ciudades cd ON ad.ciudad_id = cd.id
           JOIN clases_servicio cs ON b.clase_servicio_id = cs.id
           JOIN familias_tarifa ft ON b.familia_tarifa_id = ft.id
           LEFT JOIN puertas_embarque pe ON v.puerta_embarque_id = pe.id
           WHERE pa.boleto_id = %s""",
        (boleto_id,), fetchone=True
    )
    return render_template('checkin/pase_abordar.html', pase=pase)

# ─── CRUD 3: VUELOS Y TRIPULACIÓN ───────────────────────────────
@app.route('/vuelos')
@login_required
@role_required(['Supervisor', 'Administrador'])
def lista_vuelos():
    estado_filtro = request.args.get('estado', '')
    query = """SELECT v.id, v.numero_vuelo, v.fecha_hora_salida, v.fecha_hora_llegada, v.estado,
                      r.origen_iata, r.destino_iata, a.matricula, ma.modelo,
                      co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino,
                      (SELECT COUNT(*) FROM boletos b WHERE b.vuelo_id = v.id AND b.estado NOT IN ('CANCELADO','NO_SHOW')) AS pasajeros
               FROM vuelos v
               JOIN rutas r ON v.ruta_id = r.id
               JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
               JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
               JOIN ciudades co ON ao.ciudad_id = co.id
               JOIN ciudades cd ON ad.ciudad_id = cd.id
               JOIN aviones a ON v.avion_matricula = a.matricula
               JOIN modelos_avion ma ON a.modelo_id = ma.id"""
    params = []
    if estado_filtro:
        query += " WHERE v.estado = %s"
        params.append(estado_filtro)
    query += " ORDER BY v.fecha_hora_salida DESC LIMIT 50"
    
    vuelos = execute_query(query, tuple(params) if params else None, fetchall=True) or []
    return render_template('vuelos/lista.html', vuelos=vuelos, estado_filtro=estado_filtro)

@app.route('/vuelos/nuevo', methods=['GET', 'POST'])
@login_required
@role_required(['Supervisor', 'Administrador'])
def nuevo_vuelo():
    if request.method == 'POST':
        numero = request.form.get('numero_vuelo')
        ruta_id = request.form.get('ruta_id')
        avion = request.form.get('avion_matricula')
        salida = request.form.get('fecha_hora_salida')
        llegada = request.form.get('fecha_hora_llegada')
        puerta = request.form.get('puerta_embarque_id') or None
        sobreventa = request.form.get('limite_sobreventa', 0)
        observaciones = request.form.get('observaciones', '')
        
        execute_query(
            """INSERT INTO vuelos (numero_vuelo, ruta_id, avion_matricula, fecha_hora_salida, fecha_hora_llegada, puerta_embarque_id, limite_sobreventa, observaciones)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (numero, ruta_id, avion, salida, llegada, puerta, sobreventa, observaciones)
        )
        flash('✅ Vuelo programado exitosamente.', 'success')
        return redirect(url_for('lista_vuelos'))
    
    rutas = execute_query(
        """SELECT r.id, r.origen_iata, r.destino_iata, r.distancia_km, r.duracion_estimada_min,
                  co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino
           FROM rutas r
           JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
           JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
           JOIN ciudades co ON ao.ciudad_id = co.id
           JOIN ciudades cd ON ad.ciudad_id = cd.id
           WHERE r.esta_activa = TRUE
           ORDER BY co.nombre""",
        fetchall=True
    ) or []
    aviones = execute_query(
        """SELECT a.matricula, ma.fabricante, ma.modelo, ma.capacidad_pasajeros
           FROM aviones a JOIN modelos_avion ma ON a.modelo_id = ma.id
           WHERE a.estado = 'OPERATIVO' ORDER BY a.matricula""",
        fetchall=True
    ) or []
    puertas = execute_query(
        """SELECT pe.id, pe.numero, a.codigo_iata, c.nombre AS ciudad
           FROM puertas_embarque pe
           JOIN aeropuertos a ON pe.aeropuerto_iata = a.codigo_iata
           JOIN ciudades c ON a.ciudad_id = c.id
           WHERE pe.estado = 'DISPONIBLE'
           ORDER BY a.codigo_iata, pe.numero""",
        fetchall=True
    ) or []
    
    return render_template('vuelos/nuevo.html', rutas=rutas, aviones=aviones, puertas=puertas)

@app.route('/vuelos/<int:id>')
@login_required
def detalle_vuelo(id):
    vuelo = execute_query(
        """SELECT v.*, r.origen_iata, r.destino_iata, r.distancia_km,
                  ao.nombre AS aero_origen, ad.nombre AS aero_destino,
                  co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino,
                  a.matricula, ma.modelo, ma.fabricante, ma.capacidad_pasajeros
           FROM vuelos v
           JOIN rutas r ON v.ruta_id = r.id
           JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
           JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
           JOIN ciudades co ON ao.ciudad_id = co.id
           JOIN ciudades cd ON ad.ciudad_id = cd.id
           JOIN aviones a ON v.avion_matricula = a.matricula
           JOIN modelos_avion ma ON a.modelo_id = ma.id
           WHERE v.id = %s""",
        (id,), fetchone=True
    )
    tripulacion = execute_query(
        """SELECT tv.id, tv.funcion, p.nombres, p.apellidos, e.cargo, e.numero_licencia
           FROM tripulacion_vuelo tv
           JOIN empleados e ON tv.empleado_id = e.persona_id
           JOIN personas p ON e.persona_id = p.id
           WHERE tv.vuelo_id = %s""",
        (id,), fetchall=True
    ) or []
    pasajeros = execute_query(
        """SELECT b.id AS boleto_id, b.numero_boleto, b.numero_asiento, b.estado, b.precio,
                  p.nombres, p.apellidos, p.numero_documento,
                  cs.nombre AS clase, ft.nombre AS tarifa,
                  (SELECT COUNT(*) FROM equipajes e WHERE e.boleto_id = b.id) AS equipajes
           FROM boletos b
           JOIN personas p ON b.pasajero_id = p.id
           JOIN clases_servicio cs ON b.clase_servicio_id = cs.id
           JOIN familias_tarifa ft ON b.familia_tarifa_id = ft.id
           WHERE b.vuelo_id = %s AND b.estado != 'CANCELADO'
           ORDER BY b.fecha_emision""",
        (id,), fetchall=True
    ) or []
    return render_template('vuelos/detalle.html', vuelo=vuelo, tripulacion=tripulacion, pasajeros=pasajeros)

@app.route('/vuelos/estado/<int:id>', methods=['POST'])
@login_required
@role_required(['Supervisor', 'Administrador'])
def cambiar_estado_vuelo(id):
    nuevo_estado = request.form.get('estado')
    observaciones = request.form.get('observaciones', '')
    result = call_procedure('sp_cambiar_estado_vuelo', [id, nuevo_estado, observaciones, ''])
    if result and 'EXITO' in str(result[3]):
        flash(f'Estado actualizado a {nuevo_estado}.', 'success')
    else:
        flash(f'Error: {result[3] if result else "desconocido"}', 'danger')
    return redirect(url_for('detalle_vuelo', id=id))

@app.route('/vuelos/tripulacion/<int:id>', methods=['GET', 'POST'])
@login_required
@role_required(['Supervisor', 'Administrador'])
def tripulacion_vuelo(id):
    if request.method == 'POST':
        empleado_id = request.form.get('empleado_id')
        funcion = request.form.get('funcion')
        result = call_procedure('sp_asignar_tripulacion', [id, int(empleado_id), funcion, ''])
        if result and 'EXITO' in str(result[3]):
            flash('Tripulante asignado exitosamente.', 'success')
        else:
            flash(f'Error: {result[3] if result else "desconocido"}', 'danger')
    
    vuelo = execute_query(
        """SELECT v.*, r.origen_iata, r.destino_iata, co.nombre AS ciudad_origen, cd.nombre AS ciudad_destino
           FROM vuelos v
           JOIN rutas r ON v.ruta_id = r.id
           JOIN aeropuertos ao ON r.origen_iata = ao.codigo_iata
           JOIN aeropuertos ad ON r.destino_iata = ad.codigo_iata
           JOIN ciudades co ON ao.ciudad_id = co.id
           JOIN ciudades cd ON ad.ciudad_id = cd.id
           WHERE v.id = %s""", (id,), fetchone=True
    )
    tripulacion = execute_query(
        """SELECT tv.id, tv.funcion, p.nombres, p.apellidos, e.cargo
           FROM tripulacion_vuelo tv
           JOIN empleados e ON tv.empleado_id = e.persona_id
           JOIN personas p ON e.persona_id = p.id
           WHERE tv.vuelo_id = %s""",
        (id,), fetchall=True
    ) or []
    empleados = execute_query(
        """SELECT e.persona_id, p.nombres, p.apellidos, e.cargo, e.numero_licencia
           FROM empleados e JOIN personas p ON e.persona_id = p.id
           WHERE e.esta_activo = TRUE AND e.cargo IN ('PILOTO','COPILOTO','SOBRECARGO')
           ORDER BY e.cargo, p.apellidos""",
        fetchall=True
    ) or []
    return render_template('vuelos/tripulacion.html', vuelo=vuelo, tripulacion=tripulacion, empleados=empleados)

@app.route('/vuelos/tripulacion/eliminar', methods=['POST'])
@login_required
@role_required(['Supervisor', 'Administrador'])
def eliminar_tripulante():
    tripulacion_id = request.form.get('tripulacion_id')
    vuelo_id = request.form.get('vuelo_id')
    execute_query("DELETE FROM tripulacion_vuelo WHERE id = %s", (tripulacion_id,))
    flash('Tripulante removido del vuelo.', 'info')
    return redirect(url_for('tripulacion_vuelo', id=vuelo_id))

# ─── ADMINISTRACIÓN ──────────────────────────────────────────────
@app.route('/admin/aviones')
@login_required
@role_required(['Administrador'])
def admin_aviones():
    aviones = execute_query(
        """SELECT a.matricula, a.anio_fabricacion, a.estado, a.fecha_registro,
                  ma.fabricante, ma.modelo, ma.capacidad_pasajeros
           FROM aviones a JOIN modelos_avion ma ON a.modelo_id = ma.id
           ORDER BY a.matricula""",
        fetchall=True
    ) or []
    return render_template('admin/aviones.html', aviones=aviones)

@app.route('/admin/aviones/nuevo', methods=['GET', 'POST'])
@login_required
@role_required(['Administrador'])
def nuevo_avion():
    if request.method == 'POST':
        matricula = request.form.get('matricula').upper()
        modelo_id = request.form.get('modelo_id')
        anio = request.form.get('anio_fabricacion')
        execute_query(
            "INSERT INTO aviones (matricula, modelo_id, anio_fabricacion) VALUES (%s, %s, %s)",
            (matricula, modelo_id, anio)
        )
        flash('✅ Avión registrado.', 'success')
        return redirect(url_for('admin_aviones'))
    
    modelos = execute_query("SELECT * FROM modelos_avion ORDER BY fabricante, modelo", fetchall=True) or []
    return render_template('admin/aviones_nuevo.html', modelos=modelos)

@app.route('/admin/aviones/estado', methods=['POST'])
@login_required
@role_required(['Administrador'])
def cambiar_estado_avion():
    matricula = request.form.get('matricula')
    estado = request.form.get('estado')
    execute_query("UPDATE aviones SET estado = %s WHERE matricula = %s", (estado, matricula))
    flash(f'Estado del avión {matricula} actualizado.', 'success')
    return redirect(url_for('admin_aviones'))

@app.route('/admin/empleados')
@login_required
@role_required(['Administrador'])
def admin_empleados():
    empleados = execute_query(
        """SELECT e.persona_id, e.codigo_empleado, e.cargo, e.numero_licencia,
                  e.fecha_contratacion, e.esta_activo,
                  p.nombres, p.apellidos, p.numero_documento, p.email
           FROM empleados e JOIN personas p ON e.persona_id = p.id
           ORDER BY p.apellidos""",
        fetchall=True
    ) or []
    return render_template('admin/empleados.html', empleados=empleados)

@app.route('/admin/empleados/nuevo', methods=['GET', 'POST'])
@login_required
@role_required(['Administrador'])
def nuevo_empleado():
    if request.method == 'POST':
        # Crear persona primero
        tipo_doc = request.form.get('tipo_documento')
        num_doc = request.form.get('numero_documento')
        nombres = request.form.get('nombres')
        apellidos = request.form.get('apellidos')
        email = request.form.get('email')
        telefono = request.form.get('telefono')
        fecha_nac = request.form.get('fecha_nacimiento') or None
        nacionalidad = request.form.get('nacionalidad', 'EC')
        genero = request.form.get('genero', 'M')
        
        execute_query(
            """INSERT INTO personas (tipo_documento, numero_documento, nombres, apellidos, email, telefono, fecha_nacimiento, nacionalidad, genero)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (tipo_doc, num_doc, nombres, apellidos, email, telefono, fecha_nac, nacionalidad, genero)
        )
        persona = execute_query(
            "SELECT id FROM personas WHERE tipo_documento = %s AND numero_documento = %s",
            (tipo_doc, num_doc), fetchone=True
        )
        
        # Comentario prueba

        if persona:
            codigo = request.form.get('codigo_empleado')
            cargo = request.form.get('cargo')
            licencia = request.form.get('numero_licencia') or None
            fecha_cont = request.form.get('fecha_contratacion')
            salario = request.form.get('salario', 0)
            
            execute_query(
                """INSERT INTO empleados (persona_id, codigo_empleado, cargo, numero_licencia, fecha_contratacion, salario)
                   VALUES (%s, %s, %s, %s, %s, %s)""",
                (persona['id'], codigo, cargo, licencia, fecha_cont, salario)
            )
            flash('✅ Empleado registrado.', 'success')
        else:
            flash('Error al crear persona.', 'danger')
        return redirect(url_for('admin_empleados'))
    
    paises = execute_query("SELECT codigo_iso, nombre FROM paises ORDER BY nombre", fetchall=True) or []
    return render_template('admin/empleados_nuevo.html', paises=paises)

if __name__ == '__main__':
    app.run(debug=True)
