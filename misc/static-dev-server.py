#!/usr/bin/env python3
import sys
import os
import time
import queue
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

root = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
start = sys.argv[2] if len(sys.argv) > 2 else 'index.html'
port = int(sys.argv[3]) if len(sys.argv) > 3 else 3000

clients = []
clients_lock = threading.Lock()

RELOAD_SNIPPET = (
    b"<script>"
    b"new EventSource('/__livereload').onmessage=function(e){"
    b"if(e.data==='reload')location.reload();};"
    b"</script>"
)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=root, **kwargs)

    def log_message(self, *args):
        pass

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def do_GET(self):
        if self.path == '/__livereload':
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.end_headers()
            q = queue.Queue()
            with clients_lock:
                clients.append(q)
            try:
                while True:
                    msg = q.get()
                    self.wfile.write(b'data: ' + msg.encode() + b'\n\n')
                    self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            finally:
                with clients_lock:
                    if q in clients:
                        clients.remove(q)
            return

        if self.path in ('/', ''):
            self.path = '/' + start

        clean = self.path.split('?', 1)[0]
        fs_path = os.path.join(root, clean.lstrip('/'))

        if clean.endswith('.html') and os.path.isfile(fs_path):
            with open(fs_path, 'rb') as f:
                body = f.read()
            if b'</body>' in body:
                body = body.replace(b'</body>', RELOAD_SNIPPET + b'</body>', 1)
            else:
                body += RELOAD_SNIPPET
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        return super().do_GET()


def watch():
    mtimes = {}
    first = True
    while True:
        changed = False
        for dirpath, dirs, files in os.walk(root):
            for name in files:
                fp = os.path.join(dirpath, name)
                try:
                    m = os.path.getmtime(fp)
                except OSError:
                    continue
                if fp not in mtimes:
                    mtimes[fp] = m
                elif mtimes[fp] != m:
                    mtimes[fp] = m
                    changed = True
        if changed and not first:
            with clients_lock:
                for q in list(clients):
                    q.put('reload')
        first = False
        time.sleep(0.3)


threading.Thread(target=watch, daemon=True).start()
server = ThreadingHTTPServer(('127.0.0.1', port), Handler)
print(f"static live server on http://localhost:{port} (root={root}, start={start})")
server.serve_forever()
