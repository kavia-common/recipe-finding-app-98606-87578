import os
from pathlib import Path
from flask import Flask, jsonify, request
from werkzeug.utils import secure_filename
from dotenv import load_dotenv
load_dotenv()
_env_ws = os.environ.get('BACKENDAPI_WORKSPACE')
BASE = Path(_env_ws) if _env_ws else Path(__file__).resolve().parent
_upload_env = os.environ.get('UPLOAD_DIR')
if _upload_env:
    UPLOAD_DIR = Path(_upload_env)
    if not UPLOAD_DIR.is_absolute():
        UPLOAD_DIR = (BASE / UPLOAD_DIR).resolve()
else:
    UPLOAD_DIR = (BASE / 'uploads').resolve()
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app = Flask(__name__)
@app.route('/health')
def health():
    return jsonify({'status':'ok'})
@app.route('/upload', methods=['POST'])
def upload():
    if 'file' not in request.files:
        return jsonify({'error':'no file'}), 400
    f = request.files['file']
    filename = secure_filename(f.filename)
    if not filename:
        return jsonify({'error':'invalid filename'}), 400
    dest = UPLOAD_DIR / filename
    f.save(str(dest))
    return jsonify({'saved': str(dest)})
if __name__ == '__main__':
    app.run(host='127.0.0.1', port=int(os.environ.get('PORT', 5000)), debug=False, use_reloader=False)
