from flask import Flask, jsonify
import socket
import datetime
import os

app = Flask(__name__)

DATA_DIR = os.getenv("DATA_DIR", "/var/lib/data")
COUNTER_FILE = os.path.join(DATA_DIR, "counter.txt")


def bump_counter():
    os.makedirs(DATA_DIR, exist_ok=True)
    try:
        with open(COUNTER_FILE) as f:
            count = int(f.read().strip() or 0)
    except FileNotFoundError:
        count = 0
    count += 1
    with open(COUNTER_FILE, "w") as f:
        f.write(str(count))
    return count


@app.get("/api/hello")
def hello():
    return jsonify(
        message="Hello from the backend!",
        container=socket.gethostname(),
        time=datetime.datetime.now().isoformat(timespec="seconds"),
        calls=bump_counter(),
    )


@app.get("/api/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))
