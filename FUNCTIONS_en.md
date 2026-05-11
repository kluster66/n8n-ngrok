# Function Reference — n8n-ngrok

This project consists of two initialization scripts (`init.sh` for Bash, `init.ps1` for PowerShell) and Docker Compose configuration files. The "functions" documented here correspond to the logical blocks of the main script flow and the PowerShell helper functions.

---

## init.sh — Main Bash Script

### Script Steps (Sequential Flow)

---

### 1. `.env` File Check

#### In

No parameters. Implicitly reads the current working directory to look for a `.env` file.

#### Transform

Checks for the existence of the `.env` file using `[ ! -f .env ]`. If the file is missing, prints an error message and exits the script with code `1`.

#### Out

No return value. Causes early script termination if `.env` is not found.

---

### 2. Docker Image Update

#### In

No parameters. Requires a valid `docker-compose.yml` in the current directory and network access to the Docker registry.

#### Transform

Runs `docker-compose pull` to force-download the latest versions of the images declared in `docker-compose.yml` (`ngrok/ngrok` and `n8nio/n8n:latest`).

#### Out

No return value. Updates the locally cached Docker images.

---

### 3. Start ngrok

#### In

No parameters. Requires `NGROK_AUTHTOKEN` to be set in `.env` and loaded by Docker Compose.

#### Transform

Runs `docker-compose up -d ngrok` to start only the `ngrok` service in detached mode. ngrok establishes an HTTP tunnel to `host.docker.internal:5678` (n8n's local port) and exposes its admin dashboard on port `4040`.

#### Out

No return value. The `ngrok` container starts running in the background.

---

### 4. Retrieve the ngrok Public URL (Polling Loop)

#### In

No parameters. Queries ngrok's local REST API at `http://localhost:4040/api/tunnels`.

#### Transform

Loops up to 15 times with a 2-second pause between each attempt. On each iteration, calls `curl -s http://localhost:4040/api/tunnels` and pipes the JSON response through `jq` to extract the `public_url` of the tunnel whose protocol is `https`. Exits the loop as soon as a URL is found. If no URL is detected after 15 attempts, prints an error message and exits with code `1`.

#### Out

Sets the shell variable `NGROK_URL` to the tunnel's public HTTPS URL (e.g. `https://abc123.ngrok.io`). Causes early script termination if the URL cannot be retrieved.

---

### 5. Update the `.env` File

#### In

| Implicit input | Type   | Description                                              |
|----------------|--------|----------------------------------------------------------|
| `NGROK_URL`    | string | Public HTTPS URL retrieved in the previous step          |

#### Transform

Uses `sed -i.bak` to delete any existing lines starting with `WEBHOOK_TUNNEL_URL=` or `WEBHOOK_URL=` from `.env`, then appends two new lines with the current values. A `.env.bak` backup file is created automatically by `sed`.

#### Out

Modifies `.env` in place. Creates `.env.bak` as an automatic backup. The `WEBHOOK_TUNNEL_URL` and `WEBHOOK_URL` variables now reflect the active ngrok tunnel.

---

### 6. Restart n8n

#### In

No parameters. Requires `.env` to contain valid values for `WEBHOOK_TUNNEL_URL` and `WEBHOOK_URL`.

#### Transform

Runs `docker-compose up -d --force-recreate n8n` to recreate and restart the `n8n` container with the updated environment variables, particularly `WEBHOOK_URL` pointing to the active ngrok tunnel.

#### Out

No return value. The `n8n` container is restarted and accessible locally at `http://localhost:5678`, configured to use the ngrok public URL as its webhook URL.

---

## init.ps1 — Main PowerShell Script

### Write-Info()

#### In

| Parameter | Type   | Description                              |
|-----------|--------|------------------------------------------|
| `$msg`    | string | Message to display in the console        |

#### Transform

Calls `Write-Host` with the `[INFO]` prefix and the Cyan color.

#### Out

No return value. Displays a colored informational message in the PowerShell console.

---

### Write-Success()

#### In

| Parameter | Type   | Description                              |
|-----------|--------|------------------------------------------|
| `$msg`    | string | Message to display in the console        |

#### Transform

Calls `Write-Host` with the `[OK]` prefix and the Green color.

#### Out

No return value. Displays a green success message in the PowerShell console.

---

### Write-ErrorMsg()

#### In

| Parameter | Type   | Description                              |
|-----------|--------|------------------------------------------|
| `$msg`    | string | Message to display in the console        |

#### Transform

Calls `Write-Host` with the `[ERROR]` prefix and the Red color.

#### Out

No return value. Displays a red error message in the PowerShell console.

---

### PowerShell Script Main Body

The main script body follows the same logic as `init.sh`, with the following differences:

#### In

No parameters. Implicitly reads the `.env` file in the current directory.

#### Transform

1. **`.env` check** — `Test-Path -Path '.env'`; exits with `exit 1` if missing.
2. **Image pull** — `docker-compose pull`.
3. **Start ngrok** — `docker-compose up -d ngrok`.
4. **URL polling** — `for` loop up to 15 iterations; uses `Invoke-RestMethod` to query `http://localhost:4040/api/tunnels`; iterates over `$resp.tunnels` to find the `https` tunnel. 2-second pause between attempts via `Start-Sleep`.
5. **Back up and update `.env`** — copies `.env` to `.env.bak` via `Copy-Item`. Filters `WEBHOOK_TUNNEL_URL=` and `WEBHOOK_URL=` lines using `Where-Object`. Rewrites the entire file using `Set-Content -Encoding utf8`.
6. **Restart n8n** — `docker-compose up -d --force-recreate n8n`.

#### Out

No return value. The `n8n` container is restarted with the active ngrok webhook URL. A `.env.bak` file is created before any modification to `.env`. Exit code `0` on success, `1` on error.
