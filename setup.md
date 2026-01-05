# Setup Docker-Moodle für Plugin-Entwicklung

Diese Anleitung beschreibt, wie eine lokale Entwicklungsumgebung für Moodle-Plugins mit Docker eingerichtet wird. DIe Anleitung basiert auf dem [Tutorial von Jonathan Downey](https://lmstutorials.com/tutorials/moodle_docker/moodle_docker.php) und ist speziell für die Plugin-Entwicklung angepasst.

Prinzipiell wird auch hier mittels Docker Compose Moodle in Containern ausgeführt. In der Standardkonfiguration wird ein Bind-Mount für den Moodle-Code verwendet, was bei Windows-Rechnern zu Performance-Problemen führen kann. Daher wird in dieser Anleitung stattdessen ein Docker-Volume für den Moodle-Code verwendet, das einmalig mit dem Moodle-Code befüllt wird. Zusätzlich wird ein dedizierter Bind-Mount für den Plugin-Ordner eingerichtet, um die Entwicklung zu erleichtern.

## Voraussetzungen

- Installation von [Docker](https://www.docker.com/get-started) auf dem Computer


## Schritte

### Setup der Moodle-Docker Umgebung

1. **Repository forken**  
   Forken des [Moodle-Docker-Repository](https://github.com/moodle/moodle-docker) auf GitHub in eigenes Konto.

2. **Repository klonen**  
   ```bash
   git clone https://github.com/<your-username>/moodle-docker.git
   ```

3. **In das Verzeichnis wechseln**  
   Wechsle in das geklonte Verzeichnis:
   ```bash
   cd moodle-docker
   ```

4. **Anpassen der Konfiguration**  
Für die lokale Entwicklung muss die Datei `base.yml` angepasst und die Datei `local.yml` erstellt werden.

(`base.yml`) Auskommentieren des Bind-Mounts für den Moodle-Code:
```yaml
    volumes:
      #- "${MOODLE_DOCKER_WWWROOT}:/var/www/html"
```

(`local.yml`) Spezifikation von Volumes für Moodle-Daten (moodledata), den Moodle-Code (moodlecode) und die Datenbank (moodledb). Zusätzlich Spezifikation eines bind-Mounts dediziert für den Qtype-Ordner, in dem die Pligins entwickelt werden:

```yaml
services:
  webserver:
    volumes:
      - moodledata:/var/www/moodledata
      - moodlecode:/var/www/html
      - ./moodle/question/type:/var/www/html/question/type
  db:
    volumes:
      - moodledb:/var/lib/postgresql/data
volumes:
  moodledata:
      name: moodledata
  moodledb:
      name: moodledb
  moodlecode:
      name: moodlecode
```

Die Zusätzliche Datei `local.yml` wird automatisch beim Ausführen des Compose-Kommandos mittels `\bin\moodle-docker-compose` berücksichtigt.

5. **Umgebungsvariablen setzen**
    Setzen der Umgebungsvariablen für die Moodle-Installation:
    ```bash
    export MOODLE_DOCKER_WWWROOT=./moodle
    export MOODLE_DOCKER_DB=pgsql
    ```

6. **Moodle klonen**  
   Klonen des Moodle-Codes, falls noch nicht vorhanden (https://github.com/moodle/moodle.git). Auch hier bietet sich wieder ein Fork an.
   ```bash
    git clone -b <branch> git://github.com/<your-username>/moodle.git $MOODLE_DOCKER_WWWROOT
   ```

7. **Moodle-Konfiguration**
Template-Vorlage aus dem Moodle-Docker Repository in die Datei `config.php` kopieren und anpassen:
```bash
cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php
```

8. **Moodle-Code in Volume kopieren (einmalig)**
Damit das Datenbank-Setup später klappt und der Moodle-Applikationscode im Container vorhanden ist, muss das Volume `moodlecode` einmalig mit dem Moodle-Code befüllt werden. Dazu wird ein temporärer Container gestartet, der den Code kopiert:
```bash
docker run --rm -v moodlecode:/target -v "$(pwd)/moodle:/source" alpine cp -a /source/. /target
```


9. **Docker-Container starten**  
   Starte die Docker-Container mit dem folgenden Befehl:
   ```bash
   ./bin/moodle-docker-compose up -d
   ```

10. **Datenbank-Setup**
Die Moodle-Datenbank muss initialisiert werden. Dies geschieht über ein CLI-Skript im Webserver-Container.
```bash
bin/moodle-docker-compose exec webserver php /var/www/html/admin/cli/install_database.php `
    --agree-license `
    --fullname="Docker moodle" `
    --shortname="docker_moodle" `
    --summary="Docker moodle site" `
    --adminpass="test" `
    --adminemail="admin@example.com"
```
Alternativ kann dieses Setup auch ohne CLI-Befehl über die Weboberfläche durchgeführt werden, indem im Browser die URL `http://localhost:8080` aufgerufen wird.

11. **Moodle im Browser aufrufen**  
   Öffne deinen Webbrowser und gehe zu `http://localhost:8080`, um die Moodle-Installation zu sehen.

### Plugin-Entwicklung starten  

1. **Plugin-Ordner erstellen**  
Erstelle im lokalen Moodle-Verzeichnis den Ordner für den Plugin-Typ, z.B. für Fragetypen:
```bash
mkdir -p moodle/question/type/myplugin
```

2. **Plugin-Code entwickeln**  
Der Plugin-Ordner ist als Bind-Mount im Container verfügbar. Änderungen am Plugin-Code auf dem Host-System werden sofort im Container reflektiert.

