## Contexte rapide (vue d'ensemble)

- Ce dépôt contient une petite configuration Docker pour exécuter n8n (outil d'automatisation de workflows) derrière ngrok afin que des webhooks externes puissent atteindre une instance n8n locale.
- Deux services sont définis dans `docker-compose.yml` : `ngrok` (image `ngrok/ngrok`) et `n8n` (image `n8nio/n8n`). Le script d'initialisation `init.sh` démarre uniquement ngrok, récupère l'URL publique du tunnel et l'inscrit dans `.env` puis relance `n8n` avec la bonne URL de webhook.

## Ce qu'un agent IA doit savoir en priorité

- Fichiers clés : `docker-compose.yml` (définitions des services et ports), `init.sh` (flux d'initialisation et injection de `WEBHOOK_*`), et le fichier `.env` utilisé par `init.sh`.
- L'interface web locale de ngrok est exposée sur le port hôte `4040` ; `init.sh` interroge `http://localhost:4040/api/tunnels` et extrait la `public_url` du tunnel `https` via `jq`.
- Le service `n8n` écoute sur le port hôte `5678` et utilise un volume Docker externe nommé `n8n_data`. Ce volume doit exister (voir note ci‑dessous).

## Variables d'environnement et conventions

- Variables requises (doivent être présentes dans `.env`) :
   - `NGROK_AUTHTOKEN` — token ngrok utilisé par le conteneur `ngrok` (à définir avant le lancement).
   - `NGROK_REGION` — région ngrok (optionnelle).
   - `WEBHOOK_TUNNEL_URL` et `WEBHOOK_URL` — écrites automatiquement par `init.sh` lorsque le tunnel est prêt.
- La présence du fichier `.env` est obligatoire ; `init.sh` quitte si `.env` est introuvable. Le script supprime d'abord d'éventuelles lignes `WEBHOOK_TUNNEL_URL`/`WEBHOOK_URL` existantes puis ajoute les nouvelles valeurs.

- Variables de configuration n8n (définies dans `docker-compose.yml`) :
   - `DB_SQLITE_POOL_SIZE=5` — active le pool de connexions SQLite (améliore performance).
   - `N8N_RUNNERS_ENABLED=true` — active les task runners (requis pour futures versions).
   - `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true` — corrige automatiquement les permissions des fichiers de config.
   - `N8N_GIT_NODE_DISABLE_BARE_REPOS=true` — améliore la sécurité Git.
   - `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` — permet l'accès aux variables d'environnement dans Code Node.

## Démarrage & débogage (étapes explicites)

1. Vérifier que le volume Docker `n8n_data` existe (le compose le déclare `external: true`) :

```pwsh
docker volume create n8n_data
```

2. Remplir `.env` avec au minimum `NGROK_AUTHTOKEN` (et éventuellement `NGROK_REGION`).

3. Lancer le script d'initialisation :

```pwsh
./init.sh
```

    - Ce que fait `init.sh` :
       - Démarre uniquement `ngrok` : `docker-compose up -d ngrok`.
       - Interroge `http://localhost:4040/api/tunnels` pour obtenir la `public_url` en `https` (réessaie pendant ~30s).
       - Écrit `WEBHOOK_TUNNEL_URL` et `WEBHOOK_URL` dans `.env` puis relance `n8n` : `docker-compose up -d --force-recreate n8n`.

4. Pour inspecter ngrok pendant le débogage, ouvrir : http://localhost:4040

5. Pour récupérer manuellement l'URL publique (si nécessaire) :

```pwsh
curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url'
```

## Patterns et remarques spécifiques au projet

- Si vous modifiez la façon dont l'URL de webhook est construite ou injectée, mettez à jour `init.sh` — c'est la source de vérité pour les variables `WEBHOOK_*`.
- Le dépôt utilise la syntaxe `docker-compose` dans le script ; il s'attend au comportement classique de Docker Compose v2, sans forcer l'un ou l'autre binaire (`docker compose` vs `docker-compose`).
- Les données de `n8n` sont persistées dans un volume externe `n8n_data`. Les scripts CI ou d'onboarding doivent s'assurer que ce volume est créé avant de démarrer les services.

## Dépannage rapide

- Si `init.sh` ne trouve pas le tunnel : vérifier que `NGROK_AUTHTOKEN` est valide et consulter les logs du conteneur `ngrok` ou l'UI à `:4040` pour confirmer la présence d'un tunnel `https`.
- Si `n8n` ne conserve pas les données : vérifier que le volume `n8n_data` existe et est correctement monté.
- Si vous changez les ports ou les noms de services dans `docker-compose.yml`, adaptez également `init.sh` (il suppose `ngrok` sur `localhost:4040` et `n8n` sur le port `5678`).

## Références d'exemples dans le dépôt

- Services Docker : `docker-compose.yml` (services `ngrok` et `n8n`, ports `4040`/`5678`, volume `n8n_data`).
- Flux d'initialisation et injection : `init.sh` (interrogation de `http://localhost:4040/api/tunnels`, mise à jour de `.env`, redémarrage de `n8n`).

## Souhaitez-vous plus de détails ?

- Dites-moi si vous voulez que j'ajoute : instructions Windows PowerShell (`init.ps1`), un `README.md` orienté humain, un fichier `.env.example`, ou une option pour créer automatiquement le volume `n8n_data`.

