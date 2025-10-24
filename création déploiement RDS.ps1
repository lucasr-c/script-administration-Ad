# Variables avec ton serveur et domaine
$Broker = "server2025.test.local"
$WebAccess = "server2025.test.local"
$SessionHost = "server2025.test.local"

# Importer le module RemoteDesktop
Import-Module RemoteDesktop

# Créer le déploiement RDS
New-RDSessionDeployment `
    -ConnectionBroker $Broker `
    -WebAccessServer $WebAccess `
    -SessionHost $SessionHost

Write-Host "Déploiement RDS créé avec succès sur server2025.test.local"
