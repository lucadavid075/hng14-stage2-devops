#!/bin/bash
set -e

echo "Waiting for service..."
sleep 5

echo "Checking health endpoint..."
timeout 30 curl -f http://localhost:3000/health