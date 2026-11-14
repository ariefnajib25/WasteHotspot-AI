"""WasteHotspot AI local two-window demonstration server.

Python standard library only: sqlite3 + http.server.
For local development on the SAME COMPUTER; NOT a production service.
Start with: py backend/server.py  (from your Flutter project folder)
"""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from contextlib import closing
import json
import sqlite3
import threading
from datetime import datetime, timezone
from urllib.parse import urlparse

HOST = "127.0.0.1"          # only this computer
PORT = 5000
DB_PATH = Path(__file__).resolve().parent / "wastehotspot_demo.sqlite3"
ALLOWED_ORIGINS = {"http://localhost:51515", "http://127.0.0.1:51515"}
LOCK = threading.RLock()


def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def connection():
    db = sqlite3.connect(str(DB_PATH), timeout=10)
    db.row_factory = sqlite3.Row
    return db


def initialize():
    with closing(connection()) as db, db:
        db.execute("""CREATE TABLE IF NOT EXISTS report (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            days INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'Pending Review',
            team TEXT NOT NULL DEFAULT 'Not assigned',
            note TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )""")
        db.execute("""CREATE TABLE IF NOT EXISTS confirmations (
            report_id INTEGER NOT NULL DEFAULT 1,
            resident TEXT NOT NULL,
            PRIMARY KEY (report_id, resident)
        )""")


def current_report(db):
    row = db.execute("SELECT * FROM report WHERE id = 1").fetchone()
    if row is None:
        return None
    count = db.execute("SELECT COUNT(*) FROM confirmations WHERE report_id = 1").fetchone()[0]
    resolved = row["status"] == "Resolved"
    return {
        "id": row["id"],
        "location": "Township Park — Zone D",
        "waste_type": "Mixed waste (simulated scan)",
        "confirmations": count,
        "days": row["days"],
        "urgent": not resolved and (count >= 3 or row["days"] >= 3),
        "alert": not resolved and (row["days"] >= 2 or count >= 3),
        "status": row["status"],
        "team": row["team"],
        "note": row["note"],
        "resolved": resolved,
        "created_at": row["created_at"],
        "updated_at": row["updated_at"],
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[local demo] " + fmt % args)

    def cors(self):
        origin = self.headers.get("Origin", "")
        if origin in ALLOWED_ORIGINS:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def respond(self, status, payload):
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.cors()
        self.end_headers()
        self.wfile.write(raw)

    def do_OPTIONS(self):
        self.send_response(204)
        self.cors()
        self.end_headers()

    def receive_json(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length < 0 or length > 10_000:
            raise ValueError("Request size is invalid")
        if not length:
            return {}
        value = json.loads(self.rfile.read(length))
        if not isinstance(value, dict):
            raise ValueError("Expected a JSON object")
        return value

    def do_GET(self):
        if urlparse(self.path).path == "/api/state":
            with LOCK, closing(connection()) as db, db:
                self.respond(200, {"ok": True, "report": current_report(db)})
        elif urlparse(self.path).path in ("/", "/health"):
            self.respond(200, {"ok": True, "message": "WasteHotspot local demo server is running"})
        else:
            self.respond(404, {"error": "Not found"})

    def do_POST(self):
        path = urlparse(self.path).path
        try:
            data = self.receive_json()
        except (ValueError, json.JSONDecodeError) as e:
            self.respond(400, {"error": str(e)})
            return

        with LOCK, closing(connection()) as db, db:
            if path == "/api/reports":
                resident = str(data.get("resident", "")).strip().lower()
                if not 1 <= len(resident) <= 100:
                    self.respond(400, {"error": "Enter a resident name or email (1–100 characters)"})
                    return
                row = db.execute("SELECT status FROM report WHERE id = 1").fetchone()
                if row is not None and row["status"] == "Resolved":
                    self.respond(409, {"error": "Case already resolved. Reset demo to start a new incident."})
                    return
                first = row is None
                if first:
                    ts = now()
                    db.execute("INSERT INTO report (id, created_at, updated_at) VALUES (1, ?, ?)", (ts, ts))
                inserted = db.execute("INSERT OR IGNORE INTO confirmations (report_id, resident) VALUES (1, ?)", (resident,)).rowcount > 0
                if inserted:
                    db.execute("UPDATE report SET updated_at = ? WHERE id = 1", (now(),))
                earned = (10 if first else 3) if inserted else 0
                self.respond(200, {"ok": True, "earned_points": earned, "report": current_report(db)})
                return

            if path == "/api/next-day":
                row = db.execute("SELECT status FROM report WHERE id = 1").fetchone()
                if row is None or row["status"] == "Resolved":
                    self.respond(409, {"error": "No active report to escalate"})
                    return
                db.execute("UPDATE report SET days = days + 1, updated_at = ? WHERE id = 1", (now(),))
                self.respond(200, {"ok": True, "report": current_report(db)})
                return

            if path == "/api/reset":
                db.execute("DELETE FROM confirmations")
                db.execute("DELETE FROM report")
                self.respond(200, {"ok": True, "report": None})
                return

        self.respond(404, {"error": "Not found"})

    def do_PATCH(self):
        if urlparse(self.path).path != "/api/report":
            self.respond(404, {"error": "Not found"})
            return
        try:
            data = self.receive_json()
            status = str(data.get("status", ""))
            if status not in {"Pending Review", "Under Review", "In Progress", "Resolved"}:
                raise ValueError("Invalid status")
            team = str(data.get("team", "Not assigned"))[:100]
            note = str(data.get("note", ""))[:500]
        except (ValueError, json.JSONDecodeError) as e:
            self.respond(400, {"error": str(e)})
            return
        with LOCK, closing(connection()) as db, db:
            row = db.execute("SELECT status FROM report WHERE id = 1").fetchone()
            if row is None:
                self.respond(404, {"error": "Report not found"})
                return
            if row["status"] == "Resolved":
                self.respond(409, {"error": "Resolved cases cannot be reopened in this demo"})
                return
            db.execute("UPDATE report SET status = ?, team = ?, note = ?, updated_at = ? WHERE id = 1",
                       (status, team, note, now()))
            self.respond(200, {"ok": True, "report": current_report(db)})


if __name__ == "__main__":
    initialize()
    print(f"WasteHotspot local server: http://{HOST}:{PORT}")
    print("Only this computer can connect. Keep this terminal open.")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
