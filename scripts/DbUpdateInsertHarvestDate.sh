#!/bin/bash
#set -x

# Prendi l'ambiente dell/utente export

#. ./constants.inc.sh
#. ./common_functions.inc.sh

BIN_DIR=./bin



# ==========================
#   INIZIO ESECUZIONE CODICE
# ==========================

ora="date +%Y-%m-%d-%H:%M:%S"

echo `${ora}` "Inizio processo di DbUpdateInsertHarvestDate.sh"
tmr=$(timer)

echo Caricamento DB
# java e' configurato nella variabile di ambiente PATH
java -classpath $BIN_DIR:$BIN_DIR/jdbcDrivers/mysql-connector-java-8.0.13.jar DbUpdateInsert scripts/DbUpdateInsertHarvestDate.cfg scripts/DbUpdateInsertHarvestDate_env.con



echo `${ora}` "Fine processo di DbUpdateInsertHarvestDate.sh"
 
echo
# echo Elapsed time $(timer $tmr)
