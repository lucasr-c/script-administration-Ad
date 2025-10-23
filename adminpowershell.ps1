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