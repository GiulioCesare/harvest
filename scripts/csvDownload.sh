#!/bin/bash

ora="date +%Y-%m-%d-%H:%M:%S"
echo `${ora}` "Inizio processo di cvsDownload.shDownload.sh"
HOME_DIR=.
# DP_DIR=/export/indice/dp
# EXPORT_DIR=$DP_DIR/export

BIN_DIR=./bin



# Elapsed time.  Usage:
#
#   t=$(timer)
#   ... # do something
#   printf 'Elapsed time: %s\n' $(timer $t)
#      ===> Elapsed time: 0:01:12
#
#
#####################################################################
# If called with no arguments a new timer is returned.
# If called with arguments the first is used as a timer
# value and the elapsed time is returned in the form HH:MM:SS.
#
function timer()
{
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local  stime=$1
        etime=$(date '+%s')
        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%d:%02d:%02d' $dh $dm $ds
    fi
}
     

tmr=$(timer)

echo "Ricostruiamo ./csv/etd.csv and ./csv/e_journals.csv da DB per essere aggiornati sugli istituti presenti"

echo "Scarichiamo ler tabelle di etd ed e-journal"
java -classpath $BIN_DIR:$BIN_DIR/jdbcDrivers/mysql-connector-java-8.0.13.jar DbDownload scripts/csvDownload.con



# prendiamo la data per fare un backup
today="$(date '+%Y_%m_%d')"

materiale=$1
MATERIALE_TESI=$2
MATERIALE_EJOURNAL=$3

# echo "Materiale: $materiale"
# echo "MATERIALE_TESI: $MATERIALE_TESI"
# echo "MATERIALE_EJOURNAL: $MATERIALE_EJOURNAL"

if [ $materiale == $MATERIALE_TESI ]; then
    if [ -f "csv/etd.csv" ]
    then
        echo "SAVE csv/etd.csv in csv/etd.csv."$today
        cp "csv/etd.csv" "csv/etd.csv."$today

        echo "Make csv/etd.csv."$today" read only"
        chmod 444 "csv/etd.csv."$today
    fi

    echo "move csv/etd.out -> csv/etd.csv"
    mv "csv/etd.out" "csv/etd.csv"
else
    echo "move csv/e_journals.out -> csv/e_journals.csv"
    if [ -f "csv/etd.csv" ]
    then
        echo "SAVE csv/e_journals.csv in csv/e_journals.csv."$today
        cp "csv/e_journals.csv" "csv/e_journals.csv."$today

        echo "Make csv/e_journals.csv."$today" read only"
        chmod 444 "csv/e_journals.csv."$today
    fi

    echo "move csv/e_journals.out -> csv/e_journals.csv"
    mv "csv/e_journals.out" "csv/e_journals.csv"

fi



echo `${ora}` "Fine processo di csvDownload.sh" 
 
echo
echo Elapsed time $(timer $tmr)
