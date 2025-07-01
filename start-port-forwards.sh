#!/bin/bash

echo "========================================"
echo "STARTING PORT FORWARDING SERVICES"
echo "========================================"

# Kill any existing port forwards
pkill -f "kubectl port-forward.*jenkins" || true
pkill -f "kubectl port-forward.*mailhog" || true
pkill -f "kubectl port-forward.*minio" || true
pkill -f "kubectl port-forward.*frontend" || true
pkill -f "kubectl port-forward.*backend" || true
pkill -f "kubectl port-forward.*postgres" || true
pkill -f "kubectl port-forward.*ingress-nginx" || true
sleep 2

# Start Ingress-NGINX port forward in background
if kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller 2>/dev/null | grep -q 'Running'; then
  echo "Starting Ingress-NGINX port forward (8888:80)..."
  kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8888:80 > /tmp/ingress-nginx-port-forward.log 2>&1 &
  INGRESS_NGINX_PID=$!
  echo $INGRESS_NGINX_PID > /tmp/ingress-nginx-port-forward.pid
  echo "OK! Ingress-NGINX port forward is running (PID: $INGRESS_NGINX_PID)"
else
  echo "ERR! Ingress-NGINX pod not running, will retry in loop..."
fi

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

# Start Postgres port forward in background
echo "Starting Postgres port forward (5432:5432)..."
kubectl port-forward -n devops-pets service/postgres 5432:5432 > /tmp/postgres-port-forward.log 2>&1 &
POSTGRES_PID=$!
echo $POSTGRES_PID > /tmp/postgres-port-forward.pid
echo "OK! Postgres port forward is running (PID: $POSTGRES_PID)"

# Start Backend port forward in background
echo "Starting Backend port forward (8080:8080)..."
kubectl port-forward -n devops-pets service/backend 8080:8080 > /tmp/backend-port-forward.log 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > /tmp/backend-port-forward.pid
echo "OK! Backend port forward is running (PID: $BACKEND_PID)"

# Start Frontend port forward in background
echo "Starting Frontend port forward (8081:80)..."
kubectl port-forward -n devops-pets service/frontend 8081:80 > /tmp/frontend-port-forward.log 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > /tmp/frontend-port-forward.pid
echo "OK! Frontend port forward is running (PID: $FRONTEND_PID)"

# Wait for port forwards to establish
echo "Waiting for port forwards to establish..."
sleep 5

# Check if port forwards are running
if kill -0 $INGRESS_NGINX_PID 2>/dev/null; then
  echo "OK! Ingress-NGINX port forward is running"
else
  echo "ERR! Ingress-NGINX port forward failed to start"
fi

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

if kill -0 $POSTGRES_PID 2>/dev/null; then
  echo "OK! Postgres port forward is running"
else
  echo "ERR! Postgres port forward failed to start"
fi

if kill -0 $BACKEND_PID 2>/dev/null; then
  echo "OK! Backend port forward is running"
else
  echo "ERR! Backend port forward failed to start"
fi

if kill -0 $FRONTEND_PID 2>/dev/null; then
  echo "OK! Frontend port forward is running"
else
  echo "ERR! Frontend port forward failed to start"
fi

echo "========================================"
echo "PORT FORWARDING SETUP COMPLETED!"
echo "========================================"
echo "Jenkins: http://localhost:8082"
echo "MailHog: http://localhost:8025"
echo "MinIO API: http://localhost:9000"
echo "MinIO Console: http://localhost:9001"
echo "Postgres: http://localhost:5432"
echo "Frontend: http://localhost:8081"
echo "Backend API: http://localhost:8080"
echo "Ingress-NGINX: http://localhost:8888"
echo ""
echo "Port forwards are running in background."
echo "Press Ctrl+C to stop."
echo "========================================"

# === BEGIN: Infinite port-forward check for all services ===

SERVICES=(
  "jenkins jenkins 8082 8080"
  "mailhog mailhog 8025 8025"
  "minio-api minio 9000 9000"
  "minio-console minio 9001 9001"
  "backend backend 8080 8080"
  "frontend frontend 8081 80"
  "postgres postgres 5432 5432"
  "ingress-nginx ingress-nginx-controller 8888 80"
)

is_pod_running() {
  local label=$1
  kubectl get pods -n devops-pets -l app=$label 2>/dev/null | grep -q 'Running'
}

is_port_forward_active() {
  local port=$1
  lsof -iTCP:$port -sTCP:LISTEN -P 2>/dev/null | grep -q LISTEN
}

while true; do
  # Check for Jenkins signal (ConfigMap)
  if kubectl get configmap -n devops-pets -l build-complete=true | grep build-complete; then
    echo "[INFO] Jenkins build-complete signal detected. Resetting signal."
    kubectl delete configmap -n devops-pets -l build-complete=true
  fi

  # Check and start port-forwards for all services
  for entry in "${SERVICES[@]}"; do
    set -- $entry
    label=$1
    svc=$2
    local_port=$3
    target_port=$4
    namespace="devops-pets"
    if [ "$label" = "minio-console" ] || [ "$label" = "minio-api" ]; then
      pod_selector="app=minio"
    else
      pod_selector="app=$label"
    fi
    if [ "$label" = "ingress-nginx" ]; then
      namespace="ingress-nginx"
      pod_selector="app.kubernetes.io/component=controller"
      pods_output=$(kubectl get pods -n $namespace -l $pod_selector 2>/dev/null)
      if echo "$pods_output" | grep -q 'Running'; then
        if ! is_port_forward_active $local_port; then
          echo "Starting ingress-nginx port forward ($local_port:$target_port)..."
          kubectl port-forward -n $namespace service/$svc $local_port:$target_port > /tmp/${label}-port-forward.log 2>&1 &
          echo $! > /tmp/${label}-port-forward.pid
          echo "OK! ingress-nginx port forward is running (PID: $(cat /tmp/${label}-port-forward.pid))"
        fi
      else
        if [ -z "$pods_output" ]; then
          echo "ingress-nginx pod (service: $svc) not found in namespace $namespace, will retry..."
        else
          echo "ingress-nginx pod(s) not running in $namespace: $pods_output"
        fi
      fi
      continue
    fi
    pods_output=$(kubectl get pods -n $namespace -l $pod_selector 2>/dev/null)
    if echo "$pods_output" | grep -q 'Running'; then
      if ! is_port_forward_active $local_port; then
        echo "Starting $label port forward ($local_port:$target_port)..."
        kubectl port-forward -n $namespace service/$svc $local_port:$target_port > /tmp/${label}-port-forward.log 2>&1 &
        echo $! > /tmp/${label}-port-forward.pid
        echo "OK! $label port forward is running (PID: $(cat /tmp/${label}-port-forward.pid))"
      fi
    else
      if [ -z "$pods_output" ]; then
        echo "$label pod (service: $svc) not found in namespace $namespace, will retry..."
      else
        echo "$label pod(s) not running in $namespace: $pods_output"
      fi
    fi
  done
  sleep 10
done
# === END: Infinite port-forward check for all services ===

  echo "DEBUG: Script is about to exit"