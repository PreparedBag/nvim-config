#!/usr/bin/env python3

from flask import Flask, render_template, send_from_directory
import sys
import os

template_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
starting_file = sys.argv[2] if len(sys.argv) > 2 else 'index.html'
static_dir = os.path.join(template_dir, '../static')

app = Flask(
    __name__, 
    template_folder=template_dir, 
    static_folder=static_dir,
    static_url_path='/static'
)
app.config['TEMPLATES_AUTO_RELOAD'] = True
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

@app.route('/')
def index():
    return render_template(starting_file)

@app.route('/' + starting_file)
def serve_starting_file():
    return render_template(starting_file)

@app.route('/<path:filename>')
def serve_template(filename):
    print(f"[REQUEST] /{filename}")
    if filename.endswith('.html'):
        return render_template(filename)
    return send_from_directory(template_dir, filename)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=True)
