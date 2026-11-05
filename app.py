"""Tiny Flask API used to demonstrate a CI/CD pipeline.

Two endpoints:
  /        -> basic info (including which git commit is running)
  /health  -> used by the AWS load balancer to decide if the app is alive
"""
import os

from flask import Flask, jsonify

app = Flask(__name__)

# GIT_SHA is injected at image build time (see Dockerfile + deploy.yml).
# Hitting "/" therefore tells you exactly which commit is live.
GIT_SHA = os.environ.get("GIT_SHA", "dev")
APP_VERSION = "2.1.0"


@app.route("/")
def home():
    return jsonify(
        {
            "status": "success",
            "message": "DevOps Cloud App is running",
            "version": APP_VERSION,
            "commit": GIT_SHA,
        }
    )


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


if __name__ == "__main__":
    # Only used for local development (python app.py).
    # In Docker, gunicorn starts the app instead.
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
