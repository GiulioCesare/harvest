#!/bin/bash

# =======================================================
# 08/12/2020
# Utilities for archiving material in M<agazzini Digitali
# =======================================================

# - Nomi file max 255
# NOT POSSIBLE - make link files read only? e poi cancellarli no dall;area temporanea?

# KO - gunzip su link cambia il file anche se read only?
#     NOT GOOD - make target of link read only a.warc.gz
#             gunzip will rename it  to a.warc after unzipping!!!!
#             CAN\'T AFFORD THAT

declare -A software_ar


function download_sites_software_login()
{
    echo "download_sites_software "     # in csv/sw_login.csv
}



function load_sites_software_login_ar()
{
    echo "--> LOAD SITES' SOFTWARE DATA for sending documents to MD"

    filename=$1
    echo "filename: $filename"

    if [ -f $filename ]; then
        # echo "load MD software info"

        while IFS='|' read -r -a array line
        # while read -r line
        do
            # echo "line: $line"

            line=${array[0]}
            # Remove whitespaces (empty lines)
            line=`echo $line | xargs`

            if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                continue
            else
                # echo "get data"
              site=${array[0]}
              p_iva=${array[1]}
              sw_login=${array[2]}
              sw_pwd=${array[3]}

              software_ar[$site]=$site"|"$p_iva"|"$sw_login"|"$sw_pwd
            fi
        done < "$filename"

    else
        echo "No file: $filename"
        exit
    fi

    # dump_array "software_ar" "${software_ar[@]}"

}









# Copiamo i files in area temporanea!!
# Usare i link e' pericoloso perche' GUNZIP puo modificare' il target file anche se readonly
function copy_files_in_area_temporanea()
{
    echo "--> copy_files_in_area_temporanea"


     while IFS='|' read -r -a array line
     do
           line=${array[0]}

          if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
            break
          fi

           # se riga comentata o vuota skip
           if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                 continue
            fi

        istituto=$(echo "${array[1]}" | cut -f 1 -d '.')

        filename=$dest_warcs_dir"/"$harvest_date_materiale"_"$istituto".warc.gz"
        echo "Indexing "$filename

        $WB_MANAGER_DIR"wb-manager" index $WAYBACK_COLLECTION_NAME $filename

        echo "Rinominiamo " $WAYBACK_INDEX_DIR"/index.cdxj in" $WAYBACK_INDEX_DIR"/"$istituto".cdxj"
        mv $WAYBACK_INDEX_DIR"/index.cdxj" $WAYBACK_INDEX_DIR"/"$istituto".cdxj"


     done < $HARVEST_DIR"/"$repositories_file

    cd $HARVEST_DIR
} # end index_warcs





# funzione gia' presente in warc-utils.sh
#function copy_warc_to_destination_dir ()
#{
#    echo "copy_warc_to_destination_dir"
#    local source_filename=$1
#    local dest_filename=$2
#
#    echo "source_filename: " $source_filename
#    echo "dest_filename: " $dest_filename
#
#
#    echo "Copying $source_filename to $dest_filename"
#    
#    cp -p $source_filename $dest_filename
#
#    if [ $? -ne 0 ]; then
#        echo "ERROR: while copying warc file!!! STOP COPYING"
#        return 1 
#    fi
#    return 0 
#} # End copy_warc_to_destination_dir


