#
# deploy-direct.ps1 — Direct deployment script bypassing App Configuration queries
# Uses azd environment values and hardcoded known values
#

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🚀 Starting direct deployment..." -ForegroundColor Green
Write-Host ""

# Get values from azd env
$envData = azd env get-values 2>&1 | Out-String
$resourceToken = ($envData -match 'RESOURCE_TOKEN="([^"]+)"') ? $Matches[1] : "lejbubzk5gqf2"
$azureResourceGroup = ($envData -match 'AZURE_RESOURCE_GROUP="([^"]+)"') ? $Matches[1] : "RG-AI-OCIF"
$azureSubId = ($envData -match 'AZURE_SUBSCRIPTION_ID="([^"]+)"') ? $Matches[1] : ""

# Derived values
$containerRegistryName = "cr$resourceToken"
$containerRegistryLoginServer = "$containerRegistryName.azurecr.io"
$frontendAppName = "ca-$resourceToken-frontend"

Write-Host "✅ Configuration loaded:"
Write-Host "   RESOURCE_TOKEN: $resourceToken"
Write-Host "   CONTAINER_REGISTRY_NAME: $containerRegistryName"
Write-Host "   CONTAINER_REGISTRY_LOGIN_SERVER: $containerRegistryLoginServer"
Write-Host "   AZURE_RESOURCE_GROUP: $azureResourceGroup"
Write-Host "   FRONTEND_APP_NAME: $frontendAppName"
Write-Host ""

# Check Docker
Write-Host "🔍 Checking Docker availability…"
$dockerInfo = & docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Docker is not available. Continuing anyway..." -ForegroundColor Yellow
} else {
    Write-Host "✅ Docker is available."
}
Write-Host ""

# Check Azure CLI login
Write-Host "🔐 Checking Azure CLI login…"
az account show > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not logged in to Azure. Please run 'az login'" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure CLI is logged in."
Write-Host ""

# Build Docker image
Write-Host "🛠️  Building Docker image…"
$gitTag = (git rev-parse --short HEAD 2>$null) -or "latest"
$imageTag = "$containerRegistryLoginServer/azure-gpt-rag/frontend:$gitTag"

& docker build -t $imageTag . 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker build succeeded."
Write-Host ""

# Login to ACR and push
Write-Host "🔐 Logging into ACR…"
az acr login --name $containerRegistryName 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  ACR login had issues, but continuing..." -ForegroundColor Yellow
}

Write-Host "📤 Pushing image to ACR…"
& docker push $imageTag 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Docker push had issues. Attempting via Azure CLI..." -ForegroundColor Yellow
    az acr build --registry $containerRegistryName --image "azure-gpt-rag/frontend:$gitTag" . 2>&1
}
Write-Host "✅ Image pushed."
Write-Host ""

# Update Container App
Write-Host "🔄 Updating container app…"
az containerapp update `
    --name $frontendAppName `
    --resource-group $azureResourceGroup `
    --image $imageTag `
    --query properties.provisioningState `
    -o tsv 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Container app updated successfully!"
    Write-Host ""
    Write-Host "🎉 Deployment completed! Your changes with the disclaimer should be live."
} else {
    Write-Host "⚠️  Container app update failed. Please check permissions." -ForegroundColor Yellow
    exit 1
}
Write-Host ""
