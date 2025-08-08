#!/usr/bin/env python3
"""
Test script to upload a PDF to the web app and see real processing
"""

import requests
import tempfile
import os

def create_sample_pdf():
    """Create a simple PDF for testing"""
    try:
        # Try to create a minimal PDF using reportlab if available
        from reportlab.pdfgen import canvas
        from reportlab.lib.pagesizes import letter
        
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as tmp:
            c = canvas.Canvas(tmp.name, pagesize=letter)
            c.drawString(100, 750, "TEST MANIFEST EXCEPTION DOCUMENT")
            c.drawString(100, 700, "PRO123456 - SHORTAGE - 5 PIECES MISSING")
            c.drawString(100, 650, "PRO789012 - DAMAGE - WATER DAMAGE")
            c.drawString(100, 600, "Trip: 1234567, Manifest: MF-2024-001")
            c.save()
            return tmp.name
    except ImportError:
        print("📦 reportlab not available, creating text file as PDF")
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as tmp:
            tmp.write(b"""TEST MANIFEST EXCEPTION DOCUMENT
PRO123456 - SHORTAGE - 5 PIECES MISSING
PRO789012 - DAMAGE - WATER DAMAGE  
Trip: 1234567, Manifest: MF-2024-001""")
            return tmp.name

def test_upload():
    """Test uploading PDF to the web app"""
    pdf_path = create_sample_pdf()
    
    try:
        print(f"📄 Created test PDF: {pdf_path}")
        print("🔄 Uploading to web app...")
        
        with open(pdf_path, 'rb') as pdf_file:
            files = {'file': ('test_manifest.pdf', pdf_file, 'application/pdf')}
            response = requests.post('http://localhost:8182/process', files=files, timeout=60)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Upload successful!")
            print(f"📝 Note: {result.get('note', 'No note')}")
            print(f"🔍 Source: {result.get('source', 'Unknown')}")
            print(f"📊 Exceptions: {len(result.get('exceptions', []))}")
            
            if 'demo mode' in result.get('note', '').lower():
                print("⚠️  Still getting demo data - Swift processor integration issue")
            else:
                print("🎉 Real processing working!")
                
        else:
            print(f"❌ Upload failed: {response.status_code}")
            print(f"📝 Response: {response.text}")
            
    finally:
        # Cleanup
        if os.path.exists(pdf_path):
            os.unlink(pdf_path)

if __name__ == "__main__":
    test_upload()