## Pré-requis pour l'atelier
#### Contrôleur

* Machine Debian 8/9 ou Ubuntu ⩾ 14.04 (ou MacOS X si vous savez vous débrouiller ou Windows 10 si vous savez utiliser les VMs Ubuntu intégrées)
* Python 2.6/2.7 ou 3.5+
* Accès SSH en root
* Avoir une clé SSH

#### Machine gérée :
* Machine Debian 8/9 ou Ubuntu ⩾ 14.04
* Accés SSH en root
* Au moins Python 2.6 sur la VM \o/

---
## Préparation
* Ajouter le dépot Ansible puis l'installer (c.f.: http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-apt-ubuntu)
* Copier votre clé SSH publique sur la machine gérée 

---
## YAML QÉSACO ?
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
## Hello, World !
Fichier de configuration : ansible.cfg
```
[defaults]
inventory  = ./hosts
```
Fichier d'inventaire : hosts
```
serveurweb1 ansible_host=ipmachine1 ansible_user=root 
serveurweb2 ansible_host=ipmachine2 ansible_user=root
```
Fichier hello-world.yaml

```yaml
---
- hosts: serveurweb1
  tasks:
  - name: creation d'un fichier "hello-world.txt"
    file:
     path: /root/hello-world.txt
     state: touch
```
---
Exécution du playbook:

```
$ ansible-playbook hello-world.yaml 

PLAY [serveurweb1] *************************************************************

TASK [Gathering Facts] **********************************************************
ok: [serveurweb1]

TASK [creation d'un fichier "hello-world.txt"] **********************************
changed: [serveurweb1]

PLAY RECAP **********************************************************************
serveurweb1                    : ok=2    changed=1    unreachable=0    failed=0   
```

Remarque: Si vous ne vous êtes pas encore connecté à la VM, ansible (ssh) vous demandera
---
Vérifications:
```shell
$ ssh root@ipmachine1
$ ls -l
> -rw-r--r-- 1 root root 0 Nov 14 09:50 hello-world.txt
```

---

## Playbook Nginx

Un petit playbook pour voir quelques actions de base.

```yaml
---
- hosts: serveurweb1
  tasks:
  - name: installation de django
    pip:
      name: django
      virtualenv: /home/python1/django-test/
      virtualenv_python: python3.6

  - name: creation app django
    command: /home/python1/django-test/bin/django-admin startproject www .
    # idempotence !
    args:
      chdir: /home/python1/django-test
      creates: /home/python1/django-test/www/

  - name: creer le dossier utilisateur de systemd
    file:
      state: directory
      dest: /home/python1/.config/systemd/user/
      recurse: yes
      owner: python1
      group: python1

  - name: installation du service systemd
    copy:
      src: django-python1.service
      dest: /home/python1/.config/systemd/user/
    notify: execution du serveur debug de django

  handlers:
  - name: execution du serveur debug de django
    systemd:
      name: django-python1.service
      state: restarted
      user: yes
      daemon_reload: yes
      #enabled: true

```
---

## [PIPO] idempotence

**il faut que le playbook aie le même comportement qu'il soit joué une ou plusieurs fois**

Par exemple :
* on ne recréée pas les dossiers
* on ne ré-installe pas un package.

Pourquoi ?
* installer une machine en rejouant le playbook de son groupe
* patches : appliquer tout le playbook pour corriger toutes les machines (on ne crée un playbook de patch)

Comment ?
* La plupart des modules sont idempotents
* Sauf command / shell / script / raw : ajouter un argument `creates:`
* on peut rendre les tâches conditionnelles avec `when:`


---
## Rôle
Les rôles permettent de découper un playbook en morceaux réutilisables.

Voici une arborescence basique:

```
roles/
└── django
    ├── files
    │   └── django-python1.service
    ├── handlers
    │   └── main.yml
    └── tasks
        └── main.yml
```
On découpe les sections du playbook:

* les tâches *tasks* dans *django/tasks/main.yml*
* les tâches *handlers* dans *django/handlers/main.yml*
* les fichiers dans le dossier *django/files*,
* dans *tasks/main.yml*, on le référence par *files/xxx*, ansible résoud le dossier relatif par rapport au chemin du rôle

On a un nouveau fichier de playbook django-roles.yaml

```
---
- hosts: serveurweb1
  roles:
    - nginx
```
---
## Templates de fichiers

