# Script PowerShell pour collecter les infos sur les composants du pc (CPU, RAM, GPU, OS+ IP et adresse MAC)

# Récupération de la date
$Date = Get-Date -Format "dd/MM/yyyy HH:mm"
$ComputerName = $env:COMPUTERNAME
$User = $env:USERNAME
$OS = (Get-ComputerInfo).OsName
$CPU = (Get-WmiObject Win32_Processor).Name
$RAM = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB

# Récupération des informations IP et MAC
$IPConfig = Get-NetIPConfiguration | Where-Object {$_.IPv4Address -ne $null}
$IPAddress = $IPConfig.IPv4Address.IPAddress
$MACAddress = $IPConfig.NetAdapter.MacAddress

# Récupération des informations GPU
$GPUInfo = Get-WmiObject Win32_VideoController
$GPUName = $GPUInfo.Name -join ', '
$GPUMemory = ($GPUInfo.AdapterRAM / 1GB) -join ', '

# Construction du rapport
$Rapport = @"
===== RAPPORT SYSTEME =====
Machine : $ComputerName
Utilisateur : $User
OS : $OS
Processeur : $CPU
RAM (Go) : $([math]::Round($RAM,2))
Adresse IP : $IPAddress
Adresse MAC : $MACAddress
GPU : $GPUName
Mémoire GPU (Go) : $([math]::Round($GPUMemory,2))
Date : $Date
===========================
"@

# Création du dossier d'export s'il n'existe pas
if (-not (Test-Path './exports')) {
    New-Item -Path './exports' -ItemType Directory | Out-Null
}

# Export du rapport dans un fichier texte
$Rapport | Out-File './exports/system_info.txt' -Encoding UTF8

# Affichage d'un message de confirmation
Write-Host "Rapport généré dans exports/system_info.txt" -ForegroundColor Green
