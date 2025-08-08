#!/usr/bin/env python3
"""
Test the Swift processor integration directly
"""

import tempfile
import subprocess
import os
import json
from datetime import datetime

def try_swift_processor(pdf_path, filename):
    """
    Try to process PDF with the real Swift Manifest Exception Processor
    Returns processed result or None if Swift processor unavailable
    """
    try:
        print(f"🔧 Attempting to process {filename} with Swift processor...")
        print(f"📁 PDF path: {pdf_path}")
        print(f"📂 Working directory: /Users/kevinjohn/projects/unloadreader")
        
        # Try to call the Swift processor
        result = subprocess.run(
            ['swift', 'run', 'manifest-processor', pdf_path],
            capture_output=True,
            text=True,
            timeout=120,
            cwd='/Users/kevinjohn/projects/unloadreader'
        )
        
        print(f"🔍 Swift processor return code: {result.returncode}")
        print(f"📝 Swift processor stdout: {result.stdout[:200]}...")
        print(f"⚠️  Swift processor stderr: {result.stderr[:200]}...")
        
        if result.returncode == 0:
            print(f"✅ Swift processor succeeded for {filename}")
            return parse_swift_output(result.stdout, filename)
        else:
            print(f"⚠️  Swift processor failed: {result.stderr}")
            return None
            
    except subprocess.TimeoutExpired:
        print(f"⏱️  Swift processor timeout for {filename}")
        return None
    except FileNotFoundError:
        print(f"❌ Swift processor not found - ensure 'swift run manifest-processor' works")
        return None
    except Exception as e:
        print(f"❌ Swift processor error: {e}")
        return None

def parse_swift_output(output, filename):
    """Parse output from the Swift processor into web-friendly format"""
    try:
        print(f"📄 Parsing Swift output for {filename}")
        lines = output.strip().split('\n')
        
        # Look for JSON output between markers first
        json_start = -1
        json_end = -1
        
        for i, line in enumerate(lines):
            if "--- JSON OUTPUT START ---" in line:
                json_start = i + 1
            elif "--- JSON OUTPUT END ---" in line:
                json_end = i
                break
        
        if json_start != -1 and json_end != -1:
            # Extract JSON content between markers
            json_lines = lines[json_start:json_end]
            json_content = '\n'.join(json_lines)
            
            try:
                swift_data = json.loads(json_content)
                print(f"🎯 Found structured JSON output from local Swift processor")
                
                # The local Swift processor already outputs in the correct format
                swift_data['timestamp'] = datetime.now().isoformat()
                swift_data['fileSize'] = 0  # We don't have file size from Swift output
                return swift_data
                
            except json.JSONDecodeError as e:
                print(f"⚠️  JSON parsing error: {e}")
        
        print("❌ No valid JSON found in Swift output")
        return None
        
    except Exception as e:
        print(f"❌ Error parsing Swift output: {e}")
        return None

# Test the integration
if __name__ == "__main__":
    # Create test PDF
    with tempfile.NamedTemporaryFile(delete=False, suffix='_exception_manifest.pdf') as tmp:
        tmp.write(b"""TEST MANIFEST EXCEPTION DOCUMENT
PRO123456 - SHORTAGE - 5 PIECES MISSING  
PRO789012 - DAMAGE - WATER DAMAGE
Trip: 1234567, Manifest: MF-2024-001""")
        pdf_path = tmp.name
        filename = os.path.basename(pdf_path)
    
    print("🧪 Testing Swift processor integration directly")
    print("=" * 60)
    
    try:
        result = try_swift_processor(pdf_path, filename)
        
        if result:
            print("\n✅ Integration successful!")
            print(f"🔍 Source: {result.get('source')}")
            print(f"📝 Note: {result.get('note')}")
            print(f"📊 Exceptions: {len(result.get('exceptions', []))}")
            print(f"🚛 Trip: {result.get('manifest', {}).get('tripNumber')}")
            
            if result.get('source') == 'local_swift_processor':
                print("🎉 Perfect! Local Swift processor integration working")
        else:
            print("\n❌ Integration failed")
            print("The Swift processor is not returning valid results")
            
    finally:
        # Cleanup
        if os.path.exists(pdf_path):
            os.unlink(pdf_path)