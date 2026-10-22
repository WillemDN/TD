#!/usr/bin/env python3
"""Serve the Godot web build (game/build/web) over plain HTTP, for the tailnet or localhost.

Usage: python3 server-mac/serve_web.py [--bind 100.x.y.z] [--port 8060] [--dir game/build/web]
Phones in the tailnet open http://<mac tailscale ip or name>:8060. Responses are never cached, so a new build shows up
on reload. Real hosting with HTTPS comes later through `tailscale serve` (docs/PLAN.md section 5).
"""
import argparse
import functools
import http.server
import os


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, '.wasm': 'application/wasm',
                      '.pck': 'application/octet-stream', '.apk': 'application/vnd.android.package-archive', '.js': 'text/javascript'}

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def log_message(self, fmt, *args):
        pass


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser()
    ap.add_argument('--bind', default='127.0.0.1')
    ap.add_argument('--port', type=int, default=8060)
    ap.add_argument('--dir', default=os.path.join(root, 'game/build/web'))
    a = ap.parse_args()
    handler = functools.partial(Handler, directory=a.dir)
    with http.server.ThreadingHTTPServer((a.bind, a.port), handler) as srv:
        print(f'serving {a.dir} on http://{a.bind}:{a.port}', flush=True)
        srv.serve_forever()


if __name__ == '__main__':
    main()
