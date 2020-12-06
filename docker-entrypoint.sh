#!/bin/bash

function error_with_msg {
    if [[ "$count" -eq 0 ]]
    then
        echo
        echo >&2 "$1"
        exit 1
    fi
}

if [ ! -d "/var/lib/mysql/mysql" ]
then
    echo "[mysqld]\nskip-host-cache\nskip-name-resolve" > /etc/my.cnf.d/docker.cnf
    echo "- Initializing database"
    /usr/bin/mysql_install_db --user=mysql &> /dev/null
    echo "- Database initialized"
fi

if [ ! -d "/var/lib/mysql/slurm_acct_db" ]
then
    /usr/bin/mysqld_safe &

    for count in {30..0}; do
        if echo "SELECT 1" | mysql &> /dev/null
        then
            break
        fi
        echo "- Starting MariaDB to create Slurm account database"
        sleep 1
    done

    error_with_msg "MariaDB did not start"

    echo "- Creating Slurm acct database"
    mysql -NBe "CREATE USER 'slurm'@'localhost' identified by 'password'"
    mysql -NBe "GRANT ALL ON slurm_acct_db.* to 'slurm'@'localhost' identified by 'password' with GRANT option"
    mysql -NBe "GRANT ALL ON slurm_acct_db.* to 'slurm'@'slurmctl' identified by 'password' with GRANT option"
    mysql -NBe "CREATE DATABASE slurm_acct_db"
    echo "- Slurm acct database created. Stopping MariaDB"
    killall mysqld

    for count in {30..0}; do
        if echo "SELECT 1" | mysql &> /dev/null
        then
            sleep 1
        else
            break
        fi
    done

    error_with_msg "MariaDB did not stop"
fi

echo "- Starting all Slurm processes under supervisord"
/usr/bin/supervisord --configuration /etc/supervisord.conf

echo "- Waiting for the cluster to become available"
for count in {10..0}; do
    if ! grep -q "normal.*idle" <(timeout 1 sinfo)
    then
        sleep 1
    else
        break
    fi
done

error_with_msg "Slurm partitions failed to start successfully."

echo "- Cluster is now available"

exec "$@"
