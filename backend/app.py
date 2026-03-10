from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import sqlite3
import datetime

app = Flask(__name__)
CORS(app)  # Enable Cross-Origin Resource Sharing for Flutter web requests

DATABASE = 'shop_v2.db'

def get_db():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
def home():
    return jsonify({
        "status": "online",
        "message": "Super Business Shop API",
        "version": "v1",
        "timestamp": datetime.datetime.now().isoformat()
    })

@app.route('/api/sync', methods=['POST'])
def sync_data():
    """
    Endpoint for syncing data from the local Flutter SQLite to the cloud PostgreSQL
    Expected JSON payload: {"users": [...], "sales": [...], "customers": [...]}
    """
    data = request.json
    
    # Example logic (would be expanded based on full DB schema)
    # This prepares us for Render deployment sync!
    
    return jsonify({
        "status": "success",
        "synced_records": sum(len(records) for records in data.values()) if data else 0
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
