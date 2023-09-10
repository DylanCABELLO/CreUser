#!/bin/bash

#       Objectif : créer des utilisateurs, créer des groupes et ajouter des utilisateurs dans des groupes à partir d'un fichier creuser.txt
#       Prérequis :
#               creuser.txt: fichier contenant les associations utilisateurs et groupes
#		disposer des droits super utilisateur (sudo)
#       Exécution : ./creuser.sh


FICHIER=$(<creuser.txt)


#Menu help
if [ "$1" = "--help" ]; then
	printf "\033[1;96mExécution:\033[0m\n  creuser.sh [parametres]\n"
	printf "\033[1;96mObjectif:\n  Crée\033[0m des utilisateurs et des groupes et\n  \033[1;96mRajoute\033[0m des utilisateurs dans des groupes à partir du fichier \033[1;96mcreuser.txt\033[0m\n"
	printf "\033[1;96mPrérequis:\033[0m\n  \033[1mcreuser.txt\033[0m: Fichier contenant les associations utilisateurs-groupes et dans le même repertoire que ce script\n  \033[1msudo\033[0m: Disposer des droits super utilisateur\n"
	exit 0
fi



declare -A noms
declare -A grps

#Récupére les noms et les groupes dans le fichier
nomsUse=$(echo "$FICHIER" | cut -d ":" -f1)
grpUse=$(echo "$FICHIER" | cut -d ":" -f2)

cmpt=0
for i in $nomsUse; do
	noms+=([$cmpt]="$i")
	let cmpt+=1
done

cTemp=0
for i in $grpUse; do
	grps+=([$cTemp]="$i")
	let cTemp+=1
done

nUsr=()
nGrp=()
cTemp=0

while [[ $cTemp -lt $cmpt ]]; do
	cUsr=${noms[$cTemp]}
	cGrp=${grps[$cTemp]}

	#vérifie qu'un utilisateur n'existe pas déjà
	if ! id "$cUsr" >/dev/null 2>&1; then
		useradd -M "$cUsr"
		nUsr+=("$cUsr")	
	fi
	#vérifie qu'un groupe n'existe pas
	if ! getent group "$cGrp" >/dev/null ;then
		groupadd "$cGrp"
		nGrp+=("$cGrp")
	fi
	((cTemp+=1))
done

cTemp=0
declare -A manipU
while [[ $cTemp -lt $cmpt ]]; do
	nom=${noms[$cTemp]}
	grp=${grps[$cTemp]}
	
	#vérifie qu"un nom est présent dans manipU
	if ! getent group $grp | grep &>/dev/null "$nom"; then
		if [[ "${!manipU[@]} " =~ "$nom" ]]; then
			manipU[$nom]+=", $grp"
		else
			manipU+=([$nom]="$grp")
		fi
	fi
	usermod -a -G "$grp" "$nom"
	((cTemp+=1))
done


#Log
DATEX=$(date +%Y%m%d%H%M)

LOGb="$DATEX $USER"

LOGc="$LOGb Utilisateurs créés: ${nUsr[@]}"
LOGg="$LOGb Groupes créés: ${nGrp[@]}"
ajt=()
for nom in ${!manipU[@]}; do
	ajt+=" $nom: ${manipU[$nom]} |"
done

LOGa="$LOGb Ajouts: (${ajt[@]})"
cd /var/log/users
echo "$LOGc">>creuser.log
echo "$LOGg">>creuser.log
echo "$LOGa">>creuser.log
cd
exit 0
