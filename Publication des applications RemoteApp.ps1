Import-Module RemoteDesktop

$Collection = "Collection_Bureau"
$Broker = "server2025.test.local"

# Publier Bloc-notes
New-RDRemoteApp -CollectionName $Collection -DisplayName "Bloc-notes" -FilePath "C:\Windows\System32\notepad.exe" -ShowInWebAccess $true -ConnectionBroker $Broker

# Publier Calculatrice
New-RDRemoteApp -CollectionName $Collection -DisplayName "Calculatrice" -FilePath "C:\Windows\System32\calc.exe" -ShowInWebAccess $true -ConnectionBroker $Broker

Write-Host "Applications publiées avec succès." -ForegroundColor Green

# Vérifier
Get-RDRemoteApp -CollectionName $Collection -ConnectionBroker $Broker | Format-Table DisplayName, FilePath -AutoSize
