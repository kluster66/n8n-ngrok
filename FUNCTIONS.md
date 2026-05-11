# Référence des fonctions — n8n-ngrok

Ce projet est composé de deux scripts d'initialisation (`init.sh` pour Bash, `init.ps1` pour PowerShell) et de fichiers de configuration Docker Compose. Les "fonctions" documentées ici correspondent aux blocs logiques du script principal et aux fonctions helper PowerShell.

---

## init.sh — Script principal Bash

### Étapes du script (flux séquentiel)

---

### 1. Vérification du fichier `.env`

#### In

Aucun paramètre. Lit implicitement le répertoire de travail courant pour chercher un fichier `.env`.

#### Transform

Vérifie l'existence du fichier `.env` via `[ ! -f .env ]`. Si absent, affiche un message d'erreur et termine le script avec le code de sortie `1`.

#### Out

Aucune valeur de retour. Provoque une sortie anticipée du script si `.env` est introuvable.

---

### 2. Mise à jour des images Docker

#### In

Aucun paramètre. Dépend de la présence d'un fichier `docker-compose.yml` dans le répertoire courant et d'un accès réseau au registre Docker.

#### Transform

Exécute `docker-compose pull` pour forcer le téléchargement de la dernière version des images déclarées dans `docker-compose.yml` (`ngrok/ngrok` et `n8nio/n8n:latest`).

#### Out

Aucune valeur de retour. Met à jour les images Docker locales en cache.

---

### 3. Démarrage de ngrok

#### In

Aucun paramètre. Requiert que la variable `NGROK_AUTHTOKEN` soit définie dans `.env` et chargée par Docker Compose.

#### Transform

Exécute `docker-compose up -d ngrok` pour démarrer uniquement le service `ngrok` en mode détaché. ngrok établit un tunnel HTTP vers `host.docker.internal:5678` (port local de n8n) et expose son interface d'administration sur le port `4040`.

#### Out

Aucune valeur de retour. Le conteneur `ngrok` est démarré en arrière-plan.

---

### 4. Récupération de l'URL publique ngrok (boucle de polling)

#### In

Aucun paramètre. Interroge l'API REST locale de ngrok à l'adresse `http://localhost:4040/api/tunnels`.

#### Transform

Boucle jusqu'à 15 fois avec une pause de 2 secondes entre chaque tentative. À chaque itération, appelle `curl -s http://localhost:4040/api/tunnels` et filtre la réponse JSON via `jq` pour extraire `public_url` du tunnel dont le protocole est `https`. Sort de la boucle dès qu'une URL est trouvée. Si aucune URL n'est détectée après 15 tentatives, affiche un message d'erreur et termine le script avec le code `1`.

#### Out

Positionne la variable shell `NGROK_URL` avec l'URL publique HTTPS du tunnel (ex. `https://abc123.ngrok.io`). Provoque une sortie anticipée si l'URL reste introuvable.

---

### 5. Mise à jour du fichier `.env`

#### In

| Paramètre implicite | Type   | Description                                         |
|---------------------|--------|-----------------------------------------------------|
| `NGROK_URL`         | string | URL publique HTTPS récupérée à l'étape précédente   |

#### Transform

Utilise `sed -i.bak` pour supprimer toute ligne existante commençant par `WEBHOOK_TUNNEL_URL=` ou `WEBHOOK_URL=` dans `.env`. Ajoute ensuite deux nouvelles lignes en fin de fichier avec les valeurs actualisées. Un fichier de sauvegarde `.env.bak` est créé automatiquement par `sed`.

#### Out

Modifie le fichier `.env` en place. Crée `.env.bak` comme sauvegarde automatique. Les variables `WEBHOOK_TUNNEL_URL` et `WEBHOOK_URL` reflètent désormais le tunnel ngrok actif.

---

### 6. Redémarrage de n8n

#### In

Aucun paramètre. Requiert que `.env` contienne des valeurs valides pour `WEBHOOK_TUNNEL_URL` et `WEBHOOK_URL`.

#### Transform

Exécute `docker-compose up -d --force-recreate n8n` pour recréer et relancer le conteneur `n8n` avec les variables d'environnement mises à jour, notamment `WEBHOOK_URL` qui pointe vers le tunnel ngrok actif.

#### Out

Aucune valeur de retour. Le conteneur `n8n` est redémarré et accessible localement à `http://localhost:5678`, configuré pour utiliser l'URL publique ngrok comme URL de webhook.

---

## init.ps1 — Script principal PowerShell

### Write-Info()

#### In

| Paramètre | Type   | Description                           |
|-----------|--------|---------------------------------------|
| `$msg`    | string | Message à afficher dans la console    |

#### Transform

Appelle `Write-Host` avec le préfixe `[INFO]` et la couleur Cyan.

#### Out

Aucune valeur de retour. Affiche un message informatif coloré dans la console PowerShell.

---

### Write-Success()

#### In

| Paramètre | Type   | Description                           |
|-----------|--------|---------------------------------------|
| `$msg`    | string | Message à afficher dans la console    |

#### Transform

Appelle `Write-Host` avec le préfixe `[OK]` et la couleur Green.

#### Out

Aucune valeur de retour. Affiche un message de succès coloré en vert dans la console PowerShell.

---

### Write-ErrorMsg()

#### In

| Paramètre | Type   | Description                           |
|-----------|--------|---------------------------------------|
| `$msg`    | string | Message à afficher dans la console    |

#### Transform

Appelle `Write-Host` avec le préfixe `[ERROR]` et la couleur Red.

#### Out

Aucune valeur de retour. Affiche un message d'erreur coloré en rouge dans la console PowerShell.

---

### Corps principal du script PowerShell

Le script principal suit la même logique que `init.sh`, avec les différences suivantes :

#### In

Aucun paramètre. Lit implicitement le fichier `.env` dans le répertoire courant.

#### Transform

1. **Vérification `.env`** — `Test-Path -Path '.env'` ; sortie avec `exit 1` si absent.
2. **Pull des images** — `docker-compose pull`.
3. **Démarrage ngrok** — `docker-compose up -d ngrok`.
4. **Polling URL** — boucle `for` de 15 itérations ; utilise `Invoke-RestMethod` pour interroger `http://localhost:4040/api/tunnels` ; itère sur `$resp.tunnels` pour trouver le tunnel `https`. Pause de 2 secondes entre les tentatives via `Start-Sleep`.
5. **Sauvegarde et mise à jour `.env`** — copie `.env` en `.env.bak` via `Copy-Item`. Filtre les lignes `WEBHOOK_TUNNEL_URL=` et `WEBHOOK_URL=` avec `Where-Object`. Réécrit le fichier complet avec `Set-Content -Encoding utf8`.
6. **Redémarrage n8n** — `docker-compose up -d --force-recreate n8n`.

#### Out

Aucune valeur de retour. Le conteneur `n8n` est redémarré avec l'URL webhook ngrok active. Un fichier `.env.bak` est créé avant toute modification de `.env`. Code de sortie `0` en cas de succès, `1` en cas d'erreur.
