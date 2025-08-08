#!/usr/bin/env python3
"""
Minimal test server to verify web access works
"""

from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return '''
    <html>
    <head><title>Test Server</title></head>
    <body>
        <h1>🎉 Web Server Works!</h1>
        <p>Your Flask web application is running successfully.</p>
        <p>This proves the web app infrastructure is working.</p>
        <a href="/status">Check Status</a>
    </body>
    </html>
    '''

@app.route('/status')
def status():
    return {'status': 'working', 'message': 'Flask server is operational'}

if __name__ == '__main__':
    print("🧪 Starting Test Server")
    print("🌐 Open: http://localhost:9000")
    app.run(debug=True, host='127.0.0.1', port=9000)