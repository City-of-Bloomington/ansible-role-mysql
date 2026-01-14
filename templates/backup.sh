#!/bin/bash
# How many days worth of tarballs to keep around
num_days_to_keep=5
now=`date +%s`
today=`date +%F`

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
         mysqldump --defaults-extra-file=$auth $database > $dir/$today.sql
         gzip $dir/$today.sql
    fi
done <<< "$databases"
