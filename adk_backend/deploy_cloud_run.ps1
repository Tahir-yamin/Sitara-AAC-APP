# deploy_cloud_run.ps1
# Deployment script for Sitara ADK Backend

$PROJECT_ID = "sitara-v1-495117"
$REGION = "asia-south1"
$SERVICE_NAME = "sitara-backend"

Write-Host "🚀 Deploying $SERVICE_NAME to Google Cloud Run ($REGION)..." -ForegroundColor Cyan

# Ensure billing and APIs are enabled if possible
# gcloud billing projects link $PROJECT_ID --billing-account=... 

gcloud run deploy $SERVICE_NAME `
    --source . `
    --project $PROJECT_ID `
    --region $REGION `
    --allow-unauthenticated `
    --set-env-vars "ENV=production" `
    --set-secrets "GOOGLE_API_KEY=GOOGLE_API_KEY:latest"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment failed." -ForegroundColor Red
}