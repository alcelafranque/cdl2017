#! /bin/bash
serveur=$1

serveur_num=$(echo "$serveur"| sed 's/serveur[AB]\+//')

password=$( sed -n ${serveur_num}p ./passwords_crypted)

echo $password

