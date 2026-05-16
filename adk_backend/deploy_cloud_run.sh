#!/bin/bash
# deploy_cloud_run.sh
# Deployment script for Sitara ADK Backend

PROJECT_ID="sitara-v1-495117"
REGION="asia-south1"
SERVICE_NAME="sitara-backend"

echo "🚀 Deploying $SERVICE_NAME to Google Cloud Run ($REGION)..."

gcloud run deploy $SERVICE_NAME \
    --source . \
    --project $PROJECT_ID \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars "ENV=production" \
    --set-env-vars "GOOGLE_API_KEY=$GOOGLE_API_KEY"

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
else
    echo "❌ Deployment failed."
fi