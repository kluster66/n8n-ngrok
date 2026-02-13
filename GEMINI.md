# Project Overview

This project provides a Docker-based development environment for **n8n**, a workflow automation tool, configured to work behind public tunnels for webhook testing. It offers two alternative configurations for exposing the local n8n instance to the internet:

1.  **ngrok (Root Configuration):** Uses ngrok to create a secure tunnel. Includes automation scripts to capture the dynamic public URL and configure n8n webhooks automatically.
2.  **Cloudflare Tunnel (`n8n-cloudflared/`):** An alternative setup using Cloudflare's `cloudflared` to create "quick tunnels" without requiring an account or token.

## Main Technologies
- **n8n:** Workflow automation platform.
- **Docker & Docker Compose:** Containerization and orchestration.
- **ngrok:** Tunneling service (requires an auth token).
- **Cloudflare Tunnel (cloudflared):** Alternative tunneling service.
- **PowerShell / Bash:** Automation scripts for environment initialization.

---

# Building and Running

### Prerequisites
1.  **Docker & Docker Compose** installed and running.
2.  Create a persistent Docker volume for n8n data:
    ```bash
    docker volume create n8n_data
    ```

### Using ngrok (Root)
1.  Create a `.env` file in the root directory:
    ```env
    NGROK_AUTHTOKEN=your_ngrok_token_here
    # Optional: NGROK_REGION=eu
    ```
2.  Run the initialization script:
    - **Windows (PowerShell):** `./init.ps1`
    - **Linux/WSL (Bash):** `./init.sh`
3.  The script will start ngrok, retrieve the public URL, update `.env` with `WEBHOOK_URL`, and restart n8n.
4. Access n8n locally at `http://localhost:5678` and the ngrok dashboard at `http://localhost:4040`.

### Stopping and Restarting
To completely stop the services and remove containers:
```bash
docker-compose down
```
To restart everything properly (including tunnel URL refresh):
- **Windows:** `./init.ps1`
- **Linux/WSL:** `./init.sh`

*Note: Avoid using `docker-compose restart` as it may not update the n8n webhook URL if the ngrok tunnel has changed.*

### Using Cloudflare Tunnel (`n8n-cloudflared/`)
1.  Navigate to the directory: `cd n8n-cloudflared`
2.  Start the services:
    ```bash
    docker-compose up -d
    ```
3.  Find your public URL in the logs:
    ```bash
    docker-compose logs -f cloudflared
    ```
    Look for an URL ending in `.try.cloudflare.com`.

---

# Development Conventions

- **Environment Variables:** n8n configuration is primarily handled via environment variables in `docker-compose.yml`.
- **Initialization Scripts:** Use `init.ps1` or `init.sh` to ensure `WEBHOOK_URL` is correctly synchronized with the tunnel's public endpoint.
- **Persistence:** All n8n data (workflows, credentials) is stored in the external Docker volume `n8n_data`.
- **Security:**
    - `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` is enabled.
    - `N8N_GIT_NODE_DISABLE_BARE_REPOS` is enabled for security.
    - `N8N_BLOCK_ENV_ACCESS_IN_NODE` is set to `false` to allow environment variable access in Code Nodes.

# Key Files
- `docker-compose.yml`: Main service definitions for n8n and ngrok.
- `init.ps1` / `init.sh`: Orchestrates the tunnel startup and n8n webhook configuration.
- `policy.yml`: Optional ngrok traffic policy (e.g., for OAuth).
- `n8n-cloudflared/`: Contains the Cloudflare Tunnel variant.

---

# TODO / Improvements
- [ ] Add `init.ps1` and `init.sh` to `n8n-cloudflared/` (currently mentioned in its README but missing).
- [ ] Create a `.env.example` file to simplify initial setup.
- [ ] Fix the `build: .` reference in `n8n-cloudflared/docker-compose.yml` or add a `Dockerfile`.
