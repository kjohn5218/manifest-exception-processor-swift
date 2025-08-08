#!/usr/bin/env python3
"""
Flask web server that interfaces with the Swift Manifest Exception Processor
Provides a web UI for real PDF processing using the actual API
"""

from flask import Flask, render_template, request, jsonify, send_from_directory
import subprocess
import tempfile
import os
import json
import base64
from werkzeug.utils import secure_filename
from swift_bridge import SwiftProcessorBridge

app = Flask(__name__, template_folder='templates', static_folder='static')
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB limit

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Initialize Swift processor bridge
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
swift_bridge = SwiftProcessorBridge(PROJECT_ROOT)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/process', methods=['POST'])
def process_pdf():
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not file.filename.lower().endswith('.pdf'):
            return jsonify({'error': 'Only PDF files are supported'}), 400
        
        # Save uploaded file
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        # Get processing type
        process_type = request.form.get('processType', 'sync')
        
        # Call Swift processor using the bridge
        result = swift_bridge.process_pdf(filepath, process_type)
        
        # Clean up uploaded file
        os.remove(filepath)
        
        # Format result for web response
        if 'error' in result:
            return jsonify(result), 500
        else:
            return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/test')
def test_swift_connection():
    """Test endpoint to check Swift processor availability"""
    test_result = swift_bridge.test_connection()
    return jsonify(test_result)

def call_swift_processor(pdf_path, process_type):
    """
    Call the Swift command-line processor with the PDF file
    """
    try:
        # Create a temporary Swift script that processes the PDF
        swift_script = f'''
import Foundation

// Import the processor
// Note: This would need the actual Swift files in the path
// For demo, we'll simulate the API call structure

print("Processing PDF: {pdf_path}")
print("Process Type: {process_type}")

// This would be the actual Swift processor call:
// let processor = ManifestExceptionProcessor(...)
// let result = try await processor.process{process_type.title()}(pdfPath: "{pdf_path}", identifier: "WEB_{{Date().timeIntervalSince1970}}")

// For now, return a structured response
let response = """
{{
    "status": "success",
    "metadata": {{
        "identifier": "batch_{{Int(Date().timeIntervalSince1970)}}",
        "state": "finalized",
        "result": "success",
        "processedAt": "{{Date().ISO8601Format()}}"
    }},
    "manifest": {{
        "tripNumber": "{{Int.random(in: 1000000...9999999)}}",
        "manifestNumber": "MF-2024-{{String(format: "%03d", Int.random(in: 1...999))}}",
        "trailerNumber": "TR-{{Int.random(in: 1000...9999)}}",
        "expectedShipments": {{Int.random(in: 5...20)}},
        "actualShipments": {{Int.random(in: 5...20)}},
        "expectedUnits": {{Int.random(in: 10...50)}},
        "actualUnits": {{Int.random(in: 10...50)}}
    }},
    "processing_note": "Real API integration would happen here"
}}
"""
print(response)
'''
        
        # For now, return a simulated response since we need the full Swift environment
        # In production, this would call: swift run manifest-processor {pdf_path}
        
        import random
        from datetime import datetime
        
        # Generate realistic but random data based on the PDF
        response = {
            "status": "success",
            "metadata": {
                "identifier": f"batch_{int(datetime.now().timestamp())}",
                "state": "finalized",
                "result": "success",
                "processedAt": datetime.now().isoformat()
            },
            "manifest": {
                "tripNumber": str(random.randint(1000000, 9999999)),
                "manifestNumber": f"MF-2024-{random.randint(1, 999):03d}",
                "trailerNumber": f"TR-{random.randint(1000, 9999)}",
                "expectedShipments": random.randint(5, 20),
                "actualShipments": random.randint(5, 20),
                "expectedUnits": random.randint(10, 50),
                "actualUnits": random.randint(10, 50)
            },
            "summary": generate_random_exceptions(),
            "exceptions": generate_exception_details(),
            "note": f"Processed PDF: {os.path.basename(pdf_path)} ({process_type} mode)"
        }
        
        return response
        
    except Exception as e:
        return {"error": f"Processing failed: {str(e)}"}

def generate_random_exceptions():
    import random
    
    shortage_count = random.randint(0, 3)
    overage_count = random.randint(0, 2)
    damage_count = random.randint(0, 2)
    
    return {
        "shortages": shortage_count,
        "shortagePieces": shortage_count * random.randint(1, 3),
        "overages": overage_count,
        "overagePieces": overage_count * random.randint(1, 2),
        "damages": damage_count,
        "damagePieces": damage_count * random.randint(1, 2),
        "hasOSD": shortage_count > 0 or overage_count > 0 or damage_count > 0
    }

def generate_exception_details():
    import random
    
    exception_types = ['shortage', 'overage', 'damage']
    descriptions = [
        'AUTOMOTIVE PARTS', 'ELECTRONICS', 'FURNITURE', 'MEDICAL SUPPLIES',
        'CONSTRUCTION TOOLS', 'OFFICE SUPPLIES', 'FOOD PRODUCTS', 'GLASS PRODUCTS'
    ]
    
    exceptions = []
    num_exceptions = random.randint(0, 4)
    
    for i in range(num_exceptions):
        exc_type = random.choice(exception_types)
        expected = random.randint(1, 10)
        
        if exc_type == 'shortage':
            actual = expected - random.randint(1, min(3, expected))
        elif exc_type == 'overage':
            actual = expected + random.randint(1, 3)
        else:  # damage
            actual = expected - random.randint(1, min(2, expected))
            
        exceptions.append({
            "proNumber": f"{chr(65 + i)}{random.randint(1000000, 9999999)}",
            "type": exc_type,
            "description": random.choice(descriptions),
            "expected": expected,
            "actual": actual,
            "weight": random.randint(50, 2000),
            "notes": generate_exception_note(exc_type),
            "markups": generate_markups(exc_type)
        })
    
    return exceptions

def generate_exception_note(exc_type):
    notes = {
        'shortage': ['Missing boxes', 'Pallet not found', 'Items not loaded', 'Short count verified'],
        'overage': ['Extra pallets found', 'Additional items discovered', 'Surplus shipment'],
        'damage': ['Water damage', 'Torn packaging', 'Broken items', 'Crushed boxes']
    }
    import random
    return random.choice(notes.get(exc_type, ['Processing note']))

def generate_markups(exc_type):
    markups = {
        'shortage': [['MISSING'], ['SHORT'], ['-1', 'NOT FOUND'], ['SHORTAGE']],
        'overage': [['EXTRA'], ['+1'], ['SURPLUS'], ['ADDITIONAL']],
        'damage': [['DAMAGED'], ['BROKEN'], ['WET'], ['TORN', 'UNUSABLE']]
    }
    import random
    return random.choice(markups.get(exc_type, [['NOTED']]))

if __name__ == '__main__':
    print("🚀 Starting Manifest Exception Processor Web Server")
    print("📡 Server will be available at: http://localhost:8080")
    print("📄 Upload PDFs for real processing with the Swift backend")
    app.run(debug=True, host='0.0.0.0', port=8080)