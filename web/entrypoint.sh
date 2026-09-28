#!/bin/bash
set -e

INSTALL_DIR="/var/www/html/ianseo"
CONFIG_FILE="$INSTALL_DIR/Common/config.inc.php"
DB_HOST="ianseo_docker_db"

echo "==> Démarrage du script d'entrée..."

# 1. Téléchargement et extraction
if [ ! -f "$INSTALL_DIR/index.php" ]; then
    echo "==> Téléchargement de Ianseo ${IANSEO_VERSION}..."
    mkdir -p "$INSTALL_DIR"
    curl -L "https://ianseo.net/Release/Ianseo_${IANSEO_VERSION}.zip" -o /tmp/ianseo.zip
    unzip -q /tmp/ianseo.zip -d "$INSTALL_DIR"
    rm -f /tmp/ianseo.zip
fi

# 2. Attente de la base de données
echo "==> Connexion à la base de données (${DB_HOST})..."
until mysql -h "${DB_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --skip-ssl -e "SELECT 1;" > /dev/null 2>&1; do
    echo "MySQL n'est pas encore prêt, attente de 2s..."
    sleep 2
done

echo "==> Connexion MySQL réussie !"

# 3. Génération de Common/config.inc.php
if [ ! -f "$CONFIG_FILE" ]; then
    echo "==> Génération de Common/config.inc.php..."
    mkdir -p "$INSTALL_DIR/Common"
    cat <<EOF > "$CONFIG_FILE"
<?php
\$CFG->R_HOST = '${DB_HOST}';
\$CFG->R_USER = '${MYSQL_USER}';
\$CFG->R_PASS = '${MYSQL_PASSWORD}';

\$CFG->W_HOST = '${DB_HOST}';
\$CFG->W_USER = '${MYSQL_USER}';
\$CFG->W_PASS = '${MYSQL_PASSWORD}';

\$CFG->DB_NAME = '${MYSQL_DATABASE}';
\$CFG->ROOT_DIR = '/ianseo/';

ini_set('max_execution_time', '120');
ini_set('memory_limit', '128M');
?>
EOF
fi

# 4. Importation du schéma SQL initial
TABLE_EXISTS=$(mysql -h "${DB_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --skip-ssl "${MYSQL_DATABASE}" -e "SHOW TABLES LIKE 'Parameters';" | grep -c "Parameters" || true)

if [ "$TABLE_EXISTS" -eq 0 ]; then
    echo "==> Importation du schéma SQL..."
    mysql -h "${DB_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --skip-ssl "${MYSQL_DATABASE}" < "$INSTALL_DIR/Install/install.sql"
fi

# 5. Application des mises à jour automatiques via PHP
echo "==> Exécution de la mise à jour automatique du schéma PHP..."
php "$INSTALL_DIR/Install/upgrade.php" || true

# 6. Permissions et lancement d'Apache
chown -R www-data:www-data "$INSTALL_DIR"
chmod -R u+wX "$INSTALL_DIR"

echo "==> Démarrage du serveur Web..."
exec apache2-foreground