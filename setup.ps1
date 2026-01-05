$ErrorActionPreference = "Stop"
Write-Host "=== Moodle Docker Dev Setup ===" -ForegroundColor Cyan

# Config
$MOODLE_BRANCH = "MOODLE_405_STABLE"
$MOODLE_REPO   = "https://github.com/bernhard759/moodle.git"
$MOODLE_DIR    = "./moodle"
$PREFIX = "moodle-docker"
$VOLUME_NAME   = $PREFIX + "_" + "moodlecode"


# Env vars
$env:MOODLE_DOCKER_WWWROOT = $MOODLE_DIR
$env:MOODLE_DOCKER_DB     = "pgsql"
Write-Host "Environment variables set" -ForegroundColor Green

# Clone Moodle
if (-Not (Test-Path $MOODLE_DIR)) {
    Write-Host "Cloning Moodle ($MOODLE_BRANCH)..." -ForegroundColor Yellow
    git clone -b $MOODLE_BRANCH $MOODLE_REPO $MOODLE_DIR
} else {
    Write-Host "Moodle directory already exists, skipping clone" -ForegroundColor Green
}

# Config stuff
if (-Not (Test-Path "$MOODLE_DIR/config.php")) {
    Write-Host "Creating config.php from template" -ForegroundColor Yellow
    Copy-Item "config.docker-template.php" "$MOODLE_DIR/config.php"
} else {
    Write-Host "config.php already exists, skipping" -ForegroundColor Green
}

# Volume Population
$volumeExists = docker volume ls --format "{{.Name}}" | Where-Object { $_ -eq $VOLUME_NAME }
if (-Not $volumeExists) {
    Write-Host "Creating and populating Docker volume: $VOLUME_NAME" -ForegroundColor Yellow
    docker run --rm `
        -v ${VOLUME_NAME}:/target `
        -v "${PWD}/moodle:/source" `
        alpine sh -c "cp -a /source/. /target"
} else {
    Write-Host "Docker volume already exists, skipping copy" -ForegroundColor Green
}

# Start containers
Write-Host "Starting Docker containers..." -ForegroundColor Cyan
bin/moodle-docker-compose up -d
Start-Sleep -Seconds 10


# Install Moodle (CLI)
Write-Host "Running Moodle CLI installer..." -ForegroundColor Yellow
bin/moodle-docker-compose exec webserver php /var/www/html/admin/cli/install_database.php `
    --agree-license `
    --fullname="Docker moodle" `
    --shortname="docker_moodle" `
    --summary="Docker moodle site" `
    --adminpass="test" `
    --adminemail="admin@example.com"

Write-Host "=== Setup complete ===" -ForegroundColor Green