import sqlite3

from flask import Flask, request

app = Flask(__name__)

# VULNERABLE ON PURPOSE (Task 2 demo): hardcoded secret
app.config["SECRET_KEY"] = "barakah-demo-hardcoded-secret-123"


def get_db():
    conn = sqlite3.connect(":memory:")
    conn.execute("CREATE TABLE users (id INTEGER, name TEXT)")
    conn.execute("INSERT INTO users VALUES (1, 'arslan'), (2, 'ali')")
    return conn


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/users")
def users():
    name = request.args.get("name", "")
    conn = get_db()
    # VULNERABLE ON PURPOSE (Task 2 demo): SQL injection
    query = f"SELECT id, name FROM users WHERE name = '{name}'"
    rows = conn.execute(query).fetchall()
    return {"users": [{"id": r[0], "name": r[1]} for r in rows]}
