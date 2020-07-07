#!/bin/bash


# Controlliamo se tesi e' stata archiviata
#   Scarichiamo i dati tramite wget
#   In esercizio toppa. Ricordarsi di prendere gli indici da esercizio e metterli su collaudo
# ----------------------------------------
function _controlla_tesi_archiviate()
{
    local istituto=$1
# echo "harvest_from_override=$harvest_from_override"

# echo "harvest_from_override=$harvest_from_override"
    local from_date=$(echo $harvest_from_override | sed -r "s#([0-9]{4})-([0-9]{2})-([0-9]{2})#\3-\2-\1#g" )
# echo "from_date=$from_date"

    local to_date=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\3-\2-\1#g" )

    echo "# Tesi per le quali e' stato fatto l'harvesting in Magazzini Digitali dal $from_date al $to_date. Non e' garanzia che siano state acquisita correttamente." > $archived_dir/$harvest_date_materiale"_"$istituto".in"
    echo -e "OAI identifier\tURL\tTitolo" >> $archived_dir/$harvest_date_materiale"_"$istituto".in"


    echo "# Tesi per le quali non e' stato fatto l'harvesting in Magazzini Digitali dal $from_date al $to_date" > $archived_dir/$harvest_date_materiale"_"$istituto".not_in"
    echo -e "OAI identifier\tURL\tTitolo" >> $archived_dir/$harvest_date_materiale"_"$istituto".not_in"

    while read -r line
    do
        # echo "$line"
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
            continue
        fi
        set -f                      # avoid globbing (expansion of *).
        IFS='\|'
        read -ra array <<< "$line"

        url=${array[1]}
        # echo "url=$url"
        md_url="http://memoria.col.bncf.lan/web/*/"$url
        # echo "md_url: "$md_url

        tesi_trovate=`wget -qO- $md_url | grep -i "<TR>" | wc -l`
        # echo "tesi_trovate: "$tesi_trovate
        # echo -e means 'enable interpretation of backslash escapes'
        if [ $tesi_trovate != 0 ]; then
            # echo "tesi trovata " $tesi_trovate
            echo -e ${array[0]}"\t"${array[1]}"\t"${array[2]} >> $archived_dir/$harvest_date_materiale"_"$istituto".in"
        else
            # echo "tesi NON trovata "
            echo -e ${array[0]}"\t"${array[1]}"\t"${array[2]} >> $archived_dir/$harvest_date_materiale"_"$istituto".not_in"
        fi
    # break;
    done < $archived_dir/$harvest_date_materiale"_"$istituto".mdr"

} # end _controlla_tesi_archiviate









function  _convert_tsv_to_xls()
{
    local istituto=$1

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

    excel_file=$archived_dir/$harvest_date_materiale"_"$istituto"_archived.xls"

    csv_list_file=""
    cp $archived_dir/$harvest_date_materiale"_"$istituto".in" $archived_dir"/ok"
    csv_list_file=$archived_dir"/ok"

    not_in_file=$archived_dir/$harvest_date_materiale"_"$istituto".not_in"
    not_in_size=$(wc -c <"$not_in_file")

    if [ $not_in_size -gt 129 ]; then
        cp $not_in_file $archived_dir"/ko"
        csv_list_file=$csv_list_file" "$archived_dir"/ko"
    fi

    echo "ssconvert merge csv_list_file="$csv_list_file
    arr=($csv_list_file)
    len=${#arr[@]}

# echo "len="$len
    if [[ $len > 1 ]]; then
        ssconvert --merge-to=$excel_file $csv_list_file
    else
        ssconvert $csv_list_file $excel_file
    fi

} # end _convert_tsv_to_xls


function find_archived_thesis()
{
    echo "FIND ARCHIVED THESIS"
    echo "repositories_file: " $repositories_file

    # Scarichiamo i metadati di tutte le tesi dell'istituto
    # -----------------------------------------------------
    # harvest_metadata


    # Read trough the repositories_file to create report dir for site receipts
    while IFS='|' read -r -a array line
    do
        # echo "$line"
        # echo "${array[0]}"
          line=${array[0]}
          # se riga comentata o vuota skip
          if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                continue
           fi
        istituto=${array[1]}
        echo "Working on: " $istituto


        # Dai metadati estraiamo i dati necessari alla verifica in archivio
        # -----------------------------------------------------------------
        #   - l'OAI identifier
        #   - la url della tesi (dii identifier)
        #   - il titolo della tesi
        # tesi_cancellate=$archived_dir/$harvest_date_materiale"_"$istituto".mdr_cancellate"
        # command="python ./parse_tesi_archiviate.py "$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml "$tesi_cancellate
        # eval $command > $archived_dir/$harvest_date_materiale"_"$istituto".mdr"


        # Controlliamo se tesi sono state archiviate
        # ----------------------------------------
        # _controlla_tesi_archiviate $istituto


        # Prepariamo il file excel per l'istituto
        # ---------------------------------------
        _convert_tsv_to_xls $istituto

    done < "$repositories_file"


} # find_archived_thesis
