Import-Module ActiveDirectory

# Variables globales
$domainPath = "DC=test,DC=local"
$password = ConvertTo-SecureString "P@ssword123" -AsPlainText -Force
$cheminBase = "C:\Partages"

# 1. Création des Unités organisationnelles
@("Direction", "RH", "Informatique") | ForEach-Object {
    New-ADOrganizationalUnit -Name $_ -Path $domainPath -ErrorAction SilentlyContinue
    Write-Host "OU $_ créée ou existante"
}

# 2. Création de 5 utilisateurs par service
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
    New-ADUser -SamAccountName $samAccountName `
               -UserPrincipalName "$samAccountName@test.local" `
               -Name "$($user.Prenom) $($user.Nom)" `
               -GivenName $user.Prenom `
               -Surname $user.Nom `
               -Path $ouPath `
               -AccountPassword $password `
               -Enabled $true `
               -ChangePasswordAtLogon $true  `
               -PasswordNeverExpires $false -ErrorAction SilentlyContinue
    Write-Host "Utilisateur $samAccountName créé dans $($user.OU)"
}
Write-Host "15 utilisateurs créés."

# 3. Création des groupes de sécurité
$groupes = @(
    @{Name="GRP_Direction"; Description="Groupe de sécurité pour Direction"},
    @{Name="GRP_RH"; Description="Groupe de sécurité pour Ressources Humaines"},
    @{Name="GRP_IT"; Description="Groupe de sécurité pour Informatique"}
)
foreach ($groupe in $groupes) {
    New-ADGroup -Name $groupe.Name `
                -GroupScope Global `
                -GroupCategory Security `
                -Path $domainPath `
                -Description $groupe.Description -ErrorAction SilentlyContinue
    Write-Host "Groupe $($groupe.Name) créé."
}

# 4. Assignation des utilisateurs aux groupes
$utilisateursGroupes = $utilisateurs | ForEach-Object {
    [PSCustomObject]@{
        SamAccountName = "$($_.Prenom).$($_.Nom)"
        Groupe = switch ($_.OU) {
            "Direction" { "GRP_Direction" }
            "RH" { "GRP_RH" }
            "Informatique" { "GRP_IT" }
        }
    }
}

foreach ($user in $utilisateursGroupes) {
    try {
        Add-ADGroupMember -Identity $user.Groupe -Members $user.SamAccountName -ErrorAction Stop
        Write-Host "✓ $($user.SamAccountName) ajouté au groupe $($user.Groupe)" -ForegroundColor Green
    } catch {
        Write-Host "Erreur ajout $($user.SamAccountName) : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 5. Création et partage des dossiers
if (-not (Test-Path $cheminBase)) {
    New-Item -Path $cheminBase -ItemType Directory | Out-Null
    Write-Host "Création dossier base $cheminBase"
}

$services = @(
    @{Nom="Informatique"; Share="Informatique$"},
    @{Nom="RH"; Share="RH$"},
    @{Nom="Direction"; Share="Direction$"}
)
foreach ($service in $services) {
    $cheminService = Join-Path $cheminBase $service.Nom
    if (-not (Test-Path $cheminService)) {
        New-Item -Path $cheminService -ItemType Directory | Out-Null
        Write-Host "Dossier $($service.Nom) créé"
    }
    if (-not (Get-SmbShare -Name $service.Share -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $service.Share -Path $cheminService -FullAccess "Administrateurs" | Out-Null
        Write-Host "Partage $($service.Share) créé"
    }
}

# Attribution des droits NTFS
foreach ($service in $services) {
    $pathService = Join-Path $cheminBase $service.Nom
    $groupe = "GRP_$($service.Nom.Substring(0,3).ToUpper())"
    $acl = Get-Acl $pathService
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("test\$groupe","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($rule)
    Set-Acl -Path $pathService -AclObject $acl
    Write-Host "Droits FullControl accordés à $groupe sur $pathService"
}

Write-Host "Script terminé : OUs, utilisateurs, groupes, affectations, dossiers partagés et droits créés."
