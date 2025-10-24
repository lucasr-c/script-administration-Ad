################################# Installation du rôle DHCP via powershell ################################

# Installation du rôle DHCP avec outils d'administration
Install-WindowsFeature DHCP -IncludeManagementTools

# Autorisation du serveur DHCP dans Active Directory
Add-DhcpServerInDC -DnsName server2025.test.local

########################### Script de création d'une étendue DHCP avec 20 adresses IP ###########################

# Configuration réseau :
# - Serveur DHCP : 192.168.12.10
# - Masque : 255.255.255.0
# - Passerelle : 192.168.12.5
# - Domaine : test.local
# - Étendue : 20 adresses IP
# Date : 2025-10-23

Write-Host "=== Création d'une étendue DHCP pour test.local ===" -ForegroundColor Cyan

# Configuration de l'étendue DHCP
$nomEtendue = "test.local"
$adresseServeur = "192.168.12.10"
$masque = "255.255.255.0"
$passerelle = "192.168.12.5"
$domaineDNS = "test.local"
$dureeLocation = 1.00:00:00  # 24 heures

# Plage d'adresses IP pour 20 clients
# Utilisation des adresses 192.168.12.20 à 192.168.12.39 (20 adresses)
$adresseDebut = "192.168.12.20"
$adresseFin = "192.168.12.39"

Write-Host "`n--- Configuration de l'étendue DHCP ---" -ForegroundColor Yellow
Write-Host "Nom de l'étendue : $nomEtendue" -ForegroundColor White
Write-Host "Plage d'adresses : $adresseDebut à $adresseFin (20 adresses)" -ForegroundColor White
Write-Host "Masque de sous-réseau : $masque" -ForegroundColor White
Write-Host "Passerelle par défaut : $passerelle" -ForegroundColor White
Write-Host "Domaine DNS : $domaineDNS" -ForegroundColor White
Write-Host "Durée de la location : $dureeLocation" -ForegroundColor White
Write-Host "Serveur DNS : $adresseServeur" -ForegroundColor White

# ===== Étape 1 : Vérifier que le rôle DHCP est installé =====
Write-Host "`n--- Vérification de l'installation du rôle DHCP ---`n" -ForegroundColor Yellow

