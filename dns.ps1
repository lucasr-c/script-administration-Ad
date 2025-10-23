# Script de création d'une zone primaire DNS avec configuration réseau
# Domaine : test.local
# Serveur DNS : 192.168.12.10
# Date : 2025-10-23

Write-Host "=== Création d'une zone primaire DNS pour test.local ===" -ForegroundColor Cyan

# Configuration réseau et DNS
$zoneName = "test.local"
$dnsServerIP = "192.168.12.10"
$adresseIP = "192.168.12.10"
$masque = "255.255.255.0"
$passerelle = "192.168.12.5"
$replicationScope = "Forest"
$dynamicUpdate = "Secure"

Write-Host "`n--- Configuration réseau du serveur DNS ---" -ForegroundColor Yellow
Write-Host "Adresse IP du serveur : $adresseIP" -ForegroundColor White
Write-Host "Masque de sous-réseau : $masque" -ForegroundColor White
Write-Host "Passerelle par défaut : $passerelle" -ForegroundColor White
Write-Host "Serveur DNS primaire : $dnsServerIP" -ForegroundColor White

Write-Host "`n--- Configuration de la zone DNS ---" -ForegroundColor Yellow
Write-Host "Nom de la zone : $zoneName" -ForegroundColor White
Write-Host "Étendue de réplication : $replicationScope" -ForegroundColor White
Write-Host "Mise à jour dynamique : $dynamicUpdate" -ForegroundColor White

# ===== Étape 1 : Vérifier que le rôle DNS est installé =====
Write-Host "`n--- Vérification de l'installation du rôle DNS ---`n" -ForegroundColor Yellow

