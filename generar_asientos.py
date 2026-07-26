import os
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
    cursor = conn.cursor(dictionary=True)

    # Buscar vuelos que no tengan asientos generados
    cursor.execute("""
        SELECT v.id, v.avion_matricula, a.modelo_id 
        FROM vuelos v
        JOIN aviones a ON v.avion_matricula = a.matricula
        WHERE v.id NOT IN (SELECT DISTINCT vuelo_id FROM asientos_vuelo)
    """)
    vuelos = cursor.fetchall()
    
    asientos_creados = 0
    for vuelo in vuelos:
        # Obtener configuracion del modelo de avion
        cursor.execute("SELECT id FROM configuracion_asientos WHERE modelo_id = %s", (vuelo['modelo_id'],))
        configs = cursor.fetchall()
        
        # Insertar asientos para el vuelo
        for cfg in configs:
            cursor.execute("""
                INSERT INTO asientos_vuelo (vuelo_id, configuracion_asiento_id, estado)
                VALUES (%s, %s, 'DISPONIBLE')
            """, (vuelo['id'], cfg['id']))
            asientos_creados += 1
            
    conn.commit()
    cursor.close()
    conn.close()
    print(f"Éxito: Se crearon {asientos_creados} asientos para los vuelos.")
except Exception as e:
    print(f"Error: {e}")
