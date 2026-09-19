from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class RenovaHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        if self.path.rstrip('/') == '/admin':
            self.path = '/admin/Admin.html'
        super().do_GET()

    def do_POST(self):
        rutas = {'/api/tienda': ROOT / 'Tienda.html', '/api/inicio': ROOT / 'index.html'}
        destino = rutas.get(self.path)
        if destino is None:
            self.send_error(404, 'Ruta no encontrada')
            return

        length = int(self.headers.get('Content-Length', '0'))
        contenido = self.rfile.read(length)
        try:
            destino.write_bytes(contenido)
        except OSError as error:
            self.send_error(500, f'No se pudo guardar el archivo: {error}')
            return

        self.send_response(204)
        self.end_headers()


if __name__ == '__main__':
    servidor = ThreadingHTTPServer(('127.0.0.1', 8000), RenovaHandler)
    print('Renova local: http://127.0.0.1:8000/admin/')
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        servidor.server_close()
