from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PORT = 8000


class RenovaHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_POST(self):
        if self.path != '/api/tienda':
            self.send_error(404)
            return

        length = int(self.headers.get('Content-Length', 0))
        html = self.rfile.read(length)
        target = ROOT / 'Tienda.html'
        target.write_bytes(html)

        self.send_response(200)
        self.send_header('Content-Length', '0')
        self.end_headers()

    def log_message(self, format, *args):
        print(f'[{self.log_date_time_string()}] {format % args}')


if __name__ == '__main__':
    server = ThreadingHTTPServer(('127.0.0.1', PORT), RenovaHandler)
    print(f'Renova admin disponible en http://127.0.0.1:{PORT}/admin/')
    print('Presiona Ctrl+C para detener el servidor.')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nServidor detenido.')
    finally:
        server.server_close()
