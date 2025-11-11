# n8n + ngrok (développement local)

Guide rapide pour démarrer n8n derrière ngrok sur Windows (PowerShell) ou Unix (bash).

Prérequis
- Docker et docker-compose (ou `docker compose`) installés et disponibles dans le PATH.
- Créer le volume Docker `n8n_data` (le compose le référence comme `external`):

```pwsh
docker volume create n8n_data
```

- Créer un fichier `.env` à la racine du projet contenant au minimum :

```env
NGROK_AUTHTOKEN=your_token_here
# Optionnel : NGROK_REGION=eu
```

Scripts fournis
- `init.sh` — script bash (Linux/macOS/WSL) : démarre `ngrok`, attend l'URL publique, écrit `WEBHOOK_TUNNEL_URL`/`WEBHOOK_URL` dans `.env` puis relance `n8n`.
- `init.ps1` — script PowerShell (Windows/pwsh) : même comportement que `init.sh`, crée aussi `.env.bak` avant modification.

Utilisation

PowerShell (Windows) :

```pwsh
./init.ps1
```

Bash (Linux / macOS / WSL) :

```bash
./init.sh
```

Que fait le script ?
- Démarre uniquement le service `ngrok` via Docker Compose.
- Interroge l'API locale de ngrok (`http://localhost:4040/api/tunnels`) pour obtenir la `public_url` en `https`.
- Insère `WEBHOOK_TUNNEL_URL` et `WEBHOOK_URL` dans `.env` (le PowerShell fait une sauvegarde `.env.bak`).
- Redémarre `n8n` pour appliquer la nouvelle URL de webhook.

Points d'attention et variables ajoutées
- Le fichier `docker-compose.yml` contient maintenant des variables recommandées pour améliorer le comportement et éviter des avertissements :
  - `DB_SQLITE_POOL_SIZE=5` — active un pool pour SQLite (meilleure compatibilité future).
  - `N8N_RUNNERS_ENABLED=true` — active les task runners.
  - `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true` — corrige automatiquement les permissions de fichiers.
  - `N8N_GIT_NODE_DISABLE_BARE_REPOS=true` — sécurité pour le Git Node.
  - `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` — permet l'accès aux variables d'environnement dans Code Node (si nécessaire).

Inspection & débogage
- UI et tunnel ngrok (interface web) : http://localhost:4040
- Pour voir les logs docker-compose :

```pwsh
docker-compose logs --tail=200
```

- Inspecter les logs du conteneur n8n :

```pwsh
docker logs n8n --tail 200
```

FAQ rapide — problèmes courants
- Si le script ne trouve pas d'URL ngrok : vérifiez que `NGROK_AUTHTOKEN` est correct et consultez l'UI ngrok à `:4040`.
- Si n8n ne persiste pas les données : vérifiez que le volume `n8n_data` existe et est monté.
- Si le système utilise `docker compose` (sans trait d'union) au lieu de `docker-compose`, adaptez les commandes dans les scripts.

Améliorations possibles
- Ajouter un `.env.example` (je peux le créer).
- Ajouter un job GitHub Actions pour provisionner l'environnement de dev (optionnel).

Si vous voulez que j'ajoute un `.env.example` ou que j'adapte les scripts pour détecter automatiquement `docker compose`, dites-le et je m'en occupe.
