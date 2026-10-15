from flask import Flask, jsonify
import socket
import datetime
import os

app = Flask(__name__)

@app.get("/api/hello")
def hello():
    return jsonify(
        message="Hello from the backend!",
        container=socket.gethostname(),
        time=datetime.datetime.now().isoformat(timespec="seconds"),
    )

@app.get("/api/health")
def health():
    return jsonify(status="ok")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))
