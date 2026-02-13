#!/bin/bash

# Vérifier que le fichier .env existe
if [ ! -f .env ]; then
  echo "❌ Fichier .env introuvable. Créez-le avec NGROK_AUTHTOKEN et NGROK_REGION."
  exit 1
fi

# Mettre à jour les images (force le téléchargement de la dernière version)
echo "📥 Mise à jour des images Docker..."
docker-compose pull

# Lancer ngrok seul pour récupérer l'URL
echo "🚀 Lancement de ngrok..."
docker-compose up -d ngrok

echo "⏳ Attente de l'initialisation de ngrok..."
for i in {1..15}; do
  NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url')
  if [ -n "$NGROK_URL" ]; then
    break
  fi
  sleep 2
done

if [ -z "$NGROK_URL" ]; then
  echo "❌ Impossible de récupérer l'URL ngrok."
  exit 1
fi

echo "✅ URL ngrok détectée : $NGROK_URL"

# Mettre à jour le fichier .env
echo "🔄 Mise à jour du fichier .env..."
sed -i.bak "/^WEBHOOK_TUNNEL_URL=/d" .env
sed -i.bak "/^WEBHOOK_URL=/d" .env
echo "WEBHOOK_TUNNEL_URL=$NGROK_URL" >> .env
echo "WEBHOOK_URL=$NGROK_URL" >> .env

# Redémarrer n8n avec la bonne URL
echo "🔁 Redémarrage de n8n avec l'URL webhook..."
docker-compose up -d --force-recreate n8n

echo "🎉 n8n est lancé avec l'URL webhook : $NGROK_URL"
