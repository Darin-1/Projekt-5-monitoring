Write-Host "Verifierar övervakningsplattformen..."
Write-Host "--------------------------------------"

function Check-Service {
    param([string]$name, [string]$url)
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $name är uppe och snurrar!" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ $name svarar inte." -ForegroundColor Red
    }
}

Check-Service -name "Prometheus (Monitor)" -url "http://192.168.56.11:9090/-/healthy"
Check-Service -name "Grafana (Monitor)" -url "http://192.168.56.11:3000/api/health"
Check-Service -name "Node Exporter (Server 1)" -url "http://192.168.56.12:9100/metrics"
Check-Service -name "Node Exporter (Server 2)" -url "http://192.168.56.13:9100/metrics"

Write-Host "--------------------------------------"
Write-Host "Test klart!"
