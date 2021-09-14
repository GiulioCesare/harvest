#!/bin/bash

# 24/08/2021
# TEST for valid user password for NBN API

# assicurarsi che /etc/apache2/sites-available/argetest-perl.it.conf 
# punti a: AuthUserFile /var/www/nbn.depositolegale.it/passwd/nbn.passwd.basic.ese

ctr=0

# while read id pwd; 
while IFS="|" read -r id pwd;
do

   output=`curl --silent -u $id:$pwd argetest-perl.it/perl/ `

   # echo "$id:$pwd"



    if [[ $output = *User:* ]]
    then
        echo "OK: $id:$pwd"
    else
        echo "Invalid $id:$pwd"
    fi

    # ((ctr=ctr+1));
    # echo "$ctr"
    # echo "$output";

    # if [ $ctr == 5 ]; then 
    #     break;
    # fi


done < ../tmp/nbn_api_users_to_test.csv





# for key in "${!nbn_id_pwd_AR[@]}"; 
#     do printf "%s\t%s\n" "$key" "${nbn_id_pwd_AR[$key]}"; 
# done




