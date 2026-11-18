import os
import secrets
import sqlite3

from flask import Flask, request

app = Flask(__name__)

# Fixed: secret comes from the environment, never from the code
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY") or secrets.token_hex(32)


def get_db():
    conn = sqlite3.connect(":memory:")
    conn.execute("CREATE TABLE users (id INTEGER, name TEXT)")
    conn.execute("INSERT INTO users VALUES (1, 'arslan'), (2, 'ali')")
    return conn


@app.get("/health")
def health():
    return {"status": "ok", "version": os.environ.get("APP_VERSION", "dev")}


@app.get("/users")
def users():
    name = request.args.get("name", "")
    conn = get_db()
    # Fixed: parameterized query, input is passed as data, not SQL
    rows = conn.execute(
        "SELECT id, name FROM users WHERE name = ?", (name,)
    ).fetchall()
    return {"users": [{"id": r[0], "name": r[1]} for r in rows]}