try {
    $dhcpRole = Get-WindowsFeature -Name DHCP -ErrorAction Stop
    
    if ($dhcpRole.Installed) {
        Write-Host "✓ Rôle DHCP déjà installé" -ForegroundColor Green
    } else {
        Write-Host "⚠ Installation du rôle DHCP en cours..." -ForegroundColor Yellow
        Install-WindowsFeature DHCP -IncludeManagementTools -Restart:$false | Out-Null
        Write-Host "✓ Rôle DHCP installé avec succès" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Erreur lors de la vérification du rôle DHCP : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 2 : Autoriser le serveur DHCP dans Active Directory =====
Write-Host "`n--- Autorisation du serveur DHCP dans Active Directory ---`n" -ForegroundColor Yellow

try {
    $serverFQDN = "$env:COMPUTERNAME.$domaineDNS"
    
    # Vérifier si le serveur est déjà autorisé
    $dhcpAuthorise = Get-DhcpServerInDC -ErrorAction SilentlyContinue
    
    if ($dhcpAuthorise) {
        Write-Host "✓ Serveur DHCP déjà autorisé dans Active Directory" -ForegroundColor Green
    } else {
        Write-Host "Autorisation du serveur DHCP..." -ForegroundColor Yellow
        Add-DhcpServerInDC -DnsName $serverFQDN | Out-Null
        Write-Host "✓ Serveur DHCP autorisé dans Active Directory" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Avertissement lors de l'autorisation : $($_.Exception.Message)" -ForegroundColor Yellow
}

# ===== Étape 3 : Vérifier si l'étendue existe déjà =====
Write-Host "`n--- Vérification de l'étendue DHCP ---`n" -ForegroundColor Yellow

try {
    $etendueExistante = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $nomEtendue }
    
    if ($etendueExistante) {
        Write-Host "⚠ Une étendue nommée '$nomEtendue' existe déjà !" -ForegroundColor Yellow
        Write-Host "Étendue trouvée : $($etendueExistante.ScopeId)" -ForegroundColor White
        Write-Host "État : $($etendueExistante.State)" -ForegroundColor White
    } else {
        Write-Host "✓ Aucune étendue existante avec ce nom" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Erreur lors de la vérification : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 4 : Créer l'étendue DHCP =====
Write-Host "`n--- Création de l'étendue DHCP ---`n" -ForegroundColor Yellow

try {
    # Créer la nouvelle étendue
    Add-DhcpServerv4Scope `
        -Name $nomEtendue `
        -StartRange $adresseDebut `
        -EndRange $adresseFin `
        -SubnetMask $masque `
        -Description "Étendue DHCP pour $domaineDNS - 20 adresses" `
        -State Active `
        -PassThru | Out-Null
    
    Write-Host "✓ Étendue DHCP créée avec succès !" -ForegroundColor Green
    Write-Host "  Nom : $nomEtendue" -ForegroundColor White
    Write-Host "  Plage : $adresseDebut à $adresseFin" -ForegroundColor White
    
} catch {
    Write-Host "✗ Erreur lors de la création de l'étendue : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 5 : Configurer les options DHCP =====
Write-Host "`n--- Configuration des options DHCP ---`n" -ForegroundColor Yellow

try {
    # Configurer la passerelle, DNS et domaine
    Set-DhcpServerv4OptionValue `
        -ScopeId "192.168.12.0" `
        -Router $passerelle `
        -DnsServer $adresseServeur `
        -DnsDomain $domaineDNS `
        -PassThru | Out-Null
    
    Write-Host "✓ Options DHCP configurées !" -ForegroundColor Green
    Write-Host "  Passerelle par défaut : $passerelle" -ForegroundColor White
    Write-Host "  Serveur DNS : $adresseServeur" -ForegroundColor White
    Write-Host "  Domaine DNS : $domaineDNS" -ForegroundColor White
    
} catch {
    Write-Host "✗ Erreur lors de la configuration des options : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 6 : Configurer la durée de la location =====
Write-Host "`n--- Configuration de la durée de location ---`n" -ForegroundColor Yellow

try {
    Set-DhcpServerv4Scope `
        -ScopeId "192.168.12.0" `
        -LeaseDuration $dureeLocation `
        -PassThru | Out-Null
    
    Write-Host "✓ Durée de location configurée !" -ForegroundColor Green
    Write-Host "  Durée : $dureeLocation (24 heures)" -ForegroundColor White
    
} catch {
    Write-Host "✗ Erreur lors de la configuration de la durée : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 7 : Afficher le résumé de l'étendue créée =====
Write-Host "`n--- Résumé de l'étendue créée ---`n" -ForegroundColor Yellow

try {
    $etendue = Get-DhcpServerv4Scope -ScopeId "192.168.12.0" -ErrorAction Stop
    
    Write-Host "✓ Étendue DHCP active :" -ForegroundColor Green
    Write-Host "  Nom : $($etendue.Name)" -ForegroundColor White
    Write-Host "  Scope ID : $($etendue.ScopeId)" -ForegroundColor White
    Write-Host "  Plage : $($etendue.StartRange) à $($etendue.EndRange)" -ForegroundColor White
    Write-Host "  Masque : $($etendue.SubnetMask)" -ForegroundColor White
    Write-Host "  État : $($etendue.State)" -ForegroundColor White
    Write-Host "  Description : $($etendue.Description)" -ForegroundColor White
    
} catch {
    Write-Host "⚠ Impossible d'afficher les détails" -ForegroundColor Yellow
}

# ===== Étape 8 : Afficher les options DHCP =====
Write-Host "`n--- Options DHCP configurées ---`n" -ForegroundColor Yellow

try {
    $options = Get-DhcpServerv4OptionValue -ScopeId "192.168.12.0" -ErrorAction Stop
    
    Write-Host "✓ Options DHCP :" -ForegroundColor Green
    foreach ($option in $options) {
        Write-Host "  • Option $($option.OptionId) : $($option.Value)" -ForegroundColor White
    }
    
} catch {
    Write-Host "⚠ Impossible d'afficher les options" -ForegroundColor Yellow
}

# ===== Résumé final =====
Write-Host "`n=== Résumé de la configuration DHCP ===" -ForegroundColor Cyan

Write-Host "`nConfiguration appliquée :" -ForegroundColor Yellow
Write-Host "  • Nom de l'étendue : $nomEtendue" -ForegroundColor Green
Write-Host "  • Plage d'adresses : $adresseDebut à $adresseFin (20 adresses)" -ForegroundColor Green
Write-Host "  • Masque de sous-réseau : $masque" -ForegroundColor Green
Write-Host "  • Passerelle par défaut : $passerelle" -ForegroundColor Green
Write-Host "  • Serveur DNS : $adresseServeur" -ForegroundColor Green
Write-Host "  • Domaine DNS : $domaineDNS" -ForegroundColor Green
Write-Host "  • Durée de location : 24 heures" -ForegroundColor Green

Write-Host "`nProchaines étapes :" -ForegroundColor Cyan
Write-Host "  1. Redémarrer le service DHCP (optionnel)" -ForegroundColor White
Write-Host "  2. Vérifier les clients DHCP" -ForegroundColor White
Write-Host "  3. Configurer les réservations DHCP pour les serveurs" -ForegroundColor White
Write-Host "  4. Tester la distribution des adresses IP" -ForegroundColor White

Write-Host "`n=== Configuration DHCP terminée ===" -ForegroundColor Green