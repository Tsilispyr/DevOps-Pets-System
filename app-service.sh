#!/bin/bash
#
# app-service.sh (Hybrid Version)
#
# A smart, long-running service to manage port-forwarding.
# - On startup, it checks for existing pods and connects to them (failsafe/manual mode).
# - Then, it enters a loop to wait for Jenkins build signals to refresh connections (service mode).
#
# Port Mappings:
# - Frontend: 8081 -> 80
# - Backend:  8080 -> 8080
# - MinIO API: 9000 -> 9000
# - MinIO Console: 9001 -> 9001

# --- Configuration ---
NAMESPACE="devops-pets"
APPS=("backend" "frontend" "minio" "minio-console")
declare -A PORTS=( ["backend"]="8080:8080" ["frontend"]="8081:80" ["minio"]="9000:9000" ["minio-console"]="9001:9001" )
declare -A URLS=( ["backend"]="http://backend:8080/actuator/health" ["frontend"]="http://frontend:80" ["minio"]="http://minio:9000" )
declare -A PIDS # Associative array to hold PIDs of port-forward processes

# --- Functions ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - INFO - $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - ERROR - $*" >&2
}

# Stops a specific port-forward process if it's running
stop_forward() {
    local app_name=$1
    if [ -n "${PIDS[$app_name]}" ] && ps -p "${PIDS[$app_name]}" > /dev/null; then
        log "Stopping port-forward for ${app_name} (PID: ${PIDS[$app_name]})."
        kill "${PIDS[$app_name]}"
        unset PIDS["$app_name"]
    fi
}

# The core function to bring an application's port-forward online
start_or_refresh_forward() {
    local app_name=$1
    log "Processing port-forward for '${app_name}'..."

    # Stop any previous forward for this app
    stop_forward "$app_name"

    # 1. Wait for deployment to exist and be available
    if ! kubectl wait --for=condition=available --timeout=180s "deployment/${app_name}" -n "$NAMESPACE"; then
        log_error "Deployment for '${app_name}' did not become available."
        return 1
    fi
    log "Deployment for '${app_name}' is available."

    # 2. Find the running pod and start port-forward directly
    log "Finding running pod for '${app_name}'..."
    
    # Find the running pod to forward to
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers -o custom-columns=NAME:.metadata.name | grep "^${app_name}-" | head -n 1)
    
    if [ -z "$pod_name" ]; then
        log_error "Could not find a running pod for '${app_name}' to port-forward."
        return 1
    fi

    log "Starting port-forward for pod '${pod_name}' on ports ${PORTS[$app_name]}..."
    nohup kubectl port-forward -n "$NAMESPACE" "$pod_name" "${PORTS[$app_name]}" > "/tmp/${app_name}-pf.log" 2>&1 &
    PIDS["$app_name"]=$!
    log "Successfully started '${app_name}' port-forward with PID ${PIDS[$app_name]}."
    return 0
}

# --- Main Logic ---

# Cleanup on exit
trap '{ log "Exit signal received. Shutting down all port-forwards."; for app in "${APPS[@]}"; do stop_forward "$app"; done; exit 0; }' SIGINT SIGTERM

log "==================================================="
log "      Hybrid Port-Forward Service Started     "
log "==================================================="
log "Monitoring namespace: ${NAMESPACE}"

    # 1. FAILSAFE MODE: Initial check on startup
    log "Performing initial check for existing applications (Failsafe Mode)..."
    initial_pods_found=false
    for app in "${APPS[@]}"; do
        # Check if deployment exists without waiting too long
        if kubectl get deployment "$app" -n "$NAMESPACE" &> /dev/null; then
            log "Found existing deployment for '${app}'. Attempting to connect."
            start_or_refresh_forward "$app"
            initial_pods_found=true
        elif [ "$app" = "minio-console" ]; then
            # Special handling for MinIO Console (no deployment, just service)
            log "Starting MinIO Console port-forward..."
            nohup kubectl port-forward -n "$NAMESPACE" service/minio 9001:9001 > "/tmp/minio-console-pf.log" 2>&1 &
            PIDS["minio-console"]=$!
            log "Successfully started 'minio-console' port-forward with PID ${PIDS[minio-console]}."
            initial_pods_found=true
        else
            log "No existing deployment found for '${app}'."
        fi
    done

if [ "$initial_pods_found" = true ]; then
    log "Initial check complete. Entering continuous monitoring mode."
else
    log "No initial applications found. Waiting for first Jenkins build signal."
fi

# 2. SERVICE MODE: Main monitoring loop, always waits for Jenkins signal
while true; do
    log "Waiting for a Jenkins build signal (ConfigMap with label 'build-complete=true')..."
    
    # This loop waits indefinitely for the signal
    while true; do
        jenkins_signal=$(kubectl get configmap -n "$NAMESPACE" -l build-complete=true -o name 2>/dev/null)
        if [ -n "$jenkins_signal" ]; then
            break
        fi
        sleep 15
    done
    
    log "New Jenkins build signal detected! Refreshing all applications. (Signal: $jenkins_signal)"
    
    # Refresh all applications based on the new build
    for app in "${APPS[@]}"; do
        if [ "$app" = "minio-console" ]; then
            # Special handling for MinIO Console (same service, different port)
            log "Starting port-forward for MinIO Console on ports ${PORTS[$app]}..."
            stop_forward "$app"
            nohup kubectl port-forward -n "$NAMESPACE" service/minio ${PORTS[$app]} > "/tmp/${app}-pf.log" 2>&1 &
            PIDS["$app"]=$!
            log "Successfully started '${app}' port-forward with PID ${PIDS[$app]}."
        elif [ "$app" = "minio-console" ] && [ "$1" = "initial" ]; then
            # For initial mode, start MinIO Console port-forward
            log "Starting initial MinIO Console port-forward on ports ${PORTS[$app]}..."
            stop_forward "$app"
            nohup kubectl port-forward -n "$NAMESPACE" service/minio ${PORTS[$app]} > "/tmp/${app}-pf.log" 2>&1 &
            PIDS["$app"]=$!
            log "Successfully started '${app}' port-forward with PID ${PIDS[$app]}."
        else
            log "Starting port-forward for service '${app}' on ports ${PORTS[$app]}..."
            stop_forward "$app"
            nohup kubectl port-forward -n "$NAMESPACE" service/${app} ${PORTS[$app]} > "/tmp/${app}-pf.log" 2>&1 &
            PIDS["$app"]=$!
            log "Successfully started '${app}' port-forward with PID ${PIDS[$app]}."
        fi
    done
    
    log "Cleaning up Jenkins build signal: $jenkins_signal"
    kubectl delete -n "$NAMESPACE" "$jenkins_signal" > /dev/null
    
    log "Cycle complete. Waiting for the next Jenkins signal."
done 