#!/bin/bash
# OpenClaw + Ollama - Start Script
# https://github.com/yourusername/openclaw-local-ai

echo "Starting Ollama..."
OLLAMA_HOST=0.0.0.0 OLLAMA_NUM_THREADS=6 ollama serve &

# Give Ollama a moment to initialize
sleep 2

echo "Starting OpenClaw container..."
podman start openclaw

echo ""
echo "✓ OpenClaw + Ollama started"
echo "→ Open http://localhost:3000 in your browser"
