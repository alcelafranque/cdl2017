# Pour utiliser deux machines lors de l'atelier

1) Inscrivez votre nom / nick dans une cellule vide de la colonne nick utilisateur

https://framacalc.org/oYe2CIsoGT

Si vous ne notez pas votre nick, quelqu'un d'autre pourras vous piquer votre machine

2) connectectez vous à la machine avec le user *utilisateur2017*

3) passez en super utilisateur pour ajouter votre clé SSH sur la machine

```
sudo su
vim ~/.ssh/authorized_keys
```

Remarque 1 : afficher votre clé publique SSH 
```
cat ~/.ssh/id_rsa.pub
```

Remarque 2 : créer votre clé SSH 
```
ssh-keygen
```

