# ianseo-install

Ce dépôt contient les définitions Docker nécessaires pour déployer rapidement une instance **Ianseo**
avec un conteneur PHP/Apache et une base de données MySQL.

---

## 🔁 Processus

1. Le conteneur **web** télécharge l’archive officielle `Ianseo_<version>.zip`.
2. Il extrait les fichiers dans `/var/www/html/ianseo`.
3. Il applique quelques corrections (hôte de base de données, typo connue, permissions, etc.).
4. Il active la configuration Apache fournie.

---

## 📁 Structure du projet

```
.
├── Dockerfile              # construction de l’image PHP/Apache
├── docker-compose.yml      # orchestration web + base de données
├── .env-prod               # exemple de variables d’environnement
├── web/                    # fichiers de configuration et scripts
│   ├── web_prep.sh         # script d’installation / configuration
│   ├── ianseo.conf         # configuration Apache (vhost)
│   ├── php.ini             # paramètres PHP personnalisés
│   └── phpinfo.php         # page de débogage
└── db_init/                # scripts SQL d’initialisation (optionnel)
```

---

## ⚙️ Variables d’environnement

Copiez `.env-prod` en `.env` ou définissez ces variables dans votre environnement. Elles sont utilisées
par `docker-compose` et le script de préparation.

| Variable             | Description                                    | Exemple                        |
|----------------------|------------------------------------------------|--------------------------------|
| `IANSEO_VERSION`     | Version d’Ianseo à télécharger (AAAAMMJJ)      | `20250210`                     |
| `WEB_PORT`           | Port hôte mappé vers le conteneur Apache       | `80`                           |
| `MYSQL_ROOT_PASSWORD`| Mot de passe du compte root MySQL              | `very_secure_root_password`    |
| `MYSQL_DATABASE`     | Nom de la base créée                           | `ianseo`                       |
| `MYSQL_USER`         | Utilisateur MySQL pour Ianseo                  | `ianseo`                       |
| `MYSQL_PASSWORD`     | Mot de passe de l’utilisateur                  | `ianseo`                       |

> 📝 **Sécurité** : changez impérativement les identifiants MySQL avant toute utilisation en production.

---

## 🚀 Démarrage

```bash
cp .env-prod .env       # ou modifiez .env selon vos besoins
docker-compose up -d --build
```

- L’image PHP/Apache est construite depuis le `Dockerfile`.
- Le script `/tmp/web_prep.sh` télécharge, installe et configure Ianseo.

### Une fois les conteneurs démarrés

- Application : `http://localhost:<WEB_PORT>/ianseo`
- Page de débogage PHP : `http://localhost:<WEB_PORT>/phpinfo.php`
- La base MySQL est initialisée avec les scripts présents dans `db_init/`.

---

## 🔧 Personnalisation & maintenance

- **Changer la version d’Ianseo** : mettez à jour `IANSEO_VERSION` et relancez `docker-compose up --build`.
- **Patchs et ajustements** : le script `web_prep.sh` réalise :
  - suppression de `Common/config.inc.php` pour forcer la création d’un nouveau fichier.
  - remplacement de `W_HOST='localhost'` par `ianseo_docker_db` dans `index.php`.
  - correction d’une erreur (MD5 vérifié) dans `UpdateDb.inc.php`.
  - ajustement des permissions pour `www-data`.
- **Scripts SQL** : placez‑les dans `db_init/` ; ils s’exécuteront lors du premier démarrage de MySQL.

---

## 🛠️ Bonnes pratiques

- N’incluez pas l’archive ZIP d’Ianseo dans l’image : elle est supprimée après extraction.
- Pour déboguer, ouvrez un shell :
  ```bash
  docker exec -it <container_name> bash
  ```
- Les volumes `web_volume` et `db_volume` conservent respectivement les fichiers PHP et les données MySQL.

---

## 📄 Licence & crédits

Ce projet fournit simplement un installateur Docker pour Ianseo. L’archive est téléchargée depuis
le site officiel : https://ianseo.net

---
