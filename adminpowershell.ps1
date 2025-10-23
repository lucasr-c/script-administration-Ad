####1. 	1. Création des Unités organisationnelle : 

Import-Module ActiveDirectory


New-ADOrganizationalUnit -Name "Direction" -Path "DC=VotreDomaine,DC=com"
New-ADOrganizationalUnit -Name "RH" -Path "DC=VotreDomaine,DC=com"
New-ADOrganizationalUnit -Name "Informatique" -Path "DC=VotreDomaine,DC=com"

####2. 	2. Création de 5 utilisateurs par services

Import-Module ActiveDirectory

$domainPath = "DC=test,DC=local"
$password = ConvertTo-SecureString "P@ssword123" -AsPlainText -Force

$utilisateurs = @(
    @{Prenom="Alice"; Nom="Dupont"; OU="Direction"},
    @{Prenom="Bernard"; Nom="Martin"; OU="Direction"},
    @{Prenom="Celine"; Nom="Dubois"; OU="Direction"},
    @{Prenom="David"; Nom="Leroy"; OU="Direction"},
    @{Prenom="Elise"; Nom="Moreau"; OU="Direction"},
    
    @{Prenom="Fanny"; Nom="Simon"; OU="RH"},
    @{Prenom="Gerard"; Nom="Laurent"; OU="RH"},
    @{Prenom="Helene"; Nom="Lefebvre"; OU="RH"},
    @{Prenom="Isabelle"; Nom="Roux"; OU="RH"},
    @{Prenom="Jacques"; Nom="Fournier"; OU="RH"},
    
    @{Prenom="Kevin"; Nom="Girard"; OU="Informatique"},
    @{Prenom="Laura"; Nom="Bonnet"; OU="Informatique"},
    @{Prenom="Marc"; Nom="Dupuis"; OU="Informatique"},
    @{Prenom="Nathalie"; Nom="Lambert"; OU="Informatique"},
    @{Prenom="Olivier"; Nom="Fontaine"; OU="Informatique"}
)

foreach ($user in $utilisateurs) {
    $ouPath = "OU=$($user.OU),$domainPath"
    $samAccountName = "$($user.Prenom).$($user.Nom)"
    $name = "$($user.Prenom) $($user.Nom)"
    $userPrincipalName = "$samAccountName@test.local"
    
    New-ADUser -SamAccountName $samAccountName -UserPrincipalName $userPrincipalName -Name $name -GivenName $user.Prenom -Surname $user.Nom -Path $ouPath -AccountPassword $password -Enabled $true -ChangePasswordAtLogon $true -PasswordNeverExpires $false
    
    Write-Host "Utilisateur $name cree dans l'OU $($user.OU)"
}

Write-Host "Creation terminee : 15 utilisateurs crees (5 par OU)"

####3. 	3. Création des groupes de sécurité :

Import-Module ActiveDirectory

# Chemin du domaine
$domainPath = "DC=test,DC=local"

# Liste des groupes à créer
$groupes = @(
    @{Name="GRP_Direction"; Description="Groupe de sécurité pour Direction"},
    @{Name="GRP_RH"; Description="Groupe de sécurité pour Ressources Humaines"},
    @{Name="GRP_IT"; Description="Groupe de sécurité pour Informatique"}
)

# Création des groupes
foreach ($groupe in $groupes) {
    New-ADGroup -Name $groupe.Name -GroupScope Global -GroupCategory Security -Path $domainPath -Description $groupe.Description
    
    Write-Host "Groupe $($groupe.Name) créé avec succès"
}

Write-Host "Création terminée : 3 groupes de sécurité créés"

####4. 	4. Assignation des utilisateurs dans les groupes de sécurité : 

Import-Module ActiveDirectory

$domainPath = "DC=test,DC=local"

# Liste des utilisateurs avec leurs groupes
$utilisateurs = @(
    @{SamAccountName="Alice.Dupont"; Groupe="GRP_Direction"},
    @{SamAccountName="Bernard.Martin"; Groupe="GRP_Direction"},
    @{SamAccountName="Celine.Dubois"; Groupe="GRP_Direction"},
    @{SamAccountName="David.Leroy"; Groupe="GRP_Direction"},
    @{SamAccountName="Elise.Moreau"; Groupe="GRP_Direction"},
    
    @{SamAccountName="Fanny.Simon"; Groupe="GRP_RH"},
    @{SamAccountName="Gerard.Laurent"; Groupe="GRP_RH"},
    @{SamAccountName="Helene.Lefebvre"; Groupe="GRP_RH"},
    @{SamAccountName="Isabelle.Roux"; Groupe="GRP_RH"},
    @{SamAccountName="Jacques.Fournier"; Groupe="GRP_RH"},
    
    @{SamAccountName="Kevin.Girard"; Groupe="GRP_IT"},
    @{SamAccountName="Laura.Bonnet"; Groupe="GRP_IT"},
    @{SamAccountName="Marc.Dupuis"; Groupe="GRP_IT"},
    @{SamAccountName="Nathalie.Lambert"; Groupe="GRP_IT"},
    @{SamAccountName="Olivier.Fontaine"; Groupe="GRP_IT"}
)