function copy_warcs_to_temporary_area ()
    {
     while IFS='|' read -r -a array line
     do
        line=${array[0]}

        if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
        break
        fi

        # se riga comentata o vuota skip
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
             continue
        fi

        istituto=$(echo "${array[1]}" | cut -f 1 -d '.')
        # echo "istituto="$istituto

        # Troviamo la partita iva da usare nell'area temporanea
        if test "${software_ar[$istituto]+isset}"
        then
            sw=${software_ar[$istituto]};
            # echo "sw: "$sw

          SAVEIFS=$IFS   # Save current IFS
          IFS=$'\|'      # Change IFS to new line
          fields=($sw) # split to array $names
          IFS=$SAVEIFS   # Restore IFS
          p_iva=${fields[1]};

          # echo "p_iva: "$p_iva
        else
            echo "No software config for '$istituto'"
            continue;
        fi


        # Copiamo il warc.gz in area temporanea
        filename=$harvest_date_materiale"_"$istituto".warc.gz"
        warc_source_filename=$dest_warcs_dir"/"$filename
        # warc_dest_filename=$root_area_temporanea"/"$p_iva"/"$filename
        area_temporanea=$root_area_temporanea"/"$p_iva

# echo "warc_source_filename: "$warc_source_filename
# echo "area_temporanea: "$area_temporanea
# echo "filename: "$filename

echo "creaiamo il link al file da caricare nella'area temporanea"
# Il file linkato viene rimosso dalla procedura di MD una volta archiviato il documento
ln -s $warc_source_filename $area_temporanea"/"$filename
# ls -l $area_temporanea

ret=$?

if [ $ret -gt 0 ]
then
   echo "$ret: failed to create link " $warc_source_filename $area_temporanea"/"$filename
   # Probably already present
   # continue
fi


        # Informo MD of file put in temporary area
        sw_login=${fields[2]}
        sw_pwd=${fields[3]}

        # Output di invio dati a MD in file di log
        echo "Informo MD che "$sw_login" ha messo "$filename" in "$root_area_temporanea"/"$p_iva

php scripts/md_soap_client.php $sw_login $sw_pwd $area_temporanea $filename $webServicesServer > $md_dir"/"$filename".md_log"
echo "Source: $warc_source_filename" >> $md_dir"/"$filename".md_log"

      
        # Prepariamo il record da archiviare in DB harvest.storageMD

#       - id (automatico)
#       - Data invio
#       - Ricevuta invio
#       - nome file originale (completo di path) 
#       - nome file in area temporanea (solo nome file)
#       - Tipo materiale: tesi di dottorato, e-journal, bagit, unimarc
#       - dimensione file B/MB/GB
#       - data file
#       - timestamp (creazione record) automatico



     done < "$repositories_file"

} # emd

root_area_temporanea="/mnt/areaTemporanea/Ingest"
webServicesServer="http://localhost:8080" # in base ad ambiente
sw_login_file="csv/sw_login.csv"


function prepare_docs_for_MD()
{
# download_sites_software_login

    if [ $ambiente == "sviluppo" ]; then
        echo "copying: /home/argentino/workspace/pdt/cli_app/md_soap_client.php scripts/."  
        cp /home/argentino/workspace/pdt/cli_app/md_soap_client.php scripts/.
    fi


    echo "webServicesServer: "$webServicesServer


    load_sites_software_login_ar $sw_login_file
    copy_warcs_to_temporary_area


} # end prepare_docs_for_MD





#   - Creare lista utenti SW con password per istituzioni

# $sw_login = $argv[1];       // GS_MD
# $sw_password = $argv[2];    // "GS_MD_PWD"

# $filename = $argv[3]; (o lista di file per istituzione?)


#   - creare la lista dei file da inviare per ogni istituzione

#   - Simulare invio documenti con md_soap_client.php
#   - Prendere "ricevuta" se invio ok
#       Segnalare da rifare in assenza di ricevuta
#   - Archiviare in DB harvest.storageMD info di invio dati a MD
#       - id (automatico)
#       - Data invio
#       - Ricevuta invio
#       - nome file originale (completo di path) 
#       - nome file in area temporanea (solo nome file)
#       - Tipo materiale: tesi di dottorato, e-journal, bagit, unimarc
#       - dimensione file B/MB/GB
#       - data file
#       - timestamp (creazione record) automatico
# 
#   - Il file nella cartella temporanea verra' rimosso da MD (dirlo a Massimiliano)
#   
