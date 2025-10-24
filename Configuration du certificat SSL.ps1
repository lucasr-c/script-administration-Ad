$DnsName = "server2025.test.local"
$Broker = "server2025.test.local"

# Créer certificat auto-signé
$Cert = New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation "Cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(2)
Write-Host "Certificat créé. Thumbprint : $($Cert.Thumbprint)" -ForegroundColor Green

# Appliquer aux rôles RDS existants seulement
Import-Module RemoteDesktop
@("RDWebAccess", "RDRedirector", "RDPublishing") | ForEach-Object {
    try {
        Set-RDCertificate -Role $_ -Thumbprint $Cert.Thumbprint -ConnectionBroker $Broker -Force -ErrorAction Stop
        Write-Host "Certificat appliqué à $_" -ForegroundColor Green
    } catch {
        Write-Host "Rôle $_ non disponible dans ce déploiement" -ForegroundColor Yellow
    }
}

Write-Host "RDWeb sécurisé." -ForegroundColor Cyan
