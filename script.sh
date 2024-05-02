#!/bin/bash

# Installation des dépendances
sudo apt update
sudo apt install -y git npm docker.io docker-compose

# Vérification des versions installées
git --version
npm --version
docker --version
docker-compose --version

# Clonage du dépôt Git
git clone https://github.com/ESGI-4eme-annee/realtime-quizz.git

# Déplacement des fichiers .env
mv ./backend/.env ./realtime-quizz/backend/.env
mv ./frontend/.env ./realtime-quizz/frontend/.env

# Changement du répertoire de travail
cd realtime-quizz

#  Log du statut de Docker
sudo systemctl status docker --no-pager

#Ajout de l'utilisateur au groupe Docker s'il n'y est pas déjà
if ! grep -q docker /etc/group; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER


#Lancement de Docker Compose
sudo docker-compose up -d