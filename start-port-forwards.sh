#!/bin/bash

echo "========================================"
echo "STARTING PORT FORWARDING SERVICES"
echo "========================================"

# Kill any existing port forwards
pkill -f "kubectl port-forward.*jenkins" || true
pkill -f "kubectl port-forward.*mailhog" || true
pkill -f "kubectl port-forward.*minio" || true
sleep 2

# Start Jenkins port forward in background
echo "Starting Jenkins port forward (8082:8080)..."
kubectl port-forward -n devops-pets service/jenkins 8082:8080 > /tmp/jenkins-port-forward.log 2>&1 &
JENKINS_PID=$!
echo $JENKINS_PID > /tmp/jenkins-port-forward.pid
echo "OK! Jenkins port forward is running (PID: $JENKINS_PID)"

# Start MailHog port forward in background  
echo "Starting MailHog port forward (8025:8025)..."
kubectl port-forward -n devops-pets service/mailhog 8025:8025 > /tmp/mailhog-port-forward.log 2>&1 &
MAILHOG_PID=$!
echo $MAILHOG_PID > /tmp/mailhog-port-forward.pid
echo "OK! MailHog port forward is running (PID: $MAILHOG_PID)"

# Start MinIO port forwards in background
echo "Starting MinIO API port forward (9000:9000)..."
kubectl port-forward -n devops-pets service/minio 9000:9000 > /tmp/minio-api-port-forward.log 2>&1 &
MINIO_API_PID=$!
echo $MINIO_API_PID > /tmp/minio-api-port-forward.pid
echo "OK! MinIO API port forward is running (PID: $MINIO_API_PID)"

echo "Starting MinIO Console port forward (9001:9001)..."
kubectl port-forward -n devops-pets service/minio 9001:9001 > /tmp/minio-console-port-forward.log 2>&1 &
MINIO_CONSOLE_PID=$!
echo $MINIO_CONSOLE_PID > /tmp/minio-console-port-forward.pid
echo "OK! MinIO Console port forward is running (PID: $MINIO_CONSOLE_PID)"

# Wait for port forwards to establish
echo "Waiting for port forwards to establish..."
sleep 5

# Check if port forwards are running
if kill -0 $JENKINS_PID 2>/dev/null; then
  echo "OK! Jenkins port forward is running"
else
  echo "ERR! Jenkins port forward failed to start"
fi

if kill -0 $MAILHOG_PID 2>/dev/null; then
  echo "OK! MailHog port forward is running"
else
  echo "ERR! MailHog port forward failed to start"
fi

if kill -0 $MINIO_API_PID 2>/dev/null; then
  echo "OK! MinIO API port forward is running"
else
  echo "ERR! MinIO API port forward failed to start"
fi

if kill -0 $MINIO_CONSOLE_PID 2>/dev/null; then
  echo "OK! MinIO Console port forward is running"
else
  echo "ERR! MinIO Console port forward failed to start"
fi

echo "========================================"
echo "PORT FORWARDING SETUP COMPLETED!"
echo "========================================"
echo "Jenkins: http://localhost:8082"
echo "MailHog: http://localhost:8025"
echo "MinIO API: http://localhost:9000"
echo "MinIO Console: http://localhost:9001"
echo ""
echo "Port forwards are running in background."
echo "Press Ctrl+C to stop."
echo "========================================"

# # Keep the main process alive and wait for Ctrl+C
# echo "Waiting indefinitely... (Press Ctrl+C to stop)"
# while true; do
#   sleep 30
#   echo "Port forwarding still active... (Press Ctrl+C to stop)"
# done 

  echo "DEBUG: Script is about to exit"