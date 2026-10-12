#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fake dntshop.com server - PoC kiem chung diem yeu license QLTK.exe
==================================================================
Ap dung cho: Tool Check Info (product_id = 8, Ver 0.1.4)
Server la ban universal co CATCH-ALL:
  moi POST ma body co chu "license_key" deu duoc tra license hop le,
  BAT KE path (dung cho cac build QLTK moi khong con chua chuoi
  /api/verify_license.php dang text). Path that duoc ghi vao server.log
  (dong "CATCH-ALL LICENSE HIT").

Chi ap dung tren may cua ban, cho muc dich kiem tra bao mat noi bo.
"""
import json
import os
import re
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

def _log(msg):
    try:
        print(msg, flush=True)
    except Exception:
        pass
    try:
        base = os.path.dirname(os.path.abspath(sys.executable)) if getattr(sys, "frozen", False) else os.path.dirname(os.path.abspath(__file__))
        with open(os.path.join(base, "server.log"), "a", encoding="utf-8") as f:
            f.write(msg + "\n")
    except Exception:
        pass

# license_key client gui co dang TOOL{productId}-XXXX-... -> server tu tra dung product_id
DEFAULT_PRODUCT_ID = 8  # Tool Check Info; GSM Pro = 34, Up Cskb = 29, Mo Cskb = 36, Check Thong Bao = 12

def product_id_from_body(body):
    m = re.search(r"TOOL(\d+)-", body or "")
    return int(m.group(1)) if m else DEFAULT_PRODUCT_ID

def license_ok_for(pid):
    return {
        "success": True,
        "valid": True,
        "data": {
            "product_id": pid,
            "username": "POC-VERIFIED",
            "expire_date": "2099-12-31",
        },
    }
EXPORT_OK = {"success": True, "valid": True, "message": "Xac thuc thanh cong."}
NO_UPDATE = {"success": True, "has_update": False, "message": "Khong co ban moi."}
EMPTY_LIST = []

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 80
BIND_IP = sys.argv[2] if len(sys.argv) > 2 else "0.0.0.0"


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        ts = time.strftime("%Y-%m-%d %H:%M:%S")
        _log(f"[{ts}] {self.address_string()} {self.requestline}")

    def _send(self, obj, code=200):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        te = (self.headers.get("Transfer-Encoding") or "").lower()
        if "chunked" in te:
            data = b""
            while True:
                line = self.rfile.readline(65536).strip()
                if b";" in line:
                    line = line.split(b";")[0]
                try:
                    size = int(line, 16)
                except ValueError:
                    break
                if size == 0:
                    self.rfile.readline(65536)
                    break
                data += self.rfile.read(size)
                self.rfile.readline(65536)
            return data.decode("utf-8", "replace")
        length = int(self.headers.get("Content-Length", 0) or 0)
        return self.rfile.read(length).decode("utf-8", "replace") if length else ""

    def do_POST(self):
        body = self._read_body()
        _log(f"    POST {self.path}")
        if body:
            _log(f"    body: {body[:400]}")

        if self.path.startswith("/api/verify_license.php"):
            self._send(license_ok_for(product_id_from_body(body)))
        elif self.path.startswith("/api/verify_export_password.php"):
            self._send(EXPORT_OK)
        elif self.path.startswith("/api/check_update.php"):
            self._send(NO_UPDATE)
        elif "license_key" in (body or ""):
            _log("    >>> CATCH-ALL LICENSE HIT - endpoint khong tieu chuan: " + self.path)
            self._send(license_ok_for(product_id_from_body(body)))
        else:
            self._send({"success": False, "message": "not found"}, 404)

    def do_GET(self):
        _log(f"    GET {self.path}")
        if self.path.startswith("/api/game_data_sync.php"):
            self._send(EMPTY_LIST)
        elif self.path == "/" or self.path == "/favicon.ico":
            self._send({"ok": True, "hint": "fake dntshop.com server"})
        else:
            self._send({"success": False, "message": "not found"}, 404)


if __name__ == "__main__":
    import socket
    if ":" in BIND_IP:
        ThreadingHTTPServer.address_family = socket.AF_INET6
    _log(f"[*] Fake dntshop.com listening on {BIND_IP}:{PORT} (Ctrl+C de dung)")
    try:
        ThreadingHTTPServer((BIND_IP, PORT), Handler).serve_forever()
    except KeyboardInterrupt:
        _log("\n[*] Da dung fake server.")
    except OSError as e:
        _log(f"[!] Khong bind duoc {BIND_IP}:{PORT}: {e}")
        sys.exit(1)