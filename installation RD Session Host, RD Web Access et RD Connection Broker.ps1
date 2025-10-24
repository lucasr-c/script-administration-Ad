Write-Host "=== Installation des rôles Remote Desktop Services ===" -ForegroundColor Cyan

# 1. Installation des rôles RDS
Install-WindowsFeature -Name RDS-Connection-Broker,
                             RDS-Web-Access,
                             RDS-RD-Server `
                       -IncludeManagementTools -Restart:$false

Write-Host "✓ Rôles RDS installés : Connection Broker, Web Access et Session Host" -ForegroundColor Green

# 2. Importation du module RemoteDesktop
Import-Module RemoteDesktop

# 3. Définir le nom du serveur
$ServerName = $env:COMPUTERNAME

# 4. Création du déploiement RDS complet
New-RDSessionDeployment -ConnectionBroker $ServerName `
                        -WebAccessServer $ServerName `
                        -SessionHost $ServerName

Write-Host "✓ Déploiement RDS initialisé sur $ServerName" -ForegroundColor Green

# 5. Afficher les rôles installés pour vérification
Get-WindowsFeature RDS* | Where-Object Installed

Write-Host "`n=== Installation et configuration RDS terminées ===" -ForegroundColor Cyan
Write-Host "Vous pouvez maintenant accéder à l'interface RD Web Access via : https://$ServerName/RDWeb" -ForegroundColor Yellow

# 6. Vérification de l'installation 

Write-Host "=== Vérification des rôles RDS installés ===" -ForegroundColor Cyan

# Liste des noms de rôles à vérifier
$rdRoles = @("RDS-RD-Server", "RDS-Web-Access", "RDS-Connection-Broker")

# Récupérer l'état d'installation des rôles
$installedRoles = Get-WindowsFeature -Name $rdRoles

# Afficher les résultats
foreach ($role in $installedRoles) {
    $status = if ($role.Installed) { "Installé" } else { "Non installé" }
    $color = if ($role.Installed) { "Green" } else { "Red" }
    Write-Host "$($role.DisplayName) : $status" -ForegroundColor $color
}
