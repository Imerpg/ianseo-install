#!/bin/bash

# Stop script on any error
set -e

# Variables
IANSEO_ZIP=/tmp/Ianseo_${IANSEO_VERSION}.zip
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
    # Delete the zip file after extraction to save space, since we won't need it anymore
    rm -f $IANSEO_ZIP
    echo "done."
}

ianseo_tweaks()
{
    # Delete the default config file to force ianseo to create a new one with the correct permissions on first run
    rm -f "$INSTALL_DIR/Common/config.inc.php"

    # Configure the database host in index.php to point to the correct MySQL container
    if [ -f $INDEX_PHP ]; then
        echo "Tweaking ${INDEX_PHP}"
        sed -i.orig "s/W_HOST='localhost'/W_HOST='ianseo_docker_db'/" $INDEX_PHP
    fi

    # TODO: Add known MD5 checksums for the files we want to patch and only apply the patch if the checksum matches, to avoid breaking future versions of ianseo
    # Fix a known typo in UpdateDb.inc.php if the file is present and matches the expected MD5 checksum
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
        echo "Downloading Ianseo from the official site..."
        curl -L "https://ianseo.net/Release/Ianseo_${IANSEO_VERSION}.zip" -o "$IANSEO_ZIP"
        echo "Download completed."
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