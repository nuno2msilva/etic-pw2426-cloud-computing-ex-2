from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import os

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'postgres-service'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'k8s_app'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'secretpassword')
}

def get_db_connection():
    """Get database connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.Error:
        return None

def init_database():
    """Initialize database with required tables"""
    conn = get_db_connection()
    if conn:
        with conn.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    message TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
        conn.commit()
        conn.close()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({'status': 'healthy'})
    else:
        return jsonify({'status': 'unhealthy'}), 503

@app.route('/info', methods=['GET'])
def get_info():
    """Get environment and cluster info"""
    import socket
    return jsonify({
        'hostname': socket.gethostname(),
        'pod_ip': os.getenv('POD_IP', 'unknown'),
        'node_name': os.getenv('NODE_NAME', 'unknown')
    })

@app.route('/users', methods=['GET'])
def get_users():
    """Get all users from database"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    with conn.cursor(cursor_factory=RealDictCursor) as cursor:
        cursor.execute("SELECT * FROM users ORDER BY created_at DESC")
        users = cursor.fetchall()
    
    conn.close()
    
    # Convert to list of dicts for JSON serialization
    users_list = []
    for user in users:
        user_dict = dict(user)
        if user_dict.get('created_at'):
            user_dict['created_at'] = user_dict['created_at'].isoformat()
        users_list.append(user_dict)
    
    return jsonify(users_list)

@app.route('/users', methods=['POST'])
def create_user():
    """Create a new user"""
    data = request.get_json()
    
    if not data or 'name' not in data or 'message' not in data:
        return jsonify({'error': 'Name and message are required'}), 400
    
    name = data['name'].strip()
    message = data['message'].strip()
    
    if not name or not message:
        return jsonify({'error': 'Name and message cannot be empty'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    with conn.cursor(cursor_factory=RealDictCursor) as cursor:
        cursor.execute(
            "INSERT INTO users (name, message) VALUES (%s, %s) RETURNING id, created_at",
            (name, message)
        )
        result = cursor.fetchone()
    
    conn.commit()
    conn.close()
    
    return jsonify({
        'id': result['id'],
        'name': name,
        'message': message,
        'created_at': result['created_at'].isoformat()
    }), 201

@app.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Delete a user by ID"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    with conn.cursor() as cursor:
        cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
        deleted_count = cursor.rowcount
    
    conn.commit()
    conn.close()
    
    if deleted_count == 0:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify({'message': 'User deleted successfully'}), 200

if __name__ == '__main__':
    init_database()
    app.run(host='0.0.0.0', port=8080, debug=False)

# Initialize database when module loads (for gunicorn)
init_database()