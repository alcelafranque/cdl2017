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

Remarque: Si vous ne vous êtes pas encore connecté à la VM, ansible (ssh) vous demandera de confirmer son authenticité 

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
- hosts: all
  tasks:
  - name: Installation paquets
    apt:
      name: nginx
      state: present

  - name: supression du vhost par default de nginx
    file:
      path: /etc/nginx/sites-enabled/default
      state: absent
    notify: restart nginx

  - name: copie de la conf nginx
    copy:
      src: ./cdl2017.conf
      dest: /etc/nginx/sites-available/
    notify: restart nginx

  - name: active le site CDL 2017
    command: ln -s /etc/nginx/sites-available/cdl2017.conf /etc/nginx/sites-enabled/cdl2017.conf
    # idempotence !
    args:
      creates: /etc/nginx/sites-enabled/cdl2017.conf
    notify: restart nginx

  - name: création de l'utilisateur cdl2017
    user:
      name: cdl2017

  - name: création du dossier public sur l'utilisateur
    file:
      path: /home/cdl2017/public
      state: directory

  - name: copie fichier index
    copy:
      src: ./index.html
      dest: /var/www/html/

  - name: copie fichier index utilisateur
    copy:
      src: ./my_index.html
      dest: /home/cdl2017/public/

  - name: copie fichier d'erreur 404
    copy:
      src: ./user_not_found.html
      dest: /var/www/html/

  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
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
roles
└── nginx
    ├── files
    │   ├── cdl2017.conf
    │   ├── index.html
    │   ├── my_index.html
    │   └── user_not_found.html
    ├── handlers
    │   └── main.yml
    └── tasks
        └── main.yml


```
On découpe les sections du playbook:

* les tâches *tasks* dans *nginx/tasks/main.yml*
* les tâches *handlers* dans *nginx/handlers/main.yml*
* les fichiers dans le dossier *nginx/files/*,
* dans *tasks/main.yml*, on le référence par *files/xxx*, ansible résoud le dossier relatif par rapport au chemin du rôle

On a un nouveau fichier de playbook nginx-roles.yaml

```
---
- hosts: serveurweb1
  roles:
    - nginx
```
---
## Templates de fichiers

Ansible permet d'utiliser des templates jinja2 :

* Créer un dossier *roles/nginx/templates* 
* Déplacer le fichier *roles/nginx/files/index.html* en tant que *roles/nginx/templates/index.html.j2* 
* Editer ce fichier et remplacer le titre par :

```html
<h1>Bienvenue sur la machine {{ansible_hostname}}!</h1>
```

* modifier la tâche de votre role (c'était une tâche *copy*):
```yaml
- name: copie fichier index
  template:
    src: templates/index.html.j2
    dest: /var/www/html/index.html
```
* relancer le playbook, mais cette fois avec l'option *--diff*

*ansible_hostname* est un *fact* (variable créer dynamiquement) récupéré lors de la tâche *Gathering Facts*.

On peut afficher la liste des *facts* en appelant le module *setup* :
```
$ ansible serveurweb1 -m setup | less
serveurweb1 | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "192.168.y.x",
        ],
[...]
        "ansible_architecture": "x86_64", 
        "ansible_bios_date": "04/01/2014", 
        "ansible_bios_version": "Ubuntu-1.8.2-1ubuntu1", 
[...]
        "ansible_distribution": "Debian", 
        "ansible_distribution_file_parsed": true, 
        "ansible_distribution_file_path": "/etc/os-release", 
        "ansible_distribution_file_variety": "Debian", 
        "ansible_distribution_major_version": "9", 
        "ansible_distribution_release": "stretch", 
        "ansible_distribution_version": "9.0", 
[...]
        "ansible_env": {
            "HOME": "/root", 
            "LANG": "en_US.UTF-8", 
            "LANGUAGE": "en_US.UTF-8", 
            "LC_ALL": "en_US.UTF-8", 
            "LOGNAME": "root", 
            "MAIL": "/var/mail/root", 
            "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 
            "PWD": "/root", 
[...]
        "ansible_form_factor": "Other", 
        "ansible_fqdn": "scw-33443c", 
        "ansible_hostname": "scw-33443c", 
[...]
```
Plus puissant, on peut utiliser les facts déjà moissonnés sur les autres clients, ils sont accessibles dans le dictionnaire *hostvars["clientx"]*

Utilisation :

* remplacement par le contenu de la variable: `{{variable}}`
* filtre sur la variable: `{{variable|upper}}`
* structures de controle : 
```
{% if ansible_distribution_version == "stretch" %}
            youpi
{% endif %}
```
* Commentaires: `{# il était un petit navire #}`

Ca marche aussi dans les tâches

---
## Templates de playbook
On va faire en sorte que le message d'erreur aparaisse en français sur la première machine gérée et en anglais sur la seconde.

On renomme le fichier files/user_not_found.html en files/user_not_found-serverweb1.html.

Puis on copie ce fichier en tant que files/user_not_found-serverweb2.html et on le traduit en  anglais.

```html
<!DOCTYPE html>
<html>
    <head>
        <title>Unknown User</title>
    </head>
    <body>

        <h1>Errior</h1>
        <p>Oh, this user doesn't exists...</p>

    </body>
</html>
```
On a désormais deux fichiers. Pour déployer le bon fichier sur chaque machine, il faut corriger les *tasks*, en rajoutant *-{{inventory_hostname}}* dans le nom du fichier source :

```yaml
- name: copie fichier d'erreur 404
  copy:
    src: "files/user_not_found-{{inventory_hostname}}.html"
    dest: /var/www/html/user_not_found.html
```

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
