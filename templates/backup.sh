#!/bin/bash
# How many days worth of tarballs to keep around
num_days_to_keep=5
now=`date +%s`
today=`date +%F`
year_month=`date +%Y/%m`
host=`hostname`

auth="/etc/mysql/debian.cnf"
databases=`mysql --defaults-extra-file=$auth -BN -e "show databases;"`
while read database
do
    if [[ ! $database =~ mysql|schema|sys ]]
    then
        dir="/srv/backups/$database"
        [ -d $dir ] || mkdir $dir
        [ -f $dir/$today.sql.gz ] && rm $dir/$today.sql.gz

        cd $dir
        for file in `ls`
        do
            atime=`stat -c %Y $file`
            if [ $(( $now - $atime >= $num_days_to_keep*24*60*60 )) = 1 ]
            then
                rm $file
            fi
        done
        mysqldump --defaults-extra-file=$auth $database > $today.sql
        gzip $today.sql

        # Copy file to remote backup server
        remote_dir=/srv/backups/$host/$database/$year_month
        ssh -n -i /root/.ssh/{{ mysql_backup.user }} {{ mysql_backup.user }}@{{ mysql_backup.host }} "mkdir -p $remote_dir"
        scp -i /root/.ssh/{{ mysql_backup.user }} $today.sql.gz {{ mysql_backup.user }}@{{ mysql_backup.host }}:$remote_dir
    fi
done <<< "$databases"
