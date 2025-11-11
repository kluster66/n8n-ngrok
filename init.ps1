<#
  init.ps1 - PowerShell equivalent of init.sh (backup)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success($msg){ Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-ErrorMsg($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

if (-not (Test-Path -Path '.env')) {
    Write-ErrorMsg "Fichier .env introuvable. Créez-le avec NGROK_AUTHTOKEN (et éventuellement NGROK_REGION)."
    exit 1
}

Write-Info "Lancement de ngrok..."
docker-compose up -d ngrok

Write-Info "Attente de l'initialisation de ngrok..."
$NGROK_URL = $null
for ($i=0; $i -lt 15; $i++) {
    try {
        $resp = Invoke-RestMethod -Uri 'http://localhost:4040/api/tunnels' -UseBasicParsing -ErrorAction Stop
        if ($null -ne $resp.tunnels) {
            foreach ($t in $resp.tunnels) {
                if ($t.proto -eq 'https' -and $t.public_url) {
                    $NGROK_URL = $t.public_url
                    break
                }
            }
        }
    } catch {
    }
    if ($NGROK_URL) { break }
    Start-Sleep -Seconds 2
}

if (-not $NGROK_URL) {
    Write-ErrorMsg "Impossible de récupérer l'URL ngrok après plusieurs tentatives."
    exit 1
}

Write-Success "URL ngrok détectée : $NGROK_URL"

Write-Info "Mise à jour du fichier .env..."
$envPath = Join-Path (Get-Location) '.env'
$backupPath = "$envPath.bak"
Copy-Item -Path $envPath -Destination $backupPath -Force

$lines = Get-Content -LiteralPath $envPath -ErrorAction Stop
$filtered = $lines | Where-Object { 
    ($_ -notmatch '^(WEBHOOK_TUNNEL_URL=)') -and ($_ -notmatch '^(WEBHOOK_URL=)')
}

$newLines = @()
$newLines += $filtered
$newLines += "WEBHOOK_TUNNEL_URL=$NGROK_URL"
$newLines += "WEBHOOK_URL=$NGROK_URL"

$newLines | Set-Content -LiteralPath $envPath -Encoding utf8
Write-Success "Fichier .env mis à jour (backup -> $backupPath)"

Write-Info "Redémarrage de n8n avec l'URL webhook..."
docker-compose up -d --force-recreate n8n

Write-Success "n8n est lancé avec l'URL webhook : $NGROK_URL"

exit 0
