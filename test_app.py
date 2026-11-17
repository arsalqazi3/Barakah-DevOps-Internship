from app import app


def test_health():
    r = app.test_client().get("/health")
    assert r.status_code == 200
    assert r.json["status"] == "ok"


def test_users():
    r = app.test_client().get("/users?name=arslan")
    assert r.status_code == 200
    assert r.json["users"] == [{"id": 1, "name": "arslan"}]
