#!/bin/sh



function crea_wayback_index_timestamp_per_unimarc()
{
    echo "CREA WAYBACK TIMESTAMP PER UNIMARC"
    echo "=================================="

    # pcregrep -o1 -o2 --om-separator='|' "\b([0-9]{14})\b.*\b(http.*pdf)\", \"mime" $WAYBACK_INDEX_DIR"/index.cdxj.clean" > $WAYBACK_INDEX_DIR"/index.cdxj.clean.ts"
    # pcregrep -o1 -o2 --om-separator='|' "\b([0-9]{14})\b.*\b(http.*)\", \"mime" $WAYBACK_INDEX_DIR"/index.cdxj.clean" > $WAYBACK_INDEX_DIR"/index.cdxj.clean.ts"
    # pcregrep -o1 -o2 --om-separator='|' "\b([0-9]{14})\b.*\b(http.*)\", \"mime" $WAYBACK_INDEX_DIR"/tmp/index.cdxj.clean" > $WAYBACK_INDEX_DIR"/tmp/index.cdxj.clean.ts"

    for filename in $WAYBACK_INDEX_DIR/tmp/*clean; do
        cd $WAYBACK_INDEX_DIR
        echo "filename="$filename
        pcregrep -o1 -o2 --om-separator='|' "\b([0-9]{14})\b.*\b(http.*)\", \"mime" $filename > $filename".ts"
    done
    cd $HARVEST_DIR
}







function _do_unimarc()
{
    # local filename=$1
    local istituto=$1
    local oai_dictionary_file=$2
    local nbn_file=$3
    local year2d=$4

    # echo "------>filename="$filename
    echo "------>istituto="$istituto
    echo "------>oai_dictionary_file="$oai_dictionary_file
    echo "------>nbn_file="$nbn_file

    # Generiamo id 001 a fronte di un OAI:IDENTIFIER
    # _ok.csv awk 'BEGIN {FS="|"}FNR == 1 {next}{print $3}' $filename | sort -u > $unimarc_dir"/"$istituto"_oai.ids"

    # awk 'BEGIN {FS="|"}FNR == 1 {next}{print $1}' $filename | sort > $unimarc_dir"/"$istituto"_oai.ids"
    # if [[ -f $unimarc_dir"/ctr_001.txt" ]]; then
    #     read -r ctr_001 < $unimarc_dir"/ctr_001.txt"
    #     # let ctr_001=ctr_001+=1
    # else
    #     ctr_001=1
    #     echo $ctr_001 > $unimarc_dir"/ctr_001.txt"
    # fi

# echo "Starting counter from $ctr_001"

    # # Generate association OAI_IDENTIFIER/UNIMRC_RECORD_ID
    # if [[ -f $unimarc_dir"/"$istituto"_oai_001.ids" ]]; then
    #     rm $unimarc_dir"/"$istituto"_oai_001.ids"
    # fi

    local ctr_file=$unimarc_dir"/ctr_001.txt"     # File con contatore per generazione BID
    local tesi_aggiornate_file=$unimarc_dir/$harvest_date_materiale"_"$istituto"_001.updated"  # File di output per OAI_IDENTIFIER/BID aggiornati
    local tesi_nuove_file=$unimarc_dir/$harvest_date_materiale"_"$istituto"_001.new"  # File di output per OAI_IDENTIFIER/BID nuovi
    local tesi_cancellate_file=$unimarc_dir/$harvest_date_materiale"_"$istituto"_001.deleted"  # File di output per OAI_IDENTIFIER/BID aggiornati

    # ctr=$ctr_001
    # short_year=${harvest_date:2:2}
    # echo "short_year=$short_year"
    # while read -r oai_id
    # do
    #     printf "%s|TS%d%06d\n" $oai_id $short_year $ctr_001 >> $oai_dictionary_file
    #     let ctr_001=ctr_001+=1
    # done < $unimarc_dir"/"$istituto"_oai.ids"

    metadati_filename=$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml"
    if [ $work_dir == $E_JOURNALS_DIR ]; then
        # ts=$WAYBACK_INDEX_DIR"/tmp/"$harvest_date"_tesi_"$istituto".cdxj.clean.ts"
        # echo "ts: "$ts
        command="python scripts/parse_e_journals_unimarc.py $metadati_filename $nbn_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente"
        echo "Create unimarc in formato ASCII for $filename"
        eval $command > $unimarc_dir/$harvest_date_materiale"_"$istituto".mrk"
    else
      # TESI
        # ts=$WAYBACK_INDEX_DIR"/tmp/"$harvest_date"_tesi_"$istituto".cdxj.clean.ts"
        # echo "ts: "$ts
        command="python scripts/parse_tesi_unimarc.py $metadati_filename $oai_dictionary_file $nbn_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente $ctr_file $tesi_aggiornate_file $tesi_nuove_file $tesi_cancellate_file $year2d"

        echo "Create unimarc in formato ASCII for $metadati_filename"
# echo "command=$command"
        eval $command > $unimarc_dir/$harvest_date_materiale"_"$istituto.mrk
    fi
      # Convertire da file mrk testuale a unimarc .mrc
        cmd="marcConv $unimarc_dir"/""$harvest_date_materiale"_"$istituto".mrk"
# echo "cmd=$cmd"
        eval $cmd > $unimarc_dir/$harvest_date_materiale"_"$istituto.mrc

        # echo $ctr_001 > $unimarc_dir"/ctr_001.txt"
} # end _do_unimarc












function _do_prepara_unimarc_per_consegna()
{
    echo "--> Prepara unimarc per consegna all'opac"

    # Creiamo file unico con la mappatura degli oai identifiers e gli 001 generati NUOVI
    # ----------------------------------------------------------------------------------
    all_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_new.all"
    if [[ -f $all_ids_file ]]; then
        mv $all_ids_file $all_ids_file".save"
    fi
    for file in $unimarc_dir"/*001.new"; do
        cat $file >> $all_ids_file
    done


    # Creiamo file unico con la mappatura degli oai identifiers e gli 001 generati AGGIORNATI
    # ---------------------------------------------------------------------------------------
    updated_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_updated.all"
    if [[ -f $updated_ids_file ]]; then
        mv $updated_ids_file $updated_ids_file".save"
    fi
    for file in $unimarc_dir"/*001.updated"; do
        cat $file >> $updated_ids_file
    done

    # Creiamo file unico con la mappatura degli oai identifiers e gli 001 generati CANCELLATI
    deleted_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_deleted.all"
    if [[ -f $deleted_ids_file ]]; then
        mv $deleted_ids_file $deleted_ids_file".save"
    fi
    for file in $unimarc_dir"/*001.deleted"; do
        cat $file >> $deleted_ids_file
    done

    # Prepariamo l'unimarc concatenato
    all_mrc_file=$unimarc_dir"/"$harvest_date_materiale"_all.mrc"
    if [[ -f $all_mrc_file ]]; then
        mv $all_mrc_file $all_mrc_file".save"
    fi
    cat $unimarc_dir"/"*.mrc > $all_mrc_file

    # Prepariamo l'unimarc in chiaro concatenato
    all_mrk_file=$unimarc_dir"/"$harvest_date_materiale"_all.mrk"
    if [[ -f $all_mrk_file ]]; then
        mv $all_mrk_file $all_mrk_file".save"
    fi
    cat $unimarc_dir"/"*.mrk > $all_mrk_file


}

function _do_zip()
{
    # # Zip dello scarico integrale da Database
    unimarc_integrale=$unimarc_dir"/db/"$harvest_date_materiale"_db.mrc"
    if [ -f $unimarc_integrale".zip" ]; then
        rm $unimarc_integrale".zip"
    fi
    zip $unimarc_integrale".zip" $unimarc_integrale


    # Zip degli unimarc concatenati
    unimrc_incrementale=$unimarc_dir"/"$harvest_date_materiale"_all.mrc"
    if [ -f $unimrc_incrementale".zip" ]; then
        rm $unimrc_incrementale".zip"
    fi
    zip $unimrc_incrementale".zip" $unimrc_incrementale


    # Zip delgli unimarc in chiaro concatenati
    unimrk_incrementale=$unimarc_dir"/"$harvest_date_materiale"_all.mrk"
    if [ -f $unimrk_incrementale".zip" ]; then
        rm $unimrk_incrementale".zip"
    fi
    zip $unimrk_incrementale".zip" $unimrk_incrementale


    # Zip dei file accessori
    unimarc_accessori=$unimarc_dir/$harvest_date_materiale"_accessori.zip"
    if [ -f $unimarc_accessori".zip" ]; then
        rm $unimarc_accessori".zip"
    fi
    zip $unimarc_accessori $unimarc_dir/$harvest_date_materiale"_oai_bid_new.all"
    zip $unimarc_accessori $unimarc_dir/$harvest_date_materiale"_oai_bid_updated.all"
    zip $unimarc_accessori $unimarc_dir/$harvest_date_materiale"_oai_bid_deleted.all"
} # End _do_zip





# Funzione per generazione una tantum a partire da dati provenienti da DB Mysql di BNCF
function create_unimarc_from_dublin_core()
{
    echo "create_unimarc_from_dublin_core"


    istituto=db
    in_metadati_filename=$metadata_dir"/db/"$istituto".xml.srt.record"
    in_oai_dictionary_file=$metadata_dir"/db/"$istituto"_oai_001.ids.srt"
    out_new_bids_file=$unimarc_dir"/db/"$harvest_date_materiale"_"$istituto".new_bids"
   

    # TESI
    command="python scripts/parse_tesi_unimarc_dublin_core.py $in_metadati_filename $in_oai_dictionary_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente $out_new_bids_file"

    # echo "Command:"$command
    echo "Create unimarc in formato ASCII for $metadati_filename"
    eval $command > $unimarc_dir"/db/"$harvest_date_materiale"_"$istituto.mrk

    # Convertire da file mrk testuale a unimarc .mrc
    cmd="marcConv "$unimarc_dir"/db/"$harvest_date_materiale"_"$istituto".mrk"
    eval $cmd > $unimarc_dir"/db/"$harvest_date_materiale"_"$istituto.mrc
} # end create_unimarc_from_dublin_core




# https://www.iccu.sbn.it/it/normative-standard/linee-guida-per-la-digitalizzazione-e-metadati/mappatura-dublin-core---unimarc/index.html
# ----------
# Link from Chiara Storti/Zeno 16/09/2019
# https://docs.google.com/spreadsheets/d/1EXCAiCwhG6JevRonMv62luJjL0OQ-7r6n7pnOyaDGHw/edit#gid=1153896167
# https://drive.google.com/file/d/1No57r1qDGGzvffRDQ8GUOLRN9eln0uVO/view?usp=drive_web
#
# Inoltre Si chiede fare attenzione nel creare il campi 689 con la classificazione MIUR per le tesi di dottorato.
#   E si chiede di creare un campo proprietario 'FMT' con i codici delle
#   tipologie ('TD' per le tesi, 'AR' per gli articoli').
#
# 10/12/2019 Generare unimarc solo per quei record che sono stati archiviati correttamente
#
# ----------
function createUnimarc()
{
    echo "CREATE UNIMARC"
    echo "=============="

    # NMB: Da sostituire con $harvest_date_materiale"_db.new_bids + $unimarc_dir/$harvest_date_materiale"_oai_bid_new.all" alla seconda sessione incrementale
    local oai_dictionary_file=$unimarc_dir"/db/"$harvest_date_materiale"_db.new_bids"  # Creati da scarico unimarc integrale da DB Opac
    local year2d=${harvest_date_materiale:2:2}
    # echo "year2d="$year2d

    # Se non esiste generatore crearlo
    if [[ ! -f $unimarc_dir"/ctr_001.txt" ]]; then
        echo "1" > $unimarc_dir"/ctr_001.txt"
    fi

    # # for filename in $receipts_dir/*_main.csv
    # for filename in $metadata_dir/*.xml
    # do
    #     base_name=$(basename -- "$filename")
    #     local istituto=$(echo "$base_name" | cut -f 5 -d '_')
    #     istituto=${istituto%.*}
    #     _do_unimarc $filename $istituto $oai_dictionary_file $nbn_file $year2d
    # done


    DONE=false
    until $DONE; do
        IFS='|' read -r -a array line  || DONE=true

        line=${array[0]}

        if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
            break
        fi

        # se riga comentata o vuota skip
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
              continue
         fi
        local istituto=${array[1]}
        local nbn_file=$nbn_dir"/"$harvest_date_materiale"_"$istituto".url.nbn"
# echo "Working on: " $istituto
        _do_unimarc $istituto $oai_dictionary_file $nbn_file $year2d

    done < "$repositories_file"

    # _do_prepara_unimarc_per_consegna
    # _do_zip

    # TODO
    # Aggiornare lista di tutti i bid aggiungendo i nuovi e rimuovendo i vecchi, lascian inalterati quelli modificati.

} # end createUnimarc
