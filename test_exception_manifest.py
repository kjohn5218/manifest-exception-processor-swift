#!/usr/bin/env python3
"""
Test script to upload a PDF with "exception" in the name to trigger processing
"""

import requests
import tempfile
import os

def create_exception_pdf():
    """Create a PDF with 'exception' in filename to trigger exception generation"""
    with tempfile.NamedTemporaryFile(delete=False, suffix='_exception_manifest.pdf') as tmp:
        tmp.write(b"""TEST MANIFEST EXCEPTION DOCUMENT
PRO123456 - SHORTAGE - 5 PIECES MISSING
PRO789012 - DAMAGE - WATER DAMAGE  
Trip: 1234567, Manifest: MF-2024-001""")
        return tmp.name

def test_upload():
    """Test uploading exception PDF to the web app"""
    pdf_path = create_exception_pdf()
    filename = os.path.basename(pdf_path)
    
    try:
        print(f"📄 Created exception test PDF: {filename}")
        print("🔄 Uploading to web app...")
        
        with open(pdf_path, 'rb') as pdf_file:
            files = {'file': (filename, pdf_file, 'application/pdf')}
            response = requests.post('http://localhost:8182/process', files=files, timeout=60)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Upload successful!")
            print(f"📝 Note: {result.get('note', 'No note')}")
            print(f"🔍 Source: {result.get('source', 'Unknown')}")
            print(f"📊 Exceptions: {len(result.get('exceptions', []))}")
            print(f"🚛 Trip: {result.get('manifest', {}).get('tripNumber', 'Unknown')}")
            
            if result.get('source') == 'local_swift_processor':
                print("🎉 Real Swift processor working!")
            elif 'demo mode' in result.get('note', '').lower():
                print("⚠️  Still getting demo data")
            else:
                print("❓ Unknown processing mode")
                
        else:
            print(f"❌ Upload failed: {response.status_code}")
            print(f"📝 Response: {response.text}")
            
    finally:
        # Cleanup
        if os.path.exists(pdf_path):
            os.unlink(pdf_path)

if __name__ == "__main__":
    test_upload()