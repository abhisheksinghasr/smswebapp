# deploy.ps1

param (
    [string]$sourcePath = "C:\CICD-Build",
    [string]$destinationPath = "C:\inetpub\wwwroot\checkout"
)

# Function to check command success
function Check-Success {
    param (
        [string]$message
    )
    if ($?) {
        Write-Output "$message ✅"
    } else {
        Write-Error "$message ❌"
        exit 1
    }
}

# Stop IIS
Write-Output "Stopping IIS..."
Stop-Service -Name W3SVC -Force
Check-Success "IIS Stopped"

# Clean destination folder
Write-Output "Cleaning destination folder..."
Remove-Item -Path "$destinationPath\*" -Recurse -Force
Check-Success "Destination folder cleaned"

# Deploy and extract ZIP
Write-Output "Deploying code from $sourcePath to $destinationPath..."
$zipFile = Get-ChildItem -Path $sourcePath -Filter "*.zip" | Select-Object -First 1
if ($zipFile) {
    Expand-Archive -Path $zipFile.FullName -DestinationPath $destinationPath -Force
    Check-Success "Code deployed and extracted"
} else {
    Write-Error "No ZIP file found in $sourcePath"
    exit 1
}

# Restart IIS
Write-Output "Restarting IIS..."
Start-Service -Name W3SVC
Check-Success "IIS Restarted"

Write-Output "✅ Deployment Completed Successfully!"
