#!/usr/bin/env python3
"""
Quick test to see if Swift processor integration works
"""
import subprocess
import tempfile

# Create a simple PDF
with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as tmp:
    tmp.write(b"""TEST MANIFEST EXCEPTION DOCUMENT
PRO123456 - SHORTAGE - 5 PIECES MISSING
PRO789012 - DAMAGE - WATER DAMAGE  
Trip: 1234567, Manifest: MF-2024-001""")
    pdf_path = tmp.name

print(f"📄 Test PDF: {pdf_path}")

# Test Swift processor directly
print("🔧 Testing Swift processor directly...")
result = subprocess.run(
    ['swift', 'run', 'manifest-processor', pdf_path],
    capture_output=True,
    text=True,
    timeout=30,
    cwd='/Users/kevinjohn/projects/unloadreader'
)

print(f"Return code: {result.returncode}")
print(f"Stdout length: {len(result.stdout)}")
print(f"Stderr length: {len(result.stderr)}")

if result.returncode == 0:
    print("✅ Swift processor succeeded!")
    
    # Look for JSON output
    lines = result.stdout.split('\n')
    json_start = -1
    json_end = -1
    
    for i, line in enumerate(lines):
        if "--- JSON OUTPUT START ---" in line:
            json_start = i + 1
        elif "--- JSON OUTPUT END ---" in line:
            json_end = i
            break
    
    if json_start != -1 and json_end != -1:
        json_lines = lines[json_start:json_end]
        json_content = '\n'.join(json_lines)
        print("🎯 Found JSON output:")
        print(json_content[:200] + "...")
        
        # Try parsing
        try:
            import json
            data = json.loads(json_content)
            print(f"📊 Parsed data - source: {data.get('source')}")
        except Exception as e:
            print(f"❌ JSON parsing failed: {e}")
    else:
        print("⚠️  No JSON markers found")
        print("📝 Raw output:")
        print(result.stdout[:500] + "...")
else:
    print("❌ Swift processor failed")
    print(f"Error: {result.stderr}")

# Cleanup
import os
os.unlink(pdf_path)