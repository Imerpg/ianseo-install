# ianseo-install

Ce dépôt contient les définitions Docker nécessaires pour déployer rapidement une instance **Ianseo** prête à l'emploi avec un conteneur PHP/Apache et une base de données MySQL.

---

## ⚙️ Variables d’environnement

Copiez `.env-prod` en `.env` ou définissez ces variables dans votre environnement. Elles sont utilisées par `docker-compose` et le script de préparation (`entrypoint.sh`).

| Variable              | Description                               | Exemple                     |
| :-------------------- | :---------------------------------------- | :-------------------------- |
| `IANSEO_VERSION`      | Version d’Ianseo à télécharger (AAAAMMJJ) | `20250210`                  |
| `WEB_PORT`            | Port hôte mappé vers le conteneur Apache  | `80`                        |
| `MYSQL_ROOT_PASSWORD` | Mot de passe du compte root MySQL         | `very_secure_root_password` |
| `MYSQL_DATABASE`      | Nom de la base créée                      | `ianseo`                    |
| `MYSQL_USER`          | Utilisateur MySQL pour Ianseo             | `ianseo`                    |
| `MYSQL_PASSWORD`      | Mot de passe de l’utilisateur ianseo      | _votre_mot_de_passe_        |

> 📝 **Sécurité** : Changez impérativement les identifiants MySQL avant toute utilisation en production.

---

## 🚀 Démarrage

```bash
cp .env-prod .env # ou modifiez .env selon vos besoins
docker compose up -d --build
```

Une fois les conteneurs démarrés :

- **Application** : `http://localhost:<WEB_PORT>/ianseo/`
- **Page de débogage PHP** : `http://localhost:<WEB_PORT>/phpinfo.php`

La base MySQL est initialisée automatiquement au premier démarrage.

---

## 🔄 Fonctionnement de l'installation automatisée

Le conteneur Web utilise un script d'entrée (`web/entrypoint.sh`) qui automatise l'intégralité du déploiement.

1. **Téléchargement & extraction**
   Télécharge automatiquement la version d'Ianseo spécifiée par `IANSEO_VERSION` depuis les serveurs officiels et l'extrait dans :
   `/var/www/html/ianseo/`

2. **Attente de la base de données**
   Boucle de vérification jusqu'à ce que le conteneur MySQL soit prêt à accepter des connexions.

3. **Configuration réseau & accès**
   Génère automatiquement le fichier `Common/config.inc.php` avec les identifiants de la base de données et les paramètres de limites mémoire/temps d'exécution PHP requis.

4. **Initialisation de la base**
   Détecte si la base de données est vierge et importe le schéma SQL initial :
   `Install/install.sql`

5. **Mise à jour automatique du schéma PHP**
   Exécute le script d'upgrade natif d'Ianseo (`Install/upgrade.php`) en ligne de commande pour aligner la base de données sur la version des fichiers de l'application. Cela évite le message d'avertissement de mise à jour manuelle au premier accès navigateur.

6. **Droits d'accès**
   Réapplique les permissions `www-data` sur l'ensemble des fichiers avant d'exécuter Apache.

---

## ⚠️ Warnings & Mises en garde

### ⚠️ Premier démarrage & volumes persistants

Si vous modifiez les scripts d'initialisation SQL ou la version d'Ianseo après un premier lancement, les modifications ne seront pas réappliquées automatiquement sur une base déjà créée.

Pour réinitialiser complètement l'environnement et relancer la procédure d'installation automatique, supprimez les volumes associés :

```bash
docker compose down -v
docker compose up --build -d
```

### ⚠️ Temps d'attente au premier lancement

Lors du premier démarrage, l'initialisation de MySQL et le téléchargement/décompression de l'archive Ianseo (environ 65 Mo) peuvent prendre entre **15 et 45 secondes** selon votre connexion réseau et vos performances disque.  
_Ne coupez pas le conteneur pendant cette étape._

### ⚠️ Nom de domaine / port dans l'URL

N'oubliez pas d'inclure le slash final dans l'URL :
`http://localhost/ianseo/`  
Sans ce slash, Apache peut tenter une redirection vers le port interne du conteneur selon votre configuration proxy/hôte.

---

## 🛠️ Bonnes pratiques

- N’incluez pas l’archive ZIP d’Ianseo dans l’image Docker : elle est récupérée à la volée et supprimée immédiatement après extraction.

### Déboguer ou inspecter les conteneurs

- **Conteneur Web** :
    ```bash
    docker exec -it ianseo-install-web-1 bash
    ```
- **Conteneur MySQL** :
    ```bash
    docker exec -it ianseo-install-db-1 bash
    ```

### Volumes persistants

Les volumes suivants conservent respectivement les fichiers de l'application et les tables MySQL :

- `web_volume` — Fichiers de l'application
- `db_volume` — Tables MySQL

---

## 📄 Licence & crédits

Ce projet fournit un installateur automatisé Docker pour Ianseo.

L’archive applicative est téléchargée directement depuis le site officiel :  
[https://ianseo.net](https://ianseo.net)
