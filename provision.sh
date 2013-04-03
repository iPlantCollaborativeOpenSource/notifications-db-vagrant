#!/usr/bin/env bash

export LEIN_ROOT=1

GITBASE=https://github.com/iPlantCollaborativeOpenSource

install-lein () {
    if [ ! -f /usr/local/bin/lein ]; then
        echo "Downloading lein"
        curl -L -s -o lein https://raw.github.com/technomancy/leiningen/stable/bin/lein 2>&1 lein-download-log

        echo "Moving lein into /usr/local/bin"
        mv lein /usr/local/bin/

        echo "Making lein executable"
        chmod a+x /usr/local/bin/lein

        echo "Running lein for the first time"
        lein 2>&1 lein-install-log
    else
        echo "lein is already installed at /usr/local/bin/lein"
    fi
}

apt-get update
apt-get install -q -y git
apt-get install -q -y curl
apt-get install -q -y openjdk-6-jre-headless
apt-get install -q -y postgresql-9.1

cp /vagrant/pg_hba.conf /etc/postgresql/9.1/main/
cp /vagrant/postgresql.conf /etc/postgresql/9.1/main/

cp /vagrant/pgpass ~/.pgpass
chmod 0600 ~/.pgpass

cp /vagrant/pgpass /home/vagrant/.pgpass
chown vagrant:vagrant /home/vagrant/.pgpass
chmod 0600 /home/vagrant/.pgpass

service postgresql restart
su postgres -c "psql -d template1 -f /vagrant/create_db.sql"

install-lein

git clone $GITBASE/notification-db.git notification-db
chown -r vagrant:vagrant notification-db
pushd notification-db
./build.sh
popd

git clone $GITBASE/facepalm.git facepalm
chown -r vagrant:vagrant notification-db
pushd facepalm
git checkout 1.8
git pull origin 1.8
lein clean
lein deps
lein uberjar
java -jar target/facepalm-1.2.1-SNAPSHOT-standalone.jar -f ../notification-db/notification-db.tar.gz -m init -d notifications
popd


