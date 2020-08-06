#!/bin/sh

declare -A http_error_kv_AR
declare -A meta_dati_ricevute_kv_AR
declare -A seeds_in_warc_kv_AR
declare -A seeds_not_in_warc_kv_AR
declare -A oai_nbn_kv_AR
declare -A oai_nbn_status_kv_AR


function _carica_mdr_array()
{
    local istituto=$1
    # local metadata_url=$2

    # Carichiamo l'associative array dei metadati che ha la url come chiave
    if [[ -f $receipts_dir/$harvest_date_materiale"_"$istituto".no_didl_resource" ]]; then
        rm $receipts_dir/$harvest_date_materiale"_"$istituto".no_didl_resource"
    fi

    mdr_file=$receipts_dir/$harvest_date_materiale"_"$istituto".mdr"

    # ok_tesi_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_tesi.csv"
    # ok_ej_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_ej.csv"
    ok_main_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_main.csv"

# # Per la generazione degli NBN
# in_url=$nbn_dir"/"$harvest_date_materiale"_"$istituto"_in.url"

    echo "OAI identifier|NBN identifier|NBN status|Diritti|Titolo" > $ok_main_csv
    # echo "#OAI identifier|URL tesi|URL memoria|URL OAI metadata |Titolo della tesi" > $in_url

    # while IFS='|' read -r -a array line
    # do

    # While read" doesn't work when the last line of a file doesn't end with newline char.
    # It reads the line but returns false (non-zero) value
    DONE=false
    until $DONE; do
        IFS='|' read -r -a array line  || DONE=true

# echo "line=$line"
        campo0=${array[0]}
        if [[ ${campo0:0:1} == "#" ]];     then
            continue
        fi

        len=${#array[@]}
        if [[ len > 3 ]]; then

# echo "0 data harvesting: "${array[0]}
# echo "1 data doc       : "${array[1]}
# echo "2 titolo         : "${array[2]} #
# echo "3 Creator        : "${array[3]} #
# echo "4 Contributor    : "${array[4]} #
# echo "5 Subject        : "${array[5]} #
# echo "6 Main url       : "${array[6]} #
# echo "7 Other urls     : "${array[7]} #
# echo "8 Oai identifier : "${array[8]} #
# echo "9 Rights         : "${array[9]} #
# echo ""
# return

            # replace_octal_with_encoded_hex ${array[6]} # return  value in $ret_replace_octal_with_encoded_hex
            # r7=${array[7]}  # qui prendo la chiave
            # if [ $materiale == $MATERIALE_TESI ]; then
                main=${array[6]}  # qui prendo la url della descrizimne della tesi (handle)

# echo "main key=$main"

                components=${array[7]} # URL desc + altre url (component o dc:identifiers)
                oai_id=${array[8]}  # qui prendo l'OAI identifier

                # Abbiamo un NBN?
                if test "${oai_nbn_kv_AR[$oai_id]+isset}"; then
                    # echo "NBN="${oai_nbn_kv_AR[$oai_id]};
                    nbn_id=${oai_nbn_kv_AR[$oai_id]};
                    nbn_status=${oai_nbn_status_kv_AR[$oai_id]};
                else
                    nbn_id=" ";
                    nbn_status=" ";
                fi;



# echo "components="$components
                # usati ;;; come separatori
                # concertiti in 01 binario per lo split
                new_sep_components=${components//;;;/} 
# echo "new sep components=" $new_sep_components
# echo "-----"                
                IFS= read -ra keys_ar <<< $new_sep_components 

# echo ${keys_ar[*]}
# return
                component=1
                done_main=0
                for key in ${!keys_ar[*]}; do
                    k=${keys_ar[$key]}

 # echo "key="$key
 # echo "k="$k
 
                    if [[ "$k" == " " ]]; then


                        if [ $materiale == $MATERIALE_TESI ]; then
                            echo "No didl.component.resource per:'$main'"
                            if [[ ! -f $receipts_dir/$harvest_date_materiale"_"$istituto".no_didl_resource" ]]; then
                                echo "OAI identifier|descrizione|titolo" >> $receipts_dir/$harvest_date_materiale"_"$istituto".no_didl_resource"
                            fi
                                titolo=${array[2]}
                                echo "$main|no didl:resource associato|"$titolo >> $receipts_dir/$harvest_date_materiale"_"$istituto".no_didl_resource"
                        fi;



                        component=0
                    fi
                    # k1=${k%#*} # rimuovi cio' che segue il cancelletto
                    k1=$k

                    replace_octal_with_encoded_hex "$k1" # return  value in $ret_replace_octal_with_encoded_hex

                    tmp=$(urldecode "${ret_replace_octal_with_encoded_hex}")
                    k=$(urldecode "${tmp}")
                    data_harvest=${array[0]}
                    data_tesi=${array[1]}
                    url=$k
                    tesi=${url##*/}   # rimuovi fino all'ultimo slash
                    titolo=${array[2]}
                    autore=${array[3]}
                    tutor=${array[4]}
                    soggetto=${array[5]}
                    rights=${array[9]}

                    if [ $done_main == 0 ]; then
                        meta_dati_ricevute_kv_AR[$main]=$data_harvest"|"$data_tesi"|"$oai_id"|"$nbn_id"|"$rights"|"$titolo"|"$autore"|"$tutor"|"$soggetto"|"$main
                        echo $oai_id"|"$nbn_id"|"$nbn_status"|"$rights"|"$titolo >> $ok_main_csv

                        # Per NBN echo "#OAI identifier|URL tesi|URL memoria|URL OAI metadata |Titolo della tesi" > $in_url
                        # echo $oai_id"|"$url"|http://memoria.depositolegale.it/*/"$url"|"$metadata_url$oai_id"|"$titolo >> $in_url
                        done_main=1
                    fi
# echo "k=$k"
                    if [ $component == 1 ]; then
                        meta_dati_ricevute_kv_AR[$k]=$data_harvest"|"$data_tesi"|"$oai_id"|"$nbn_id"| |"$titolo"|"$autore"|"$tutor"|"$soggetto"|"$url"|"$tesi
                    fi
                done
# break
            fi

    done < $mdr_file    #$receipts_dir/$harvest_date_materiale"_"$istituto".mdr"
    # $receipts_dir"/tmp.mdr"

printarr meta_dati_ricevute_kv_AR > $receipts_dir/$harvest_date_materiale"_"$istituto".mdr.expanded"


# echo "meta_dati_ricevute_kv_AR"
# for key in "${!meta_dati_ricevute_kv_AR[@]}"; do
# echo "key=${key}"; done
# echo "end meta_dati_ricevute_kv_AR"

# echo "meta_dati_ricevute_kv_AR length="${#meta_dati_ricevute_kv_AR[@]}

} # end _carica_mdr_array

function _do_receipts_for_seeds_in_warc ()
{
    local istituto=$1
    local seeds_filename=$seeds_dir"/"$harvest_date_materiale"_"$istituto".seeds"

echo "seeds_filename=$seeds_filename"

# echo "# Leggiamo i seeds che dovevano essere scaricati per $seeds_filename : $istituto"
    err_code=""
    if [[ -f $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv" ]]; then
        rm $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"
    fi


    if [ $materiale == $MATERIALE_TESI ]; then
        echo "DATA HARVEST|DATA DOC|OAI IDENTIFIER|NBN IDENTIFIER|DIRITTI|TITOLO|AUTORE|TUTOR|SOGGETTO|HANDLE/URL|TESI" > $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"
    else
        # echo "DATA HARVEST|DATA TESI|OAI IDENTIFIER|DIRITTI|TITOLO TESI|AUTORE|URL|TESI" >> $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"
        echo "DATA HARVEST|DATA DOC|OAI IDENTIFIER|NBN IDENTIFIER|DIRITTI|TITOLO|AUTORE|TUTOR|SOGGETTO|HANDLE/URL" > $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"
    fi;


# printarr meta_dati_ricevute_kv_AR > $receipts_dir/$harvest_date_materiale"_"$istituto".mdrAR"

# for key in "${!meta_dati_ricevute_kv_AR[@]}"; do
# echo "${key}"; done
# echo "DEBUG" > tmp.log
    # while IFS= read -r line
    # do
    # While read" doesn't work when the last line of a file doesn't end with newline char.
    # It reads the line but returns false (non-zero) value
    DONE=false
    until $DONE; do
        IFS= read -r line  || DONE=true


# echo "line="$line
        replace_octal_with_encoded_hex "${line}" # return  value in $ret_replace_octal_with_encoded_hex
        tmp=$(urldecode "$ret_replace_octal_with_encoded_hex")
        url=$(urldecode "$tmp")

        if test "${seeds_in_warc_kv_AR[$url]+isset}"
            then
echo "url in warc="$url >> tmp.log
            if test "${meta_dati_ricevute_kv_AR[$url]+isset}"
                then
                    dati_ricevuta=${meta_dati_ricevute_kv_AR[$url]}
                    echo $dati_ricevuta >> $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"
            else
                echo "MDR: NOT FOUND in meta_dati_ricevute_kv_AR '$url'" >>/dev/stderr
                exit
                # echo "meta_dati_ricevute_kv_AR"
                # printarr meta_dati_ricevute_kv_AR
            fi;
        else
            # Controllo se seed tra quelli in errore
            if ! test "${seeds_not_in_warc_kv_AR[$url]+isset}"
            then
                echo "URL non trovata neanche tra quelle in errore: '$url'"
            fi
        fi
# echo "url="$url
# return
        done < $seeds_filename
    # 23/01/2020 Generiamo la lista delle tesi (non delle suoi componenti)
    ok_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"

} # end _do_receipts_for_seeds_in_warc


function _carica_oai_nbn_array()
{
    local istituto=$1
    nbn_file=$nbn_dir"/"$harvest_date_materiale"_"$istituto".url.nbn"

    if [ ! -f $nbn_file ]; then
        return;
    fi


echo "nbn_file="$nbn_file

    # while IFS='|' read -r -a array line
    # do
    # While read" doesn't work when the last line of a file doesn't end with newline char.
    # It reads the line but returns false (non-zero) value
    DONE=false
    until $DONE; do
        IFS='|' read -r -a array line  || DONE=true
        oai=${array[0]}
# echo "oai=$oai"
        if [[ ${oai:0:1} == "#" ]] || [[ ${oai} == "" ]];  then
              continue
        fi
        nbn=${array[1]}
        status=${array[3]}
# echo "oai=$oai --- nbn=$nbn"
        oai_nbn_kv_AR[$oai]=$nbn
        oai_nbn_status_kv_AR[$oai]=$status
    done < $nbn_file
    printarr oai_nbn_kv_AR > $receipts_dir/$harvest_date_materiale"_"$istituto".oai_nbn"
} # end _carica_oai_nbn_array

# Carichiamo l'associative array con la descrizione degli errori HTTP
_load_http_error_descriptions()
{
    echo "_load_http_error_descriptions: " $HARVEST_DIR"/http_errors_it.csv"
    # while IFS='|' read -r -a array line
    # do

    # While read" doesn't work when the last line of a file doesn't end with newline char.
    # It reads the line but returns false (non-zero) value
    DONE=false
    until $DONE; do
        IFS='|' read -r -a array line  || DONE=true

    # array vuoto?
    if [ ${#array[@]} -eq 0 ]; then
        continue;
    fi

        # echo "$line"
      campo0=${array[0]}
      if [[ ${campo0:0:1} == "#" ]] || [[ ${line} == "" ]];  then
          continue
      fi
      key=${array[0]}
      value=${array[1]}
# echo "key="$key

      http_error_kv_AR[$key]=$value
    done < $HARVEST_DIR"/http_errors_it.csv"

# echo "DUMP http_error_kv_AR"
# printf '%s\n' "${http_error_kv_AR[@]}"

} # end _load_descriptions

function _genera_dati_per_ricevute()
{
    local istituto=$1

    # Generiamo i dati per le ricevute
    if [ $work_dir == $E_JOURNALS_DIR ]; then
        command="python ./scripts/parse_e_journals_ricevute.py "$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml "$formatted_harvest_date
    else
        # TESI
        command="python ./scripts/parse_tesi_ricevute.py "$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml "$formatted_harvest_date
    fi
# echo "Crea meta dati per ricevute in formato ASCII PSV (Pipe Separated Values) for ${array[1]}: "$command
	mdr=$receipts_dir/$harvest_date_materiale"_"$istituto".mdr"
 # echo "Crea mdr:" $mdr
    eval $command > $mdr

} # end _genera_dati_per_ricevute








# controlliamo che il numero di elementi delle ricevute siano uguali al numero di elementi
# dei seed in warc e non
function check_for_receipts_mismatch()
{
    echo "CHECK FOR RECEIPTS MISMATCH"
    echo "==========================="

    mismatch=0;

    for seeds_to_harvest_filename in $seeds_dir/*.seeds
    do
        echo "$seeds_to_harvest_filename"
        fname=$(basename -- "$seeds_to_harvest_filename")
        fname="${fname%.*}"
# echo "fname=$fname"



        seeds_in_warc=0
        seeds_not_in_warc=0
        receipts_in_warc=0
        receipts_not_in_warc=0
        #  Contiamo i seed scaricati inseriti nei warc
        siw=$warcs_dir/log/$fname.log.seeds_in_warc
        if [[ -f $siw ]]; then
            seeds_in_warc=$(cat $siw | wc -l)
        fi
        #  Contiamo le ricevute dei seed inseriti nei warc
        riw=$receipts_dir/$fname"_ok.csv"
        if [[ -f $siw ]]; then
            receipts_in_warc=$(cat $riw | wc -l)
            let "receipts_in_warc=receipts_in_warc-1" # togli header
        fi


        # Contiamo i seed che non sono stati inseriti nei warc
        sniw=$warcs_dir/log/$fname.log.seeds_not_in_warc
        if [[ -f $sniw ]]; then
            seeds_not_in_warc=$(cat $sniw | wc -l)
        fi

        #  Contiamo le ricevute dei seed inseriti nei warc
        rniw=$receipts_dir/$fname"_ko.csv"
        if [[ -f $sniw ]]; then
            receipts_not_in_warc=$(cat $rniw | wc -l)
            let "receipts_not_in_warc=receipts_not_in_warc-1" # togli header
        fi


        tot_seeds_from_wget=$((seeds_in_warc + seeds_not_in_warc))
        # echo "tot seeds   ="$tot_seeds_from_wget

        tot_receipts=$((receipts_in_warc + receipts_not_in_warc))
        # echo "tot receipts="$tot_receipts

        if [[ $tot_seeds_from_wget != $tot_receipts ]]; then
            echo "tot seeds "$tot_seeds_from_wget " NOT equal tot receipts " $tot_receipts
            let "mismatch=mismatch+1"
        fi

    done

    if [[ $mismatch < 1 ]]; then
        echo ""
        echo "GREAT!!! Nessun mismatch tra RICEVUTE e SEEDS"
    else
        echo ""
        echo "CHECK!!! $mismatch siti mismatch tra RICEVUTE e SEED"
    fi

} # end check_for_receipts_mismatch









function _carica_seeds_in_warc ()
{
    local istituto=$1
    local siw=$warcs_dir"/log/"$harvest_date_materiale"_"$istituto".log.seeds_in_warc"

# echo "_carica_seeds_in_warc siw="$siw

    if [ ! -f $siw ]; then
        return
    fi


    while read -r  line
    do
        [ -z "$line" ] && continue  # test empty line
# echo "$line"
        url=${line}
# echo "url=$url"
        # k1=${url%#*} # rimuovi cio' che segue il cancelletto
        # replace_octal_with_encoded_hex "$k1" # return  value in $ret_replace_octal_with_encoded_hex
        k1=$url # rimuovi cio' che segue il cancelletto
        replace_octal_with_encoded_hex "$k1" # return  value in $ret_replace_octal_with_encoded_hex

# echo "ret_replace_octal_with_encoded_hex=$ret_replace_octal_with_encoded_hex"
        tmp=$(urldecode "${ret_replace_octal_with_encoded_hex}")
# echo "tmp=$tmp"
        k=$(urldecode "${tmp}")
# echo "k=$k"
        seeds_in_warc_kv_AR[$k]=$k
    done < $siw

# echo "seeds_in_warc_kv_AR length="${#seeds_in_warc_kv_AR[@]}

printarr seeds_in_warc_kv_AR > $receipts_dir/$harvest_date_materiale"_"$istituto".siw"

} # fine _carica_seeds_in_warc

function _carica_seeds_not_in_warc ()
{
#     fname=$1
#
#     if [[ ! -f $warcs_dir"/log/"$fname".log.seeds_not_in_warc" ]]; then
#         return
#     fi
#
#     while read -r  line
#     do
#         [ -z "$line" ] && continue  # test empty line
#
# # echo "$line"
#         url=${line:4}
# # echo "$url"
#
#         k1=${url%#*} # rimuovi cio' che segue il cancelletto
#         replace_octal_with_encoded_hex "$k1" # return  value in $ret_replace_octal_with_encoded_hex
#         tmp=$(urldecode "${ret_replace_octal_with_encoded_hex}")
#         k=$(urldecode "${tmp}")
#  # echo "k=$k" >> tmp.txt
#         seeds_not_in_warc_kv_AR[$k]=$k
#     done < $warcs_dir"/log/"$fname".log.seeds_not_in_warc"
#
# # echo "seeds_not_in_warc_kv_AR length="${#seeds_not_in_warc_kv_AR[@]}
#

local istituto=$1
local sniw=$warcs_dir"/log/"$harvest_date_materiale"_"$istituto".log.seeds_not_in_warc"

# echo "_carica_seeds_in_warc siw="$siw

if [ ! -f $sniw ]; then
    return
fi
while read -r  line
do
    [ -z "$line" ] && continue  # test empty line
# echo "$line"
    url=${line}
# echo "url=$url"

    # k1=${url%#*} # rimuovi cio' che segue il cancelletto
    # replace_octal_with_encoded_hex "$k1" # return  value in $ret_replace_octal_with_encoded_hex

    k1=$url # rimuovi cio' che segue il cancelletto
    replace_octal_with_encoded_hex "$k1" # return  value in $ret_replace_octal_with_encoded_hex
# echo "ret_replace_octal_with_encoded_hex=$ret_replace_octal_with_encoded_hex"
    tmp=$(urldecode "${ret_replace_octal_with_encoded_hex}")
# echo "tmp=$tmp"
    k=$(urldecode "${tmp}")
# echo "k=$k"
    seeds_not_in_warc_kv_AR[$k]=$k
done < $sniw

# echo "seeds_in_warc_kv_AR length="${#seeds_in_warc_kv_AR[@]}

printarr seeds_not_in_warc_kv_AR > $receipts_dir/$harvest_date_materiale"_"$istituto".sinw"
} # fine _carica_seeds_not_in_warc


# Contolliamo che le url da scaricare equivalgano a quelle scaricate o andate in errore
function check_match_seeds_donloaded_to_download ()
{
    local istituto=$1
    ok_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"
    ko_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_ko.csv"
    seeds_ok_ko=$receipts_dir"/"$harvest_date_materiale"_"$istituto".seeds"
    seeds_to_download=$seeds_dir"/"$harvest_date_materiale"_"$istituto".seeds"
    awk 'BEGIN {FS="|"}FNR == 1 {next}{print $8}' $ok_csv > $seeds_ok_ko
    awk 'BEGIN {FS="|"}FNR == 1 {next}{print $9}' $ko_csv >> $seeds_ok_ko
    sort $seeds_ok_ko > $seeds_ok_ko".srt"
    sort $seeds_to_download > $seeds_ok_ko".to_download.srt"

} # end check_match_seeds_donloaded_to_download










function _do_receipts_for_seeds_not_in_warc()
{

    local istituto=$1
    bad_seeds_fileame=$warcs_dir"/log/"$harvest_date_materiale"_"$istituto".log.seeds_not_in_warc"

# echo "bad_seeds_fileame=$bad_seeds_fileame"
    ko_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_ko.csv"
    if [[ -f $ko_csv ]]; then
echo "remove "$ko_csv
        rm $ko_csv
    fi

    # -s FILE - True if the FILE exists and has nonzero size.
    if [ -s "$bad_seeds_fileame" ]; then
# echo "# Generate receipts for non accessible urls, bad_seeds_fileame = "$bad_seeds_fileame
        # cat $bad_seeds_fileame >> $receipts_dir"/"$harvest_date"_"$istituto"_ko.csv"

# echo "printarr"
# printarr meta_dati_ricevute_kv_AR
# echo "end printarr"

        if [ $materiale == $MATERIALE_TESI ]; then
            echo "Errore HTTP|DATA HARVEST|DATA DOC|OAI IDENTIFIER|NBN IDENTIFIER|DIRITTI|TITOLO|AUTORE|TUTOR|SOGGETTO|HANDLE/URL|TESI" > $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ko.csv"
        else
            echo "Errore HTTP|DATA HARVEST|DATA DOC|OAI IDENTIFIER|NBN IDENTIFIER|DIRITTI|TITOLO|AUTORE|TUTOR|SOGGETTO|HANDLE/URL" > $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ko.csv"
        fi;


        # while IFS=' ' read -r line
        # do
        # While read" doesn't work when the last line of a file doesn't end with newline char.
        # It reads the line but returns false (non-zero) value
        DONE=false
        until $DONE; do
            IFS=' ' read -r line  || DONE=true

            # echo "line="$line
            err_code=$(echo $line | egrep -o " [0-9]+ " | xargs)
            err_code=${line:0:3}
# echo "err_code="$err_code
# printarr http_error_kv_AR
            # err_description=${http_error_kv_AR["404"]}
            err_description=${http_error_kv_AR[$err_code]}
# echo "err_description="$err_description

            # end_offset=$(echo $line | grep -b -o " http" | awk 'BEGIN {FS=":"}{print $1}')
            # echo "end_offset="$end_offset
            # url=${line:$start_offset:$end_offset}

            replace_octal_with_encoded_hex "${line:4}" # return  value in $ret_replace_octal_with_encoded_hex
            tmp=$(urldecode "$ret_replace_octal_with_encoded_hex")
            url=$(urldecode "$tmp")

# echo "url="$url

            if [ "${meta_dati_ricevute_kv_AR[$url]}" ]; then
                dati_ricevuta=${meta_dati_ricevute_kv_AR[$url]}
            else [[ $dati_ricevuta=="" ]]
                # dati_ricevuta="|||||||$url"
                continue;   # ignore errors concerning accessory files
            fi
            # # echo "("$err_code") "$err_description"|"$dati_ricevuta  >> $receipts_dir"/"$harvest_date"_"$istituto"_ko.csv"

# echo "####err_description="$err_description
            echo $err_description"|"$dati_ricevuta  >> $receipts_dir"/"$harvest_date_materiale"_"$istituto"_ko.csv"
        done < $bad_seeds_fileame
    fi
} # _do_receipts_for_seeds_not_in_warc


function  _convert_csv_to_xls()
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


	# echo "# Convert receipts from csv to xls for "$istituto
    excel_file=$receipts_dir"/"$harvest_date_materiale"_"$istituto".xls"
# echo "excel_file="$excel_file

    csv_list_file=""

    base_name=$receipts_dir"/"$harvest_date_materiale"_"$istituto

# echo "base_name="$base_name
# return;
    if [[ -f $base_name"_main.csv" ]]; then
        if [ $materiale == $MATERIALE_TESI ]; then
            main="tesi"
        else
            main="e-journal"
        fi
        sed s/\|/\\t/g $base_name"_main.csv" | perl -pe 's/\x01/ # /g' > $receipts_dir"/"$main
        csv_list_file=$csv_list_file" "$receipts_dir"/"$main
    fi

    if [[ -f $base_name"_ok.csv" ]]; then
        sed s/\|/\\t/g $base_name"_ok.csv" | perl -pe 's/\x01/ # /g'  > $receipts_dir"/ok"
        csv_list_file=$csv_list_file" "$receipts_dir"/ok"
    fi

    if [[ -f $base_name"_ko.csv" ]]; then
        sed s/\|/\\t/g $base_name"_ko.csv" > $receipts_dir"/ko"
        csv_list_file=$csv_list_file" "$receipts_dir"/ko"
    fi

    if [[ -f $base_name".no_didl_resource" ]]; then
        sed s/\|/\\t/g $base_name".no_didl_resource" > $receipts_dir"/no_resource"
        csv_list_file=$csv_list_file" "$receipts_dir"/no_resource"
    fi

    missing_file=$warcs_dir"/log/"$harvest_date_materiale"_"$istituto".log.seeds.missing"
    if [[ -f $missing_file ]]; then
        echo "\"URL con caratteri riservati\"" > $receipts_dir"/missing"
        cat $missing_file >> $receipts_dir"/missing"
        csv_list_file=$csv_list_file" "$receipts_dir"/missing"

    fi

    duplicate_file=$seeds_dir"/"$harvest_date_materiale"_"$istituto".seeds_dup.csv"
    if [[ -f $duplicate_file ]]; then
        echo "\"URL con occorrenza multipla\"" > $receipts_dir"/duplicate"
        sed s/\|/\\t/g $duplicate_file >> $receipts_dir"/duplicate"
        csv_list_file=$csv_list_file" "$receipts_dir"/duplicate"
    fi

# echo "csv_list_file=$csv_list_file"


# echo "ssconvert csv_list_file="$csv_list_file
    arr=($csv_list_file)
    len=${#arr[@]}
    if [[ $len > 1 ]]; then
		echo "ssconvert --merge-to=$excel_file $csv_list_file"
        ssconvert --merge-to=$excel_file $csv_list_file > /dev/null 2>&1
    else
        echo "ssconvert $csv_list_file $excel_file"
        ssconvert $csv_list_file $excel_file # > /dev/null 2>&1
    fi
    echo "# Copy receipts to "$report_dir"/"$istituto" for the wayback machine"
    cp $excel_file $report_dir"/"$istituto"/."


} # end _convert_csv_to_xls









function _prepara_ricevute_excel_tesi()
{
    echo "Do excel receipts for tesi"
            for filename in $warcs_dir/log/*.log; do
    # echo "filename: "$filename
                fname=$(basename -- "$filename")
                fname="${fname%.*}"
    # echo "fname=$fname"
                istituto=${fname##*_}   # rimuovi fino all'ultimo underscore
    # echo "istituto TESI: $istituto"
                _convert_csv_to_xls $istituto
            done
}

function _prepara_ricevute_excel_e_journals()
{
    # echo "Do excel receipts for e-Journals"

    declare -A istituti_ej_kv_AR
    # Raggrupiamo gli istituti in modo univoco
    for filename in $warcs_dir/log/*.log; do
        # echo "filename: "$filename
            fname=$(basename -- "$filename")
            fname="${fname%.*}"
# echo "fname=$fname"
            istituto=${fname##*_}   # rimuovi fino all'ultimo underscore
            istituto=${istituto%.*}
# echo "istituto E-JOURNAL: $istituto"
            istituti_ej_kv_AR[$istituto]="ej"
        done

    # Creiamo le ricevute per istituto raggruppato (e non per singolo warc come avviene per le tesi)
    shopt -s nullglob   # option so that a pattern that matches nothing "disappears",
    for istituto in "${!istituti_ej_kv_AR[@]}"; do
        echo $istituto;
        # Raggruppiamo dati per istituto

        # Prepariamo il _main.csv
        # -----------------------
        main_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_main.csv"
        ctr=0
        for filename in $receipts_dir/$harvest_date_materiale"_"$istituto.*main.csv; do
# echo "ctr="$ctr
            if [ $ctr -eq 0 ]; then
# echo "First main file: "$filename
                awk 'BEGIN {FS="|"}{print $0}' $filename > $main_csv
            else
# echo "altro main file: "$filename
                awk 'BEGIN {FS="|"}FNR == 1 {next}{print $0}' $filename >> $main_csv
            fi
            ctr+=1
        done

        # Prepariamo il _ok.csv
        # -----------------------
        ok_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_ok.csv"
        ctr=0
        for filename in $receipts_dir/$harvest_date_materiale"_"$istituto.*ok.csv; do
            if [ $ctr -eq 0 ]; then
# echo "First ok file: "$filename
                awk 'BEGIN {FS="|"}{print $0}' $filename > $ok_csv
            else
# echo "Altro ok file: "$filename
                awk 'BEGIN {FS="|"}FNR == 1 {next}{print $0}' $filename >> $ok_csv
            fi
            ctr+=1
        done

        # Prepariamo il _ko.csv
        # -----------------------
        ko_csv=$receipts_dir"/"$harvest_date_materiale"_"$istituto"_ko.csv"
        ctr=0
        for filename in $receipts_dir/$harvest_date_materiale_$istituto.*ko.csv; do
            if [ $ctr -eq 0 ]; then
                awk 'BEGIN {FS="|"}{print $0}' $filename > $ko_csv
            else
                awk 'BEGIN {FS="|"}FNR == 1 {next}{print $0}' $filename >> $ko_csv
            ctr+=1
            fi
        done


        # Prepariamo il .seeds_dup.csv
        # ----------------------------
        dup_csv=$seeds_dir"/"$harvest_date_materiale"_"$istituto".seeds_dup.csv"
        ctr=0
        for filename in $receipts_dir/$harvest_date_materiale_$istituto.*dup.csv; do
            if [ $ctr -eq 0 ]; then
                awk 'BEGIN {FS="|"}{print $0}' $filename > $dup_csv
            else
                awk 'BEGIN {FS="|"}FNR == 1 {next}{print $0}' $filename >> $dup_csv
            ctr+=1
            fi
        done


        _convert_csv_to_xls $istituto

    done
} # end _prepara_ricevute_excel_e_journals

function _prepara_ricevute_excel()
{
    echo "prepara_ricevute_excel"
    if [ $materiale == $MATERIALE_TESI ]; then
        # Prepariamop le ricevute in formato excel per TESI
        _prepara_ricevute_excel_tesi

    elif [ $materiale == $MATERIALE_EJOURNAL ]; then
        # Prepariamop le ricevute in formato excel per E-JOURNALS
        _prepara_ricevute_excel_e_journals
    fi

} # end _prepara_ricevute_excel

function _prepara_ricevute_csv()
{
    echo "prepara_ricevute_csv"

    # while IFS='|' read -r -a array line
    # do
    # While read" doesn't work when the last line of a file doesn't end with newline char.
    # It reads the line but returns false (non-zero) value
    DONE=false
    until $DONE; do
        IFS='|' read -r -a array line  || DONE=true

        line=${array[0]}
        # se riga comentata o vuota skip
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
              continue
         fi
        local istituto=${array[1]}
        local OAI_repository=${array[2]}
        local metadata_prefix=${array[4]}
        # local metadata_url_base=$OAI_repository"?verb=GetRecord&metadataPrefix="$metadata_prefix"&identifier="

echo "Working on: " $istituto

        _genera_dati_per_ricevute $istituto
        _carica_oai_nbn_array $istituto # serve a mdr
        _carica_mdr_array $istituto

        _carica_seeds_in_warc $istituto
        _carica_seeds_not_in_warc $istituto
        _do_receipts_for_seeds_in_warc $istituto
        _do_receipts_for_seeds_not_in_warc $istituto

        # Solo per debug
        # check_match_seeds_donloaded_to_download $istituto


    done < "$repositories_file"
} # end _prepara_ricevute_csv


function make_receipts()
{
    echo "MAKE RECEIPTS"
    echo "============="
    # rm $receipts_dir/*

    harvest_date_trattini=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\1-\2-\3#g" )
    formatted_harvest_date=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\3/\2/\1#g" )

    echo "harvest date=$formatted_harvest_date"

    _load_http_error_descriptions

    echo "--------"
    echo "Istituti"
    echo "--------"

    _prepara_ricevute_csv
    _prepara_ricevute_excel
} # end make_receipts