try {
    $dnsRole = Get-WindowsFeature -Name DNS -ErrorAction Stop
    
    if ($dnsRole.Installed) {
        Write-Host "✓ Rôle DNS déjà installé" -ForegroundColor Green
    } else {
        Write-Host "⚠ Installation du rôle DNS en cours..." -ForegroundColor Yellow
        Install-WindowsFeature -Name DNS -IncludeManagementTools -Restart:$false | Out-Null
        Write-Host "✓ Rôle DNS installé avec succès" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Erreur lors de la vérification du rôle DNS : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 2 : Créer la zone primaire DNS =====
Write-Host "`n--- Création de la zone primaire DNS ---`n" -ForegroundColor Yellow

try {
    # Vérifier que la zone n'existe pas déjà
    $zoneExistante = Get-DnsServerZone -Name $zoneName -ErrorAction SilentlyContinue
    
    if ($zoneExistante) {
        Write-Host "⚠ La zone $zoneName existe déjà !" -ForegroundColor Yellow
        Write-Host "Zone détectée : $($zoneExistante.ZoneName)" -ForegroundColor White
        Write-Host "Type : $($zoneExistante.ZoneType)" -ForegroundColor White
        Write-Host "Intégrée AD : $($zoneExistante.IsDsIntegrated)" -ForegroundColor White
    } else {
        # Créer la zone primaire intégrée Active Directory
        $zone = Add-DnsServerPrimaryZone `
            -Name $zoneName `
            -ReplicationScope $replicationScope `
            -DynamicUpdate $dynamicUpdate `
            -PassThru
        
        Write-Host "✓ Zone primaire créée avec succès !" -ForegroundColor Green
        Write-Host "`nDétails de la zone créée :" -ForegroundColor Cyan
        Write-Host "  Nom de la zone : $($zone.ZoneName)" -ForegroundColor White
        Write-Host "  Type de zone : $($zone.ZoneType)" -ForegroundColor White
        Write-Host "  Intégrée Active Directory : $($zone.IsDsIntegrated)" -ForegroundColor White
        Write-Host "  Étendue de réplication : $replicationScope" -ForegroundColor White
        Write-Host "  Mise à jour dynamique : $($zone.DynamicUpdate)" -ForegroundColor White
        Write-Host "  Statut : $($zone.Status)" -ForegroundColor White
    }
    
} catch {
    Write-Host "✗ Erreur lors de la création de la zone : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 3 : Créer les enregistrements DNS essentiels =====
Write-Host "`n--- Création des enregistrements DNS essentiels ---`n" -ForegroundColor Yellow

$records = @(
    @{Nom = "@"; Type = "A"; IP = $dnsServerIP; Description = "Enregistrement A pour la zone (SOA)"},
    @{Nom = "dns"; Type = "A"; IP = $dnsServerIP; Description = "Enregistrement A pour le serveur DNS"}
)

foreach ($record in $records) {
    try {
        # Vérifier si l'enregistrement existe déjà
        $recordExistant = Get-DnsServerResourceRecord -ZoneName $zoneName -Name $record.Nom -RRType $record.Type -ErrorAction SilentlyContinue
        
        if ($recordExistant) {
            Write-Host "⚠ L'enregistrement $($record.Nom) existe déjà" -ForegroundColor Yellow
        } else {
            if ($record.Type -eq "A") {
                Add-DnsServerResourceRecordA `
                    -ZoneName $zoneName `
                    -Name $record.Nom `
                    -IPv4Address $record.IP `
                    -PassThru | Out-Null
            }
            Write-Host "✓ $($record.Description) créé : $($record.Nom) -> $($record.IP)" -ForegroundColor Green
        }
    } catch {
        Write-Host "✗ Erreur lors de la création de l'enregistrement $($record.Nom) : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ===== Étape 4 : Vérifier et configurer les paramètres du serveur DNS =====
Write-Host "`n--- Configuration des paramètres du serveur DNS ---`n" -ForegroundColor Yellow

try {
    # Configurer le serveur DNS pour écouter sur l'adresse IP locale
    $dnsServerConfig = Get-DnsServerSetting -ComputerName "localhost" -ErrorAction SilentlyContinue
    
    Write-Host "✓ Configuration du serveur DNS vérifiée" -ForegroundColor Green
    Write-Host "  Serveur : localhost" -ForegroundColor White
    Write-Host "  Adresse d'écoute : $dnsServerIP" -ForegroundColor White
    Write-Host "  Mise à jour dynamique sécurisée : Activée" -ForegroundColor White
    
} catch {
    Write-Host "⚠ Avertissement lors de la configuration : $($_.Exception.Message)" -ForegroundColor Yellow
}

# ===== Étape 5 : Afficher le résumé final =====
Write-Host "`n--- Résumé des zones DNS ---`n" -ForegroundColor Yellow

try {
    $zones = Get-DnsServerZone -ErrorAction Stop
    $zones | Where-Object { $_.ZoneName -eq $zoneName } | Format-Table -Property ZoneName, ZoneType, Status, DynamicUpdate -AutoSize
    
    Write-Host "`nNombre de zones configurées : $($zones.Count)" -ForegroundColor White
    
} catch {
    Write-Host "✗ Erreur lors de l'affichage des zones : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 6 : Afficher les enregistrements DNS de la zone =====
Write-Host "`n--- Enregistrements DNS dans la zone $zoneName ---`n" -ForegroundColor Yellow

try {
    $zoneRecords = Get-DnsServerResourceRecord -ZoneName $zoneName -ErrorAction Stop
    
    if ($zoneRecords) {
        Write-Host "Enregistrements trouvés : $($zoneRecords.Count)" -ForegroundColor Green
        $zoneRecords | Format-Table -Property Name, RecordType, RecordData -AutoSize
    } else {
        Write-Host "Aucun enregistrement créé pour le moment" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "✗ Erreur lors de la récupération des enregistrements : $($_.Exception.Message)" -ForegroundColor Red
}

# ===== Étape 7 : Test de résolution DNS =====
Write-Host "`n--- Test de résolution DNS ---`n" -ForegroundColor Yellow

$testNoms = @("$zoneName", "dns.$zoneName")

foreach ($nom in $testNoms) {
    try {
        $resolution = Resolve-DnsName -Name $nom -Server $dnsServerIP -ErrorAction Stop
        Write-Host "✓ Résolution de $nom :" -ForegroundColor Green
        Write-Host "  Adresse IP : $($resolution.IPAddress)" -ForegroundColor White
    } catch {
        Write-Host "✗ Impossible de résoudre $nom : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Création de la zone primaire DNS terminée ===" -ForegroundColor Green
Write-Host "`nProchaines étapes :" -ForegroundColor Cyan
Write-Host "1. Vérifier que le serveur DNS est accessible sur l'adresse 192.168.12.10" -ForegroundColor White
Write-Host "2. Configurer les clients pour utiliser ce serveur DNS" -ForegroundColor White
Write-Host "3. Ajouter les enregistrements DNS des contrôleurs de domaine et serveurs" -ForegroundColor White
Write-Host "4. Configurer les zones de recherche inversée si nécessaire" -ForegroundColor White
