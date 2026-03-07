#!/bin/bash
# Arrête le script dès qu'une erreur survient
set -e

# Correction de la syntaxe de la variable
IANSEO_ZIP=/tmp/${IANSEO_VERSION}.zip
INSTALL_DIR=/var/www/html/ianseo
INDEX_PHP=$INSTALL_DIR/Install/index.php

directory_prep()
{
    if [ ! -f $IANSEO_ZIP ]; then
        echo "Did not find required file $IANSEO_ZIP."
        exit 1
    fi

    if [ -d $INSTALL_DIR ]; then
        echo "Removing old install directory: $INSTALL_DIR"
        rm -rf $INSTALL_DIR
    fi

    mkdir -p $INSTALL_DIR
}

extract_ianseo_zip()
{
    echo -n "Extracting $IANSEO_ZIP file... "
    unzip -q $IANSEO_ZIP -d $INSTALL_DIR
    # Suppression du zip après extraction pour alléger l'image
    rm -f $IANSEO_ZIP
    echo "done."
}

ianseo_tweaks()
{
    # Suppression du fichier de config pour forcer l'installation
    rm -f "$INSTALL_DIR/Common/config.inc.php"

    # Configuration de l'hôte base de données Docker
    if [ -f $INDEX_PHP ]; then
        echo "Tweaking ${INDEX_PHP}"
        sed -i.orig "s/W_HOST='localhost'/W_HOST='ianseo_docker_db'/" $INDEX_PHP
    fi

    # Fix du bug UpdateDb (si présent)
    UPDATE_DB_FILE=$INSTALL_DIR/Common/UpdateDb.inc.php
    if [ -f "$UPDATE_DB_FILE" ]; then
        UPDATE_DB_MD5SUM=$(md5sum "$UPDATE_DB_FILE" | awk '{ print $1 }')
        if [ "$UPDATE_DB_MD5SUM" = "9b97ce0acf64cdd6df6dadfd5e72bead" ]; then
            echo "Fixing typo in UpdateDb.inc.php."
            sed -i 's/if($u=safe_fetch($q))/if($u=safe_fetch($t))/' "$UPDATE_DB_FILE"
        fi
    fi
}

set_permissions()
{
    echo "Adjusting ianseo file ownership and access."
    chown -R www-data:www-data $INSTALL_DIR
    chmod -R u+wX $INSTALL_DIR
}

download_ianseo()
{
    if [ ! -f "$IANSEO_ZIP" ]; then
        echo "Téléchargement de Ianseo depuis le site officiel..."
        curl -L "https://ianseo.net/Release/${IANSEO_VERSION}.zip" -o "$IANSEO_ZIP"
        echo "Téléchargement terminé."
    fi
}

echo "web_prep script starting:"
download_ianseo
directory_prep
extract_ianseo_zip
ianseo_tweaks
set_permissions

# Préparation du debug
cp /tmp/phpinfo.php /var/www/html/phpinfo.php
chown www-data:www-data /var/www/html/phpinfo.php

# Activation config Apache
a2enconf -q ianseo

echo "web_prep script completed."