# Sitara Frontend — Cloud Run Deploy Script
# Run from the sitara_app directory:
#   cd D:\my-dev-knowledge-base\sitara\sitara_app
#   .\deploy.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploying Sitara frontend to Cloud Run..." -ForegroundColor Cyan
Write-Host ""

# Verify Dockerfile is present
if (-not (Test-Path "Dockerfile")) {
    Write-Error "Dockerfile not found! Run this script from sitara_app/"
    exit 1
}

# Verify lib/ has dart files
$dartCount = (Get-ChildItem -Path "lib" -Recurse -Filter "*.dart").Count
Write-Host "✅ Found $dartCount Dart files in lib/" -ForegroundColor Green

gcloud run deploy sitara-frontend `
    --source . `
    --region asia-south1 `
    --project [GCP-PROJECT-ID] `
    --allow-unauthenticated `
    --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deploy succeeded!" -ForegroundColor Green
    Write-Host "🌐 URL: https://[YOUR-CLOUD-RUN-FRONTEND-URL]" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ Deploy failed. Check Cloud Build logs:" -ForegroundColor Red
    Write-Host "   https://console.cloud.google.com/cloud-build/builds?project=[GCP-PROJECT-ID]" -ForegroundColor Yellow
}
