<H1> Script permettant d'obtenir plusieurs informations sur le pc (CPU, GPU, Ram, adresse IP/MAC, OS, Utilisateur ) <H1>

![Audit pc](<Capture d'écran 2025-10-23 132400.png>) 

<H1> TP 1 : Administration Active Directory, DNS et DHCP (PowerShell &
Automatisation) <H1>

<H2> Après avoir installé Windows Server 2025 sur une machine virtuelle, il était nécessaire de lui ajouter via powershell différents rôles comme : l'active directory, DHCP, DNS, RDS <H2>

<H2> Après avoir installé les 3 rôles je vais administrer l'active directory <H2>

<H1> Création de 3 unités organisationnelle : RH, Direction, IT <H1>

![Création OU](<2 création d'ou.png>)

<H1> Création de 5 utilisateurs par unités organisationnelle <H1>

![Création utilisateur direction](<2.1 création utilisateur direction.png>)
![Création utilisateur informatique](<2.1 création utilisateur informatique.png>)
![Création utilisateur RH](<2.1 création utilisateur RH.png>)

<H1> Création de 3 groupes de sécurité : GRP_Direction, GRP_IT et GRP_RH <H1>

![Création groupes de sécurité](<3. création des groupes.png>)
![Ajout des utilisateurs dans le groupe direction](<4 ajout des users dans le groupe direction.png>)
![Ajout des utilisateurs dans le groupe informatique](<4 ajout des users dans le groupe informatique.png>)
![Ajout des utilisateurs dans le groupe RH](<4 ajout des users dans le groupe rh.png>)
![Création des dossiers partagés](<5 création des dossiers partagés.png>)
![Vérification des droits NTF](<5.1 vérification des droits ntfs.png>)
![Ajout de 5 pc](<6 création de 5 pc.png>)
![Création dns](<7 powershell dns.png>)
![Vérification redirecteur](<8 vérification redirecteur.png>)
![Création DHCP + étendue](<9 création étendue.png>)
