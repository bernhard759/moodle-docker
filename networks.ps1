# Ensure external Docker networks exist
$externalNetworks = @("coderunner-net", "llm-net")
foreach ($net in $externalNetworks) {
    $exists = docker network ls --format "{{.Name}}" | Where-Object { $_ -eq $net }
    if (-not $exists) {
        Write-Host "Creating external Docker network: $net" -ForegroundColor Yellow
        docker network create $net
    } else {
        Write-Host "Docker network '$net' already exists, skipping" -ForegroundColor Green
    }
}