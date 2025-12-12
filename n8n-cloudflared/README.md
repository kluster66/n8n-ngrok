# n8n + Cloudflare Tunnel (développement local)

Guide rapide pour démarrer n8n avec un tunnel public et persistant via Cloudflare Tunnel.

Cette configuration utilise un "quick tunnel" de Cloudflare, qui vous donne une URL publique se terminant par `.try.cloudflare.com`.

## Prérequis

- Docker et `docker-compose` (ou `docker compose`) installés.
- Créer le volume Docker `n8n_data` si ce n'est pas déjà fait :

```powershell
docker volume create n8n_data
```

## Utilisation

Les scripts fournis démarrent simplement les services `n8n` et `cloudflared`.

**Avec PowerShell (Windows) :**

```powershell
./init.ps1
```

**Avec Bash (Linux / macOS / WSL) :**

```bash
./init.sh
```

## Comment obtenir votre URL publique

Contrairement à la configuration ngrok, l'URL est maintenant visible dans les logs du conteneur `cloudflared`.

1.  Lancez l'environnement avec l'un des scripts ci-dessus.
2.  Dans un autre terminal, suivez les logs du service `cloudflared` :

    ```bash
    docker-compose logs -f cloudflared
    ```

3.  Attendez quelques instants. Vous verrez apparaître des lignes de log contenant votre URL publique. Cherchez une URL se terminant par `.try.cloudflare.com`.

    Exemple de log :
    `INF Connection <ID> registered connIndex=0 ip=<IP> location=<location> **url=https://your-random-name.try.cloudflare.com**`

Cette URL est votre `WEBHOOK_URL`. Vous pouvez l'utiliser pour configurer les webhooks dans vos services externes.

## Inspection & débogage

- Pour voir les logs de tous les services :

  ```bash
  docker-compose logs --tail=200
  ```

- Pour inspecter spécifiquement les logs du conteneur n8n :

  ```bash
  docker logs n8n --tail 200
  ```

- L'interface de n8n reste accessible localement à l'adresse : http://localhost:5678

## Points d'attention

- Le `docker-compose.yml` contient des variables d'environnement recommandées pour améliorer la stabilité et la sécurité de n8n.
- Il n'y a plus besoin de fichier `.env` ni de token d'authentification pour que le tunnel fonctionne.
