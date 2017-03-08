#!/bin/bash

INSTALL_ROOT=~/src
mkdir -p $INSTALL_ROOT || die "Unable to create installation directory"
pushd $INSTALL_ROOT

### Clone required GitHub repos
echo "Cloning GitHub repos to build from source..."
git clone --depth=1 https://github.com/goldshtn/linux-tracing-workshop labs
git clone --depth=1 https://github.com/nodejs/node
git clone --depth=1 https://github.com/postgres/postgres
git clone --depth=1 https://github.com/MariaDB/server mariadb

NUMPROCS=$(nproc --all)

### Build Node from source
echo "Building Node from source..."
pushd node
./configure --with-dtrace
make -j $NUMPROCS
sudo make install
popd

### Build Postgres from source
echo "Building Postgres from source..."
pushd postgres
./configure --enable-dtrace --without-readline
make -j $NUMPROCS
sudo make install
popd

### Build MariaDB from source
echo "Building MariaDB from source..."
pushd mariadb
cmake . -DENABLE_DTRACE=1
make -j $NUMPROCS
sudo make install
popd

### Install MySQL Python connector
echo "Installing MySQL Python connector..."
sudo pip install mysql-python

### Setting up Postgres
echo "Setting up Postgres with user 'postgres'..."
sudo adduser postgres
sudo mkdir /usr/local/pgsql/data
sudo chown postgres /usr/local/pgsql/data
sudo -u postgres /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data
echo "To start Postgres, run 'sudo -u postgres /usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data >logfile 2>&1 &'"

### Setting up MySQL
echo "Setting up MySQL with user 'mysql'..."
sudo groupadd mysql
sudo useradd -g mysql mysql
pushd /usr/local/mysql
sudo chown -R mysql .
sudo chgrp -R mysql .
sudo scripts/mysql_install_db --user=mysql
sudo chown -R root .
sudo chown -R mysql data
echo "To start MySQL, run 'sudo -u mysql /usr/local/mysql/bin/mysqld_safe --user=mysql &'"
popd

### Restore original directory
popd
