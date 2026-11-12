# RedForge

**Selbst gehosteter Git-Server wie GitHub**: Repositories, Pull Requests mit Reviews, Issues, Releases, Wiki, Actions, Pages, Gists, Discussions, Pakete und Container-Registry – auf deinem eigenen Server, mit voller Nutzerverwaltung. RedForge läuft als Docker-Paket und holt das HTTPS-Zertifikat selbst.

By [TheRedStonee](https://www.theredstonee.de/) · komplett kostenlos, ohne Lizenzschlüssel

> **English:** Self-hosted Git server that looks and works like GitHub. Repositories with code browser and README, pull requests with reviews and merge, issues with labels and milestones, releases, wiki, code search, Actions (CI with a built-in runner), Pages for static websites, Gists, Discussions, packages (npm, Maven, NuGet, PyPI …) and a Docker container registry. Full user management with organizations and teams, two-factor and passkeys, LDAP and OpenID Connect (Keycloak, Entra, Authentik). Import from GitHub with issues and pull requests, or keep a repository in sync with GitHub automatically (mirror in either direction). Git over HTTPS and SSH. One command to install, automatic HTTPS via Let's Encrypt, email, your own logo and colour, scheduled backups with restore, one-click updates. Interface in English. Jump to [Quick start](#schnellstart).

---

## Was es kann

**Code**
- Repositories mit Code-Ansicht, README, Branches, Tags, Commit-Verlauf und Vergleichen
- Git über HTTPS und SSH, große Dateien mit Git LFS
- Releases mit Anhängen, Wiki je Repository
- Code-Suche über alle Repositories

**Zusammenarbeit**
- Pull Requests mit Reviews, Kommentaren an Zeilen, Freigaben und Zusammenführen (Merge, Squash, Rebase)
- Issues mit Labels, Meilensteinen, Zuweisungen und Projekten
- Organisationen und Teams mit Rechten je Repository, Benachrichtigungen
- Discussions je Repository: Ankündigungen, Fragen mit markierter Antwort, Ideen, Stimmen
- Gists: Schnipsel mit mehreren Dateien, Versionen, Kommentaren und Sternen; geheime Gists nur über den Link

**Actions und Pages**
- Actions: Workflows aus `.gitea/workflows` oder `.github/workflows` (Syntax wie GitHub Actions). Ein Runner ist eingebaut und läuft in einem eigenen, abgeschotteten Docker – einschalten in der Verwaltung unter **Actions runners**. Weitere Runner auf anderen Rechnern lassen sich anmelden.
- Pages: statische Website direkt aus einem Branch (Wurzel oder `/docs`) unter `https://pages.<deine-domain>/<besitzer>/<repo>/` oder mit eigener Domain, HTTPS automatisch, nach jedem Push innerhalb einer Minute neu. Dafür braucht `pages.<deine-domain>` einen DNS-Eintrag auf den Server.

**Pakete**
- Container-Registry für Docker-Images
- Paket-Registry für npm, Maven, NuGet, PyPI, Composer, Cargo und mehr

**Nutzer und Anmeldung**
- Volle Nutzerverwaltung: anlegen, sperren, Admin-Rechte, Registrierung an oder aus
- Zwei-Faktor und Passkeys, Zwei-Faktor auf Wunsch als Pflicht für alle
- LDAP und OpenID Connect (Keycloak, Microsoft Entra, Authentik …)

**Umzug und Abgleich mit GitHub**
- Import von GitHub, GitLab und Gitea mit Issues, Pull Requests, Releases und Wiki
- Spiegel von GitHub: RedForge holt neue Commits, Branches und Tags automatisch
- Spiegel nach GitHub: jeder Push in RedForge geht automatisch auch zu GitHub

**Betrieb**
- Updates mit einem Klick in der Verwaltung (jeder Admin), vorher automatische Sicherung der Datenbanken
- Sicherungen täglich, wöchentlich oder per Knopf, zum Herunterladen, Wiederherstellen in der Verwaltung
- E-Mail über deinen SMTP-Server (mit Testmail), eigener Name, eigenes Logo und eigene Farbe
- Automatisches HTTPS über Let's Encrypt, oder hinter deinem eigenen Webserver, oder über Cloudflare Tunnel

RedForge nutzt im Kern [Gitea](https://about.gitea.com/) (MIT-Lizenz), unverändert aus dem offiziellen Image. Hinweise zu Lizenzen: [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Voraussetzungen

- Linux-Server (Debian, Ubuntu, Fedora, Rocky, Alma, Unraid …) mit 64 Bit, 2 GB RAM empfohlen, mit Actions 4 GB
- Docker (installiert das Skript bei Bedarf selbst)
- Für HTTPS: eine Domain, die auf den Server zeigt (zum Beispiel `git.deinefirma.de`)
- Freie Ports 80 und 443 – sonst läuft RedForge hinter deinem vorhandenen Webserver
- Ein freier Port für Git über SSH (Standard 2222)

## Schnellstart

```bash
curl -fsSL https://raw.githubusercontent.com/theredstonee/redforge-docker/main/install.sh | sudo bash
```

Das Skript prüft Docker, wählt den passenden Weg (eigenes HTTPS oder hinter deinem Webserver) und startet RedForge. Am Ende zeigt es einen **Setup-Code**. Öffne dann die Adresse des Servers im Browser und folge dem Assistenten: Code eingeben, Name und Farbe, Adresse und HTTPS, Admin-Konto.

Ordner: `/opt/redforge` (auf Unraid `/mnt/user/appdata/redforge`).

### Domain und HTTPS

Zeigt die Domain auf den Server und sind Port 80 und 443 frei, holt RedForge das Zertifikat selbst (Let's Encrypt) und leitet HTTP immer auf HTTPS um.

### Hinter deinem eigenen Webserver

Sind Port 80 oder 443 belegt (nginx, Apache …), lauscht RedForge nur auf `127.0.0.1` und einem freien Port. Der Assistent richtet den Virtual Host samt Zertifikat auf Wunsch selbst ein. Von Hand für nginx:

```nginx
server {
    server_name git.deinefirma.de;
    client_max_body_size 0;           # große Pushes und Container-Images
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;     # Live-Benachrichtigungen
        proxy_set_header Connection "upgrade";
        proxy_request_buffering off;
        proxy_read_timeout 3600s;
    }
}
```

### Cloudflare Tunnel (ohne offene Ports)

In der Einrichtung „Cloudflare Tunnel“ wählen und den Token eintragen. Git über SSH geht durch den Tunnel nicht – dafür HTTPS verwenden oder den SSH-Port freigeben.

## Git über SSH

RedForge nimmt SSH auf einem eigenen Port an (Standard `2222`, steht in der `.env` als `RF_SSH_PORT`). Die Klon-Adressen zeigen ihn automatisch an:

```bash
git clone ssh://git@git.deinefirma.de:2222/lena/projekt.git
```

## Update

In der Verwaltung unter **Admin → Overview → Updates** mit einem Klick (jeder Admin). Vorher sichert RedForge beide Datenbanken; schlägt der Start fehl, geht es automatisch auf die vorige Version zurück. Von Hand:

```bash
curl -fsSL https://raw.githubusercontent.com/theredstonee/redforge-docker/main/update.sh | sudo bash
```

## Sicherung

Am einfachsten in der Verwaltung unter **Backups**: Plan einstellen oder „Back up now“. Eine Sicherung enthält beide Datenbanken, Repositories, Anhänge, Pakete und die Gitea-Einstellungen; sie liegt im Datenordner unter `sicherungen/` und lässt sich dort herunterladen und wiederherstellen (vorher legt RedForge automatisch eine Sicherheitskopie an). Kopiere die Sicherungen regelmäßig auf einen anderen Rechner.

Von Hand wichtig sind die Docker-Volumes `redforge_db` (Datenbanken), `redforge_gitea` (Repositories, Anhänge, Pakete) und die Datei `.env` (enthält den Schlüssel für verschlüsselte Daten – ohne sie lassen sich Zwei-Faktor-Geheimnisse nicht mehr lesen). Vor jedem Update liegen Sicherungen der Datenbanken unter `.sicherung/`.

## Entfernen

```bash
sudo bash /opt/redforge/install.sh --deinstallieren
```

Fragt, ob auch alle Daten gelöscht werden sollen (Bestätigung durch Eintippen).

## Hilfe

- **Setup-Code nicht mehr da:** `cd /opt/redforge && docker compose logs app | grep Setup-Code`
- **Admin-Passwort vergessen:** `cd /opt/redforge && docker compose exec gitea gitea admin user change-password --username <name> --password '<neues-passwort>'`
- **Logs:** `docker compose logs -f app` bzw. `docker compose logs -f gitea`

---

RedForge ist ein Produkt von [TheRedStonee](https://www.theredstonee.de/). Der Quelltext ist nicht öffentlich; dieses Repository enthält die Installationsdateien für das Docker-Image `ghcr.io/theredstonee/redforge`. Als Git-Kern läuft [Gitea](https://about.gitea.com/) (MIT) als eigener, unveränderter Container.