Ansible permet d'utiliser des templates jinja2 :

* Créer un dossier *roles/django/templates* 
* Copier depuis la cible *django-test/www/settings.py* en tant que *roles/django/templates/settings.py.j2* 
* Editer ce fichier et remplacer ALLOWED\_HOSTS par :

```yaml
ALLOWED_HOSTS = ["{{ansible_hostname}}"]
```

* Ajouter cette tâche à votre role :
```yaml
- name: correction des settings
  template:
    src: templates/settings.py.j2
    dest: /home/python1/django-test/www/settings.py
  notify: execution du serveur debug de django
```
* relancer le playbook, mais cette fois avec l'option *--diff*

*ansible_hostname* est un *fact* (variable créer dynamiquement) récupéré lors de la tâche *Gathering Facts*.

On peut afficher la liste des facts en appelant le module *setup* :
```
$ ansible hote -m setup | less
serveurweb1 | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "192.168.y.x",
        ],
        "ansible_distribution": "Ubuntu", 
        "ansible_distribution_major_version": "16", 
        "ansible_distribution_release": "xenial", 
        "ansible_distribution_version": "16.04", 
        "ansible_env": {
            "HOME": "/root", 
            "LANG": "fr_FR.UTF-8", 
            "PWD": "/root", 
            "SHELL": "/bin/bash", 
            "USER": "root", 
        }, 
        "ansible_hostname": "serveurweb1", 
		"ansible_user_dir": "/root", 
[...]
```
Plus puissant, on peut utiliser les facts déjà moissonnés sur les autres clients, ils sont accessibles dans le dictionnaire *hostvars["clientx"]*

Utilisation :

* remplacement par le contenu de la variable: `{{variable}}`
* filtre sur la variable: `{{variable|upper}}`
* structures de controle : 
```
{% if ansible_distribution_version == "xenial" %}
            youpi
{% endif %}
```
* Commentaires: `{# il était un petit navire #}`

Ca marche aussi dans les tâches

---
## Templates de playbook
Dans *roles/django/tasks/main.yml*, mettre des guillemets dans toutes les chaînes qui contiennent *python1*: 
```
virtualenv: "/home/python1/django-test/"
```
Puis remplacer */home/python1* par `{{ansible_env.PWD}}`
```
virtualenv: "{{ansible_env.PWD}}/django-test/"
```
Puis remplacer les *python1* restant par `{{ansible_user_id}}`


On vient de rendre le rôle insenssible au nom de l'utilisateur.

Pour vérifier que tout fonctionne encore, lancer le playbook avec l'option *--check*

Pour étendre le parc machines sur lequel on applique le playbook, editez-le et remplacez le contenu de *hosts* par *all* puis relancer-le.

---
## Inventaire

Le fichier *hosts* qui ressemble à un fichier "ini".
On peut créer des groupes (une machine peut appartenir à plusieurs groupes).

```
serveurweb1 variables
serveurweb2 variables

[webserver]
serveurweb[1:9]

[django]
serveurweb2

```
#### Gestion des variables
On peut mettre des variables (utilisés dans les templates comme des facts) dans l'inventaire mais c'est limité.

On peut creer deux dossiers *host_vars* et *group_vars*
contenant des fichiers portant le nom des hôtes / groupes,
contenant des structures en yaml ou json

```
host_vars/
├── serveurweb1.yaml
└── serveurweb2.yaml
group_vars/
└── webserver.yaml
```
On peut donc stocker des tableaux, dictionnaires...

On peut aussi stocker des variables dans les rôles (valeurs par défaut) 

On peut surcharger les variables, attention à l'ordre de surcharge :

http://docs.ansible.com/ansible/latest/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable

---
## Aller plus loin
#### Où trouver des infos
http://docs.ansible.com/ansible/latest/index.html

* filtres des templates jinja2 ... mais aussi Ansible :
* documentations des modules : http://docs.ansible.com/ansible/latest/modules_by_category.html
* Ansible Galaxy

#### Possibilités

* structures de contrôle dans les rôles
* enregistrer le résutlat des tâches dans des variables
* mettre les facts en cache.
* environnements dans les inventaires
* inventaires dynamiques (scripts qui listent les machines et leurs variables en json/yaml)
* création de modules

## The END

Sébastien DA ROCHA

sebastien@da-rocha.net

Alcé LAFRANQUE

alce@lafranque.net
