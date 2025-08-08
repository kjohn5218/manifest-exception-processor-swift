#!/usr/bin/env python3
"""
Bridge between Python web server and Swift Manifest Processor
This script calls the actual Swift processor and returns real results
"""

import subprocess
import json
import tempfile
import os
from pathlib import Path

class SwiftProcessorBridge:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.swift_executable = self.project_root / ".build" / "debug" / "manifest-processor"
        
    def process_pdf(self, pdf_path, process_type="sync"):
        """
        Process a PDF using the Swift Manifest Exception Processor
        
        Args:
            pdf_path (str): Path to the PDF file
            process_type (str): 'sync' or 'async'
            
        Returns:
            dict: Processing results or error information
        """
        try:
            # Build the Swift package if needed
            if not self.swift_executable.exists():
                self._build_swift_package()
            
            # Prepare command
            cmd = [str(self.swift_executable), pdf_path]
            if process_type == "async":
                cmd.append("--async")
            
            # Execute Swift processor
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300,  # 5 minute timeout
                cwd=self.project_root
            )
            
            if result.returncode == 0:
                # Parse Swift output
                return self._parse_swift_output(result.stdout)
            else:
                return {
                    "error": f"Swift processor failed: {result.stderr}",
                    "stdout": result.stdout,
                    "returncode": result.returncode
                }
                
        except subprocess.TimeoutExpired:
            return {"error": "Processing timeout - PDF took too long to process"}
        except Exception as e:
            return {"error": f"Bridge error: {str(e)}"}
    
    def _build_swift_package(self):
        """Build the Swift package"""
        try:
            print("🔨 Building Swift package...")
            result = subprocess.run(
                ["swift", "build"],
                capture_output=True,
                text=True,
                cwd=self.project_root
            )
            
            if result.returncode != 0:
                raise Exception(f"Swift build failed: {result.stderr}")
                
            print("✅ Swift package built successfully")
            
        except Exception as e:
            print(f"❌ Build failed: {e}")
            raise
    
    def _parse_swift_output(self, swift_output):
        """
        Parse the output from the Swift processor
        Expected format: JSON output from the Swift processor
        """
        try:
            # Look for JSON in the output
            lines = swift_output.strip().split('\n')
            
            # Find JSON output (usually the last substantial line)
            json_line = None
            for line in reversed(lines):
                line = line.strip()
                if line.startswith('{') and line.endswith('}'):
                    json_line = line
                    break
            
            if json_line:
                return json.loads(json_line)
            else:
                # If no JSON found, create a structured response from text output
                return {
                    "status": "success",
                    "output": swift_output,
                    "parsed": self._parse_text_output(swift_output)
                }
                
        except json.JSONDecodeError as e:
            return {
                "error": f"Failed to parse Swift output as JSON: {e}",
                "raw_output": swift_output
            }
    
    def _parse_text_output(self, output):
        """
        Parse text output from Swift processor into structured data
        This is a fallback when JSON parsing fails
        """
        parsed = {
            "manifest": {},
            "summary": {},
            "exceptions": [],
            "raw_output": output
        }
        
        lines = output.split('\n')
        current_section = None
        
        for line in lines:
            line = line.strip()
            
            # Skip empty lines and separators
            if not line or line.startswith('=') or line.startswith('-'):
                continue
            
            # Detect sections
            if 'MANIFEST INFORMATION' in line.upper():
                current_section = 'manifest'
            elif 'EXCEPTION SUMMARY' in line.upper():
                current_section = 'summary'
            elif 'EXCEPTION DETAILS' in line.upper():
                current_section = 'exceptions'
            
            # Parse data based on section
            if ':' in line and current_section:
                key, value = line.split(':', 1)
                key = key.strip().lower().replace(' ', '_')
                value = value.strip()
                
                if current_section in ['manifest', 'summary']:
                    # Extract numbers from value
                    import re
                    numbers = re.findall(r'\d+', value)
                    if numbers:
                        parsed[current_section][key] = int(numbers[0])
                    else:
                        parsed[current_section][key] = value
        
        return parsed

    def test_connection(self):
        """Test if the Swift processor is accessible"""
        try:
            # Try to build and run a simple test
            result = subprocess.run(
                ["swift", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            return {
                "swift_available": result.returncode == 0,
                "swift_version": result.stdout.strip() if result.returncode == 0 else None,
                "project_root": str(self.project_root),
                "executable_exists": self.swift_executable.exists()
            }
            
        except Exception as e:
            return {
                "swift_available": False,
                "error": str(e)
            }

# Example usage
if __name__ == "__main__":
    # Test the bridge
    bridge = SwiftProcessorBridge("/Users/kevinjohn/projects/unloadreader")
    
    print("🧪 Testing Swift Processor Bridge")
    print("=" * 40)
    
    # Test connection
    connection_test = bridge.test_connection()
    print(f"Swift Available: {connection_test['swift_available']}")
    if connection_test.get('swift_version'):
        print(f"Swift Version: {connection_test['swift_version']}")
    
    # If you have a test PDF, uncomment this:
    # result = bridge.process_pdf("path/to/test.pdf")
    # print(json.dumps(result, indent=2))