#!/bin/bash

echo "Verifierar övervakningsplattformen..."
echo "--------------------------------------"

# Funktion för att kolla om en webbadress svarar med HTTP 200 (OK)
check_service() {
    local name=$1
    local url=$2
    if curl -s -f -o /dev/null "$url"; then
        echo "✅ $name är uppe och snurrar!"
    else
        echo "❌ $name svarar inte."
    fi
}

check_service "Prometheus (Monitor)" "http://192.168.56.11:9090/-/healthy"
check_service "Grafana (Monitor)" "http://192.168.56.11:3000/api/health"
check_service "Node Exporter (Server 1)" "http://192.168.56.12:9100/metrics"
check_service "Node Exporter (Server 2)" "http://192.168.56.13:9100/metrics"

echo "--------------------------------------"
echo "Test klart!"
