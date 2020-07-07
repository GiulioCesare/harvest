#!/bin/bash

function _prepare_todo_list()
{
    local istituto=$1
    local metadata_url_base=$2
    local out_file=$3
    # local archived_documents=$3

# echo "-$1\n-$2\n-$3\n-$4"

    # echo "Prepare todo list of theses for "$istituto" in "$out_file

    # echo "out_file="$out_file; # Contiene campo 'URL memoria'a "NIM" se URL assente in warc dei seeds scaricati correttamente
    # Usiamo log.seeds_in_warc e .seeds_not_in_warc per generare campo pieno o vuoto per url a memoria

    # harvest_date_trattini=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\1-\2-\3#g" )
    # formatted_harvest_date=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\3/\2/\1#g" )

    local siw=$warcs_dir"/logs1/"$harvest_date_materiale"_"$istituto".log.seeds_in_warc"
    local metadati=$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml"
    if [ $work_dir == $E_JOURNALS_DIR ]; then
        command="python ./parse_e_journals_nbn.py "$metadati" "$siw" "$metadata_url_base
    else
        # TESI
        command="python ./parse_tesi_nbn.py "$metadati" "$siw" "$metadata_url_base
#
    fi
# command="ls -l"
# echo "command="$command
echo "Prepara "$out_file
    eval $command > $out_file

    return 0; # OK
} # _prepare_todo_list

function  _convert_tsv_to_xls()
{
    local istituto=$1
    local nbnInMD=$2
    local nbnNotInMD=$3

# CSV IMPORT FILTER OPTIONS
#        The CSV import filter accepts a FilterOptions setting, the order is: separator(s),text-delimiter,encoding,first-row,column-format
#        For example you might want to use this for a real comma-separated document:
#            -i FilterOptions=44,34,76,2,1/5/2/1/3/1/4/1
#        which will use a comma (44) as the field separator, a double quote (34) as the text delimiter, UTF-8 (76) for the input encoding, start from the
#        second row and use the specified formats for each column (1 means standard, 5 means YY/MM/DD date)
#        If you like to use more than one separator (say a space or a tab) and use the system’s encoding (9), but with no text-delimiter, you can do:
#            -i FilterOptions=9/32,,9,2
#        For a list of possible encoding types, you can use the above link to find the possible options.
#        ·   FilterOptions


	echo "# Convert thesis archived and not for "$istituto

    excel_file=$nbn_dir/$harvest_date_materiale"_"$istituto"_storico_nbn.xls"
    local csv_list_file=$nbnInMD
    csv_list_file=$csv_list_file" "$nbnNotInMD

    echo "ssconvert merge csv_list_file="$csv_list_file
    arr=($csv_list_file)
    len=${#arr[@]}

    if [[ $len > 1 ]]; then
        ssconvert --merge-to=$excel_file $csv_list_file
    else
        ssconvert $csv_list_file $excel_file
    fi

} # end _convert_tsv_to_xls





# function generate_harvested_thesis_nbn()
# {
#     echo ""
#     echo "GENERATE NBN number FOR HARVESTED THESES"
#
#     # Read trough the repositories_file
#     while IFS='|' read -r -a array line
#     do
#         # echo "$line"
#         # echo "${array[0]}"
#           line=${array[0]}
#           # se riga comentata o vuota skip
#           if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
#                 continue
#            fi
#
#         local istituto=${array[1]}
#         # local OAI_repository=${array[2]}
#         # local metadata_prefix=${array[4]}
#         # local metadata_url_base=$OAI_repository"?verb=GetRecord&metadataPrefix="$metadata_prefix"&identifier="
#
#         echo "Working on: " $istituto
#
#
#         # "_in.url" per il sito viene generato quando si fanno le ricevute perche' abbiamo i dati che ci servono
#         # Vedi receipt_utils->_carica_mdr_array()
#
#
#         # Prepariamo il file excel per l'istituto
#         # ---------------------------------------
#         # _convert_tsv_to_xls $istituto $nbnInMD $nbnNotInMD
#
#     done < "$repositories_file"
#
# }


function generate_nbn_identifiers()
{
    # local archived_documents=$1
    local archived_documents=false  # Per ora la Storti non vuole gestire lo storico

    echo ""
    echo "GENERATE NBN Identifiers, archived="$archived_documents



    # echo "repositories_file: " $repositories_file
echo "repositories_file=".$repositories_file
# pwd
# return;
    # Scarichiamo i metadati di tutte le tesi dell'istituto
    # -----------------------------------------------------
    # Solo per storico
    # if [ "$archived" == true ]; then
    # harvest_metadata
    # fi


    # Read trough the repositories_file
    while IFS='|' read -r -a array line
    do
        # echo "$line"
        # echo "${array[0]}"
          line=${array[0]}
          # se riga comentata o vuota skip
          if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                continue
           fi

        local istituto=${array[1]}
        local OAI_repository=${array[2]}
        local metadata_prefix=${array[4]}
        local opera_per_baseurl=${array[6]}
        local metadata_url_base=$OAI_repository"?verb=GetRecord\&metadataPrefix="$metadata_prefix"\&identifier="

        echo "Working on: " $istituto
        # echo "OAI Repository: " $OAI_repository
        # echo "metadata_prefix: " $metadata_prefix
        echo "opera_per_baseurl: " $opera_per_baseurl

        # echo "metadata_url_base: "$metadata_url_base
        # echo "metadata_url: "$metadata_url_base"oai:apeiron.iulm.it:10808/599"
        # https://apeiron.iulm.it/oai/request?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:apeiron.iulm.it:10808/599

        if [ "$archived_documents" == true ]; then
            url_out_file=$nbn_dir/$harvest_date_materiale"_"$istituto"_storico.url"
            # out_file_not_in_warc=$nbn_dir/$harvest_date_materiale"_"$istituto"_storico.not_in.warc"
        else
            url_out_file=$nbn_dir/$harvest_date_materiale"_"$istituto".url"
            # out_file_not_in_warc=$nbn_dir/$harvest_date_materiale"_"$istituto"_.not_in.warc"
        fi

# echo "url_out_file="$url_out_file
# echo "opera_per_baseurl="$opera_per_baseurl

        _prepare_todo_list $istituto $metadata_url_base $url_out_file;


        # echo "Generiamo NBN per TESI/E-JOURNALS"
        # Generiamo NBN (o prendiamo quello esistente)
        # ----------------------------------------
        # Copiamoci ultima versione del generatore
        if [ "$ambiente" == "sviluppo" ]; then
            echo "Getting latest version of genera_nbn.pl"
            cp ~/workspace/perl/harvest/genera_nbn.pl .
        fi

        url_in=$url_out_file
        nbn_out=$url_out_file".nbn"
        rows_todo=0; # 0 = all
        # ambiente_db_nbn=$ambiente
        ambiente_db_nbn=collaudo
        echo "Generiamo gli NBN dal db di '" $ambiente_db_nbn "'"
        ./genera_nbn.pl $url_in $ambiente_db_nbn harvest harvest_pwd $opera_per_baseurl $rows_todo > $nbn_out

        # # Gli nbn generati vengono riportati nelle ricevute dell'harvesting!!! Per ora.



        # Prepariamo il file excel per l'istituto
        # ---------------------------------------
        # _convert_tsv_to_xls $istituto $nbnInMD $nbnNotInMD

    done < "$repositories_file"
} # generate_nbn_identifiers
