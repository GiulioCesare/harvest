#!/bin/bash

# =======================================================
# 08/12/2020
# Utilities for archiving material in M<agazzini Digitali
# =======================================================
#   - Il file nella cartella temporanea verra' rimosso da MD (dirlo a Massimiliano)

# - Nomi file max 255
# NOT POSSIBLE - make link files read only? e poi cancellarli no dall;area temporanea?

# KO - gunzip su link cambia il file anche se read only?
#     NOT GOOD - make target of link read only a.warc.gz
#             gunzip will rename it  to a.warc after unzipping!!!!
#             CAN'T AFFORD THAT

declare -A software_ar





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








# # Copiamo i files in area temporanea!!
# # Usare i link e' pericoloso perche' GUNZIP puo modificare' il target file anche se readonly
# function copy_files_in_area_temporanea()
# {
#     echo "--> copy_files_in_area_temporanea"


#      while IFS='|' read -r -a array line
#      do
#            line=${array[0]}

#           if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
#             break
#           fi

#            # se riga comentata o vuota skip
#            if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
#                  continue
#             fi

#         istituto=$(echo "${array[1]}" | cut -f 1 -d '.')

#         filename=$dest_warcs_dir"/"$harvest_date_materiale"_"$istituto".warc.gz"
#         echo "Indexing "$filename

#         $WB_MANAGER_DIR"wb-manager" index $WAYBACK_COLLECTION_NAME $filename

#         echo "Rinominiamo " $WAYBACK_INDEX_DIR"/index.cdxj in" $WAYBACK_INDEX_DIR"/"$istituto".cdxj"
#         mv $WAYBACK_INDEX_DIR"/index.cdxj" $WAYBACK_INDEX_DIR"/"$istituto".cdxj"


#      done < $HARVEST_DIR"/"$repositories_file

#     cd $HARVEST_DIR
# } # end index_warcs



function md_archive_file()
{
    local istituto=$1
    local source_filename=$2
    local fnmae=$3

    sw=${software_ar[$istituto]};
    # echo "sw: "$sw

    SAVEIFS=$IFS   # Save current IFS
    IFS=$'\|'      # Change IFS to new line
    fields=($sw) # split to array $names
    IFS=$SAVEIFS   # Restore IFS
    
    local p_iva=${fields[1]};
    local sw_login=${fields[2]}
    local sw_pwd=${fields[3]}
    local area_temporanea=$root_area_temporanea"/"$p_iva


    echo ""
    echo "==============>"
    echo ""
    echo "source_filename: "$source_filename
    echo "area_temporanea: "$area_temporanea
    echo "fname: "$fname
    echo "p_iva="$p_iva
    echo "sw_login="$sw_login
    echo "sw_pwd="$sw_pwd
    echo ""


    echo "creiaamo il link al file da caricare nella'area temporanea"
    # Il file linkato viene rimosso dalla procedura di MD una volta archiviato il documento
    ln -s $source_filename $area_temporanea"/"$fname
    ret=$?
    if [ $ret -gt 0 ]
    then
       echo "$ret: failed to create link " $source_filename""$area_temporanea"/"$fname
       # Probably already present. A meno di problemi di permessi
    fi
    echo "linked filename = "$area_temporanea"/"$fname


    # Informo MD of file put in temporary area

    echo "Output di invio dati a MD in file di log"
    echo "Informo MD che "$sw_login" ha messo "$fname" in "$root_area_temporanea"/"$p_iva

echo "DUMMY ARCHIVE"
    # php scripts/md_soap_client.php $sw_login $sw_pwd $area_temporanea $fname $webServicesServer > $md_dir"/"$fname".md_log"

    echo "Source: $warc_source_filename" >> $md_dir"/"$fname".md_log"
    echo "Vedi log in "$md_dir"/"$fname".md_log"


} # End md_archive_file



function copy_istituto_warcs_to_temporary_area()
{
    local istituto=$1

    echo "copy_istituto_warcs_to_temporary_area: " $istituto


	wild_fn=$dest_warcs_dir"/$harvest_date_materiale"_"$istituto-*.warc.gz"

	echo "wild_fn: $wild_fn"

    for filename in $wild_fn ; do
        echo ""
        echo "Process $filename"
        local fname=$(basename -- "$filename")

        # Copiamo il warc.gz in area temporanea. 
        # NO .md5 i file .md5 non sono riconosciuti
        warc_source_filename=$dest_warcs_dir"/"$fname
        md_archive_file $istituto $warc_source_filename $fname
    done
} # End copy_istituto_warcs_to_temporary_area



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

        local istituto=$(echo "${array[1]}" | cut -f 1 -d '.')
        # echo "istituto="$istituto

        # Troviamo la partita iva da usare nell'area temporanea
        if !test "${software_ar[$istituto]+isset}"
        then
            echo "Non trovo software config for '$istituto' in sw_config.csv"
            continue;
        fi
        copy_istituto_warcs_to_temporary_area $istituto 

     done < "$repositories_file"
} # end copy_warcs_to_temporary_area




function copy_unimarc_to_temporary_area ()
    {
    echo "copy_unimarc_to_temporary_area"

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


    local unimarc_source_filename=$unimarc_dir"/"$harvest_date_materiale"_"$istituto".mrc"
    local fname=$(basename -- "$unimarc_source_filename")

    echo "local unimarc_source_filename:" $unimarc_source_filename
    echo "fname="$fname

    md_archive_file $istituto $unimarc_source_filename $fname
    
     done < "$repositories_file"

} # end copy_unimarc_to_temporary_area



function download_sw_login()
{
    echo "download_sw_login "     # in csv/sw_login.csv
    pwd
    cd ./scripts
    ./swLoginDownload.sh
    cd ../csv
    mv sw_login.out sw_login.csv
    cd ..
} # End download_sw_login


# =================================
# MAIN
# =================================

root_area_temporanea="/mnt/areaTemporanea/Ingest"
webServicesServer="http://localhost:8080" # in base ad ambiente
sw_login_file="csv/sw_login.csv"

function prepare_docs_for_MD()
{
    download_sw_login


    if [ $ambiente == "sviluppo" ]; then
        echo "copying: /home/argentino/workspace/pdt/cli_app/md_soap_client.php scripts/."  
        cp /home/argentino/workspace/pdt/cli_app/md_soap_client.php scripts/.
    fi


    echo "webServicesServer: "$webServicesServer

    load_sites_software_login_ar $sw_login_file

echo "... UNCOMMENT TO CONTINUE"

    # copy_warcs_to_temporary_area
    # copy_unimarc_to_temporary_area


} # end prepare_docs_for_MD





