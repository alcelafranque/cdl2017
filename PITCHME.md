# Pré-requis
#### Contrôleur

* Machine debian 8/9 
* Python récent & python-pip
* Accès SSH en root
* Avoir une clé SSH


#### Machine gérée :
* Machine debian 8/9 ou Ubuntu ⩾ 14.04
* Accés SSH en root
* Au moins python 2.6 sur la VM \o/
---
@title[Préparation]
# Préparation
* Ajouter le dépot ansible 
* Copier la clé publique sur la machine gérée 

---
@title[YAML]
# YAML QÉSACO ?
* Equivalent de JSON/XML en moins verbeux.
* Sensible à l'indentation 
* Permet de modeliser de scalaires, tableaux et dictionnaires
```yaml
    ---
    variable: bar   
    tableau:
      - foo1
      - foo2
      - bar
    dictionnaire:
      foo1: bar
      foo2: tabac
```

---
@title[Hello-wordl-1/3]
# Hello, World ! 1/3
```
[defaults]
inventory      = ./hosts
```
inventaire hosts
```
serveurweb1 ansible_host=ipmachine1 ansible_user=root 
serveurweb2 ansible_host=ipmachine2 ansible_user=root
```


---
@title[Hello-wordl-2/3]
# Hello, World ! 2/3
```yaml
    ---
    - hosts: virt-python1
      tasks:
        - name: creation d'un fichier "hello-world.txt"
          file:
            path: /home/python1/hello-world.txt
            state: touch
```



