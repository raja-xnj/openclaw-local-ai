#!/bin/bash
# OpenClaw + Ollama - Stop Script
# https://github.com/yourusername/openclaw-local-ai

echo "Stopping Ollama..."
pkill -9 ollama

echo "Stopping OpenClaw container..."
podman stop -t 0 openclaw

echo ""
echo "✓ OpenClaw + Ollama stopped"
