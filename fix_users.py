import os
import hashlib
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

dbconfig = {
    "host": os.getenv('MYSQL_HOST', 'localhost'),
    "user": os.getenv('MYSQL_USER', 'root'),
    "password": os.getenv('MYSQL_PASSWORD', ''),
    "database": os.getenv('MYSQL_DATABASE', 'pegaso_airlines'),
}

try:
    conn = mysql.connector.connect(**dbconfig)
    cursor = conn.cursor()

    # Password hashes
    hash_agente = hashlib.sha256(b'agente').hexdigest()
    hash_supervisor = hashlib.sha256(b'supervisor').hexdigest()

    # Update agente password
    cursor.execute("UPDATE usuarios SET hash_contrasena = %s WHERE username = 'agente'", (hash_agente,))
    
    # Check if supervisor exists
    cursor.execute("SELECT id FROM usuarios WHERE username = 'supervisor'")
    if not cursor.fetchone():
        # Insert a persona for supervisor if needed, or reuse one
        # Let's use persona_id 7 (which is EMP005 - SOBRECARGO, wait, let's use an unused one, e.g. persona 3 or 4 are passengers)
        # We need an employee for supervisor. Let's use persona 5 or something, or just create a new persona
        cursor.execute("INSERT INTO personas (tipo_documento, numero_documento, nombres, apellidos, email, nacionalidad, genero) VALUES ('CEDULA', '9999999999', 'Super', 'Visor', 'super@test.com', 'EC', 'M')")
        new_persona_id = cursor.lastrowid
        # Insert into usuarios
        # rol_id 2 is Supervisor de Vuelos
        cursor.execute("INSERT INTO usuarios (persona_id, username, hash_contrasena, rol_id) VALUES (%s, 'supervisor', %s, 2)", (new_persona_id, hash_supervisor))
    
    conn.commit()
    cursor.close()
    conn.close()
    print("Usuarios actualizados correctamente.")
except Exception as e:
    print(f"Error: {e}")