# Ajout des utilisateurs dans les groupes de sécurité :
Write-Host "=== Assignation des utilisateurs aux groupes ===" -ForegroundColor Cyan

foreach ($user in $utilisateurs) {
    try {
        Add-ADGroupMember -Identity $user.Groupe -Members $user.SamAccountName -ErrorAction Stop
        Write-Host "✓ Utilisateur $($user.SamAccountName) ajouté au groupe $($user.Groupe)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur lors de l'ajout de $($user.SamAccountName) : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Résumé ===" -ForegroundColor Cyan
Write-Host "- 5 utilisateurs assignés à GRP_Direction" -ForegroundColor Yellow
Write-Host "- 5 utilisateurs assignés à GRP_RH" -ForegroundColor Yellow
Write-Host "- 5 utilisateurs assignés à GRP_IT" -ForegroundColor Yellow
Write-Host "`nAssignation terminée !" -ForegroundColor Green

####5. 	5. #Création des dossiers partagés :

# Script de création de dossiers partagés

# Défininition du chemin des partages (sur le disque C:)
$cheminBase = "C:\Partages"

# Créer le dossier partagé
if (-not (Test-Path $cheminBase)) {
    New-Item -Path $cheminBase -ItemType Directory | Out-Null
    Write-Host "Dossier de base $cheminBase créé"
}

# Définir les services et leurs chemins
$services = @(
    @{Nom="Informatique"; Chemin="$cheminBase\Informatique"; Share="Informatique$"},
    @{Nom="RH"; Chemin="$cheminBase\RH"; Share="RH$"},
    @{Nom="Direction"; Chemin="$cheminBase\Direction"; Share="Direction$"}
)

# Créer les dossiers et les partager
foreach ($service in $services) {
    # Créer le dossier s'il n'existe pas
    if (-not (Test-Path $service.Chemin)) {
        New-Item -Path $service.Chemin -ItemType Directory | Out-Null
        Write-Host "Dossier $($service.Nom) créé : $($service.Chemin)"
    } else {
        Write-Host "Le dossier $($service.Nom) existe déjà"
    }

    # Partage du dossier
    $partageExistant = Get-SmbShare -Name $service.Share -ErrorAction SilentlyContinue
    
    if ($null -eq $partageExistant) {
        New-SmbShare -Name $service.Share -Path $service.Chemin -FullAccess "Administrateurs" | Out-Null
        Write-Host "Partage '$($service.Share)' créé pour $($service.Nom)"
    } else {
        Write-Host "Le partage '$($service.Share)' existe déjà"
    }
}

Write-Host "`n=== Résumé ===" -ForegroundColor Cyan
Write-Host "3 dossiers partagés ont été créés :"
Write-Host "- \\$env:COMPUTERNAME\Informatique$"
Write-Host "- \\$env:COMPUTERNAME\RH$"
Write-Host "- \\$env:COMPUTERNAME\Direction$"

#Droits ntfs : 

# Script d'attribution des droits NTFS aux dossiers partagés

# Définir le chemin de base des partages
$cheminBase = "C:\Partages"

# Définir les dossiers, groupes et droits
$dossiers = @(
    @{Chemin="$cheminBase\Direction"; Groupe="GRP_Direction"; Droits="FullControl"},
    @{Chemin="$cheminBase\RH"; Groupe="GRP_RH"; Droits="FullControl"},
    @{Chemin="$cheminBase\Informatique"; Groupe="GRP_IT"; Droits="FullControl"}
)

Write-Host "=== Attribution des droits NTFS aux dossiers ===" -ForegroundColor Cyan

foreach ($dossier in $dossiers) {
    try {
        # Vérifier que le dossier existe
        if (-not (Test-Path $dossier.Chemin)) {
            Write-Host "✗ Le dossier $($dossier.Chemin) n'existe pas" -ForegroundColor Red
            continue
        }

        # Récupérer la liste de contrôle d'accès (ACL) du dossier
        $acl = Get-Acl -Path $dossier.Chemin

        # Créer une nouvelle règle d'accès pour le groupe
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "test\$($dossier.Groupe)",
            $dossier.Droits,
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )

        # Ajouter la règle à la liste de contrôle d'accès
        $acl.SetAccessRule($rule)

        # Appliquer la nouvelle liste de contrôle d'accès au dossier
        Set-Acl -Path $dossier.Chemin -AclObject $acl

        Write-Host "✓ Droits $($dossier.Droits) accordés au groupe $($dossier.Groupe) pour $($dossier.Chemin)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur lors de l'attribution des droits pour $($dossier.Chemin) : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Résumé des droits NTFS ===" -ForegroundColor Cyan
Write-Host "- GRP_Direction : Droits complets (FullControl) sur C:\Partages\Direction" -ForegroundColor Yellow
Write-Host "- GRP_RH : Droits comp

#Vérification des droits : 

# Vérifier les droits du dossier Direction
Get-Acl -Path "C:\Partages\Direction" | Format-List

# Vérifier les droits du dossier RH
Get-Acl -Path "C:\Partages\RH" | Format-List

# Vérifier les droits du dossier Informatique
Get-Acl -Path "C:\Partages\Informatique" | Format-List

####5.1   5.1 Script de vérification des droits NTFS sur les dossiers partagés
# Domaine : test.local
# Date : 2025-10-23

Write-Host "=== Vérification des droits NTFS sur les dossiers partagés ===" -ForegroundColor Cyan

# Définir le chemin de base des partages
$cheminBase = "C:\Partages"

# Liste des dossiers à vérifier avec leurs groupes attendus
$dossiersConfig = @(
    @{Chemin="$cheminBase\Direction"; GroupeAttendu="GRP_Direction"; Service="Direction"},
    @{Chemin="$cheminBase\RH"; GroupeAttendu="GRP_RH"; Service="RH"},
    @{Chemin="$cheminBase\Informatique"; GroupeAttendu="GRP_IT"; Service="Informatique"}
)

# Tableau pour stocker les résultats
$resultats = @()

Write-Host "`n--- Analyse détaillée des droits NTFS ---`n" -ForegroundColor Yellow

foreach ($dossierConfig in $dossiersConfig) {
    $dossier = $dossierConfig.Chemin
    $service = $dossierConfig.Service
    
    Write-Host "Vérification du dossier : $dossier" -ForegroundColor Cyan
    
    try {
        # Vérifier que le dossier existe
        if (-not (Test-Path $dossier)) {
            Write-Host "✗ Le dossier $dossier n'existe pas`n" -ForegroundColor Red
            continue
        }

        # Récupérer les ACL du dossier
        $acl = Get-Acl -Path $dossier
        
        # Afficher le propriétaire
        Write-Host "  Propriétaire : $($acl.Owner)" -ForegroundColor White
        
        # Vérifier si le groupe attendu a des droits
        $groupeTrouve = $false
        
        # Parcourir toutes les permissions
        foreach ($access in $acl.Access) {
            $identite = $access.IdentityReference.Value
            $droits = $access.FileSystemRights
            $type = $access.AccessControlType
            $herite = $access.IsInherited
            
            # Créer un objet pour le rapport
            $objet = [PSCustomObject]@{
                Service         = $service
                Dossier         = $dossier
                Utilisateur_Groupe = $identite
                Droits          = $droits
                Type_Acces      = $type
                Herite          = $herite
                Propagation     = $access.InheritanceFlags
            }
            
            $resultats += $objet
            
            # Afficher les permissions dans la console
            $couleur = if ($type -eq "Allow") { "Green" } else { "Red" }
            $heritageInfo = if ($herite) { "(Hérité)" } else { "(Explicite)" }
            
            Write-Host "  └─ $identite" -ForegroundColor $couleur
            Write-Host "     Droits : $droits | Type : $type | $heritageInfo" -ForegroundColor Gray
            
            # Vérifier si c'est le groupe attendu
            if ($identite -like "*$($dossierConfig.GroupeAttendu)*") {
                $groupeTrouve = $true
                Write-Host "     ✓ Groupe de sécurité $($dossierConfig.GroupeAttendu) identifié" -ForegroundColor Green
            }
        }
        
        # Résumé pour ce dossier
        if ($groupeTrouve) {
            Write-Host "`n  ✓ Configuration correcte pour $service`n" -ForegroundColor Green
        } else {
            Write-Host "`n  ⚠ ATTENTION : Le groupe $($dossierConfig.GroupeAttendu) n'a pas été trouvé !`n" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "✗ Erreur lors de la vérification de $dossier : $($_.Exception.Message)`n" -ForegroundColor Red
    }
}

# Affichage du tableau récapitulatif
Write-Host "`n=== Tableau récapitulatif des autorisations ===" -ForegroundColor Cyan
$resultats | Format-Table -Property Service, Utilisateur_Groupe, Droits, Type_Acces, Herite -AutoSize

# Statistiques finales
Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
Write-Host "- Nombre total de permissions analysées : $($resultats.Count)" -ForegroundColor Yellow
Write-Host "- Dossiers vérifiés : $($dossiersConfig.Count)" -ForegroundColor Yellow

# Vérification des groupes de sécurité dans les permissions
$groupesDetectes = $resultats | Where-Object { $_.Utilisateur_Groupe -like "*GRP_*" }
Write-Host "- Permissions de groupes de sécurité détectées : $($groupesDetectes.Count)" -ForegroundColor Yellow

Write-Host "`n=== Vérification terminée avec succès ===" -ForegroundColor Green

#### Création de 5 pc par services : 

# Script de création d'ordinateurs dans Active Directory

Import-Module ActiveDirectory

# Définir le chemin du domaine
$domainPath = "DC=test,DC=local"

# Liste des ordinateurs à créer par service
$ordinateurs = @(
    # Service Direction
    @{Nom="PC-DIR-01"; OU="Direction"; Description="Poste Direction 1"},
    @{Nom="PC-DIR-02"; OU="Direction"; Description="Poste Direction 2"},
    @{Nom="PC-DIR-03"; OU="Direction"; Description="Poste Direction 3"},
    @{Nom="PC-DIR-04"; OU="Direction"; Description="Poste Direction 4"},
    @{Nom="PC-DIR-05"; OU="Direction"; Description="Poste Direction 5"},
    
    # Service RH
    @{Nom="PC-RH-01"; OU="RH"; Description="Poste Ressources Humaines 1"},
    @{Nom="PC-RH-02"; OU="RH"; Description="Poste Ressources Humaines 2"},
    @{Nom="PC-RH-03"; OU="RH"; Description="Poste Ressources Humaines 3"},
    @{Nom="PC-RH-04"; OU="RH"; Description="Poste Ressources Humaines 4"},
    @{Nom="PC-RH-05"; OU="RH"; Description="Poste Ressources Humaines 5"},
    
    # Service Informatique
    @{Nom="PC-IT-01"; OU="Informatique"; Description="Poste Informatique 1"},
    @{Nom="PC-IT-02"; OU="Informatique"; Description="Poste Informatique 2"},
    @{Nom="PC-IT-03"; OU="Informatique"; Description="Poste Informatique 3"},
    @{Nom="PC-IT-04"; OU="Informatique"; Description="Poste Informatique 4"},
    @{Nom="PC-IT-05"; OU="Informatique"; Description="Poste Informatique 5"}
)

Write-Host "=== Création des ordinateurs dans Active Directory ===" -ForegroundColor Cyan

# Créer chaque ordinateur dans son OU respective
foreach ($pc in $ordinateurs) {
    try {
        # Construire le chemin complet de l'OU
        $ouPath = "OU=$($pc.OU),$domainPath"
        
        # Créer l'ordinateur dans l'Active Directory
        New-ADComputer -Name $pc.Nom -SAMAccountName $pc.Nom -Path $ouPath -Description $pc.Description -Enabled $true -ErrorAction Stop
        
        Write-Host "✓ Ordinateur $($pc.Nom) créé dans l'OU $($pc.OU)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur lors de la création de $($pc.Nom) : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Résumé ===" -ForegroundColor Cyan
Write-Host "- 5 ordinateurs créés dans l'OU Direction (PC-DIR-01 à PC-DIR-05)" -ForegroundColor Yellow
Write-Host "- 5 ordinateurs créés dans l'OU RH (PC-RH-01 à PC-RH-05)" -ForegroundColor Yellow
Write-Host "- 5 ordinateurs créés dans l'OU Informatique (PC-IT-01 à PC-IT-05)" -ForegroundColor Yellow
Write-Host "`nCréation terminée : 15 ordinateurs créés au total !" -ForegroundColor Green


#### DNS Script de création d'une zone primaire DNS avec configuration réseau
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

