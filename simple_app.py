#!/usr/bin/env python3
"""
Simple standalone web application for Manifest Exception Processor
No external templates - everything embedded
"""

from flask import Flask, request, jsonify
import os
import tempfile
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB

@app.route('/')
def index():
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manifest Exception Processor</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin: 0 0 10px 0;
            font-weight: 700;
        }
        .content {
            padding: 40px;
        }
        .upload-area {
            border: 3px dashed #e0e6ed;
            border-radius: 15px;
            padding: 60px 40px;
            text-align: center;
            margin-bottom: 30px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        .upload-area:hover {
            border-color: #4facfe;
            background-color: #f8faff;
        }
        .upload-text {
            font-size: 1.3em;
            color: #4a5568;
            margin-bottom: 10px;
            font-weight: 600;
        }
        .file-input {
            display: none;
        }
        .process-btn {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            border: none;
            padding: 18px 40px;
            font-size: 1.2em;
            font-weight: 600;
            border-radius: 12px;
            cursor: pointer;
            width: 100%;
            margin-bottom: 20px;
        }
        .process-btn:disabled {
            background: #cbd5e0;
            cursor: not-allowed;
        }
        .status {
            background: #f7fafc;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            display: none;
        }
        .status.processing {
            background: #fff5cd;
            color: #744210;
            display: block;
        }
        .status.success {
            background: #d4f4dd;
            color: #22543d;
            display: block;
        }
        .status.error {
            background: #fed7d7;
            color: #822727;
            display: block;
        }
        .results {
            background: #f8fafc;
            border-radius: 15px;
            padding: 30px;
            margin-top: 20px;
            display: none;
        }
        .spinner {
            border: 3px solid #e2e8f0;
            border-top: 3px solid #4facfe;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            animation: spin 1s linear infinite;
            display: inline-block;
            margin-right: 10px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Manifest Exception Processor</h1>
            <p>AI-powered OS&D extraction from PDFs</p>
        </div>
        <div class="content">
            <div class="upload-area" onclick="document.getElementById('fileInput').click()">
                <div style="font-size: 4em; margin-bottom: 20px;">📄</div>
                <div class="upload-text">Select PDF File</div>
                <div>Click here to upload your manifest exception PDF</div>
                <input type="file" id="fileInput" class="file-input" accept=".pdf">
            </div>
            
            <button class="process-btn" id="processBtn" disabled onclick="processFile()">
                Process Document
            </button>
            
            <div class="status" id="status"></div>
            <div class="results" id="results"></div>
        </div>
    </div>

    <script>
        let selectedFile = null;

        document.getElementById('fileInput').addEventListener('change', function(e) {
            selectedFile = e.target.files[0];
            if (selectedFile && selectedFile.type === 'application/pdf') {
                document.querySelector('.upload-text').textContent = 'Selected: ' + selectedFile.name;
                document.getElementById('processBtn').disabled = false;
            }
        });

        async function processFile() {
            if (!selectedFile) return;
            
            const statusEl = document.getElementById('status');
            const resultsEl = document.getElementById('results');
            
            statusEl.className = 'status processing';
            statusEl.innerHTML = '<div class="spinner"></div>Processing ' + selectedFile.name + '...';
            resultsEl.style.display = 'none';
            
            const formData = new FormData();
            formData.append('file', selectedFile);
            
            try {
                const response = await fetch('/process', {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (response.ok) {
                    statusEl.className = 'status success';
                    statusEl.innerHTML = '✅ Processing complete!';
                    
                    resultsEl.innerHTML = '<h3>📊 Results</h3><pre>' + JSON.stringify(result, null, 2) + '</pre>';
                    resultsEl.style.display = 'block';
                } else {
                    throw new Error(result.error || 'Processing failed');
                }
            } catch (error) {
                statusEl.className = 'status error';
                statusEl.innerHTML = '❌ Error: ' + error.message;
            }
        }
    </script>
</body>
</html>
    '''

@app.route('/process', methods=['POST'])
def process_pdf():
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not file.filename.lower().endswith('.pdf'):
            return jsonify({'error': 'Only PDF files supported'}), 400
        
        # Save temporarily
        filename = secure_filename(file.filename)
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
            file.save(temp_file.name)
            
            # Process with Swift (for now, return demo data)
            result = {
                'status': 'success',
                'filename': filename,
                'message': 'PDF processed successfully with Swift backend',
                'manifest': {
                    'tripNumber': '12345',
                    'manifestNumber': 'MF-001',
                    'expectedShipments': 10,
                    'actualShipments': 9
                },
                'exceptions': [
                    {
                        'proNumber': 'ABC123',
                        'type': 'shortage',
                        'description': 'Missing package'
                    }
                ],
                'note': f'Real processing would connect to Swift processor with file: {filename}'
            }
            
            # Clean up
            os.unlink(temp_file.name)
            return jsonify(result)
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'app': 'Manifest Exception Processor'})

if __name__ == '__main__':
    print("🚀 Starting Simple Web App")
    print("📡 Open: http://localhost:8080")
    app.run(debug=True, host='0.0.0.0', port=8080)