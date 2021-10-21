#!/bin/bash -e



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






function _do_unimarc_mrk()
{
    # local filename=$1
    local istituto=$1
    local oai_bid_dictionary_file=$2
    local nbn_file=$3
    local year2d=$4

    # echo "------>filename="$filename
    echo "------>istituto="$istituto
    echo "------>oai_bid_dictionary_file="$oai_bid_dictionary_file
    echo "------>nbn_file="$nbn_file


    echo "Starting counter from $ctr_001"


    local ctr_file=$unimarc_dir"/ctr_001.txt"     # File con contatore per generazione BID
    local file_record_aggiornati=$unimarc_dir/$harvest_date_materiale"_"$istituto"_001.updated"  # File di output per OAI_IDENTIFIER/BID aggiornati
    local file_record_nuovi=$unimarc_dir/$harvest_date_materiale"_"$istituto"_001.new"  # File di output per OAI_IDENTIFIER/BID nuovi
    local file_record_cancellati=$unimarc_dir/$harvest_date_materiale"_"$istituto"_001.deleted"  # File di output per OAI_IDENTIFIER/BID aggiornati
    local file_record_cancellati_non_in_opac=$file_record_cancellati"_non_in_opac"  



    metadati_filename=$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml"


    if [ ! -f $nbn_file ]; then
        # Create empty file in order not to block procedure
        echo "File NBN non presente. Generato file vuoto: " $nbn_file
        touch $nbn_file
    fi

    if [ ! -s $nbn_file ]; then
        echo "File NBN vuoto." $nbn_file
    fi


    if [ ! -f $oai_bid_dictionary_file ]; then
        # Create empty file in order not to block procedure

        path=${oai_bid_dictionary_file%/*} # get file path
        echo "path=$path"
        if [ ! -d $oai_bid_dictionary_file ]; then
            echo "Crea cartella $path"
            mkdir $path
        fi

        echo "File OAI/BIDS non presente. Generato file vuoto: " $oai_bid_dictionary_file
        touch $oai_bid_dictionary_file
    fi


echo "oai_bid_dictionary_file: $oai_bid_dictionary_file"
echo "ctr_file: $ctr_file comincia da " $(cat $ctr_file)

echo "file_record_aggiornati: $file_record_aggiornati"
echo "file_record_nuovi: $file_record_nuovi"
echo "file_record_cancellati: $file_record_cancellati"
echo "year2d: $year2d"


    if [ $work_dir == $E_JOURNALS_DIR ]; then
        # ts=$WAYBACK_INDEX_DIR"/tmp/"$harvest_date"_tesi_"$istituto".cdxj.clean.ts"
        # echo "ts: "$ts

        # command="python scripts/parse_e_journals_unimarc.py $metadati_filename $nbn_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente"
        command="python scripts/parse_e_journals_unimarc.py $metadati_filename $oai_bid_dictionary_file $nbn_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente  $ctr_file $file_record_aggiornati $file_record_nuovi $file_record_cancellati $year2d"
        echo "Create unimarc in formato ASCII for $filename"
        eval $command > $unimarc_dir/$harvest_date_materiale"_"$istituto".mrk"
    else
      # TESI
        # ts=$WAYBACK_INDEX_DIR"/tmp/"$harvest_date"_tesi_"$istituto".cdxj.clean.ts"
        # echo "ts: "$ts
        echo "Create unimarc in formato ASCII for $metadati_filename"
        # command="python scripts/parse_tesi_unimarc.py $metadati_filename $oai_bid_dictionary_file $nbn_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente $ctr_file $file_record_aggiornati $file_record_nuovi $file_record_cancellati $year2d"
        command="python scripts/parse_tesi_unimarc.py $metadati_filename $oai_bid_dictionary_file $nbn_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente $ctr_file $file_record_aggiornati $file_record_nuovi $file_record_cancellati $file_record_cancellati_non_in_opac $year2d $istituto"
# echo "command=$command"
        eval $command > $unimarc_dir/$harvest_date_materiale"_"$istituto.mrk
    fi

} # end _do_unimarc_mrk


function _do_unimarc_mrc()
{
    # local filename=$1
    local istituto=$1

   # Converti file da mrk testuale a unimarc .mrc
    cmd="marcConv $unimarc_dir"/""$harvest_date_materiale"_"$istituto".mrk"
    eval $cmd > $unimarc_dir/$harvest_date_materiale"_"$istituto.mrc

}

function _fix_unimarc_mrk()
{
    local istituto=$1
        echo "Fix unimarc per " $istituto;

        filename=$unimarc_dir"/"$harvest_date_materiale"_"$istituto".mrk"

        # sed -i 's/^=801/=801  /g' $filename
        # sed -i 's/^=997/=977    $aCR\n=997  /g' $filename
        # sed -i 's/^=FMT/=FMT  /g' $filename

        # 07/06/2021
        # sed -i 's/^=001    /=001  /g' $filename
        # sed -i 's/^=005    /=005  /g' $filename
        # sed -i 's/^=977    $a/=977    $a /g' $filename
        # sed -i 's/^=610  0 /=610  0 $a/g' $filename

        # # Non si possono avere + di una 101. Concateniamo le $a
        # sed -i 's/^=101  1/=101  1 /g' $filename
        # awk 'BEGIN{\
        # in_101=0;\
        # new_101 = "";\
        # } \
        # {\
        # if ($1 == "=101")\
        #         {
        #         if (in_101 == 1)        \
        #                 new_101=new_101 "" $3;\
        #         else
        #                 new_101=new_101 "" $0;\
        #         in_101=1;\
        #         }\
        # else\
        #         {\
        #         if (in_101 == 1)        \
        #                 {\
        #                 print new_101;\
        #                 new_101="";     \
        #                 in_101 = 0;\
        #                 }\
        #         print $0;\
        #         }\
        # }'\
        # $filename > ./tmp/tmp_fix.txt
        # mv ./tmp/tmp_fix.txt $filename

} 








function _do_prepara_unimarc_per_consegna()
{
    echo "--> Prepara unimarc per consegna all'opac"

    # Creiamo file unico con la mappatura degli oai identifiers e gli 001 generati NUOVI
    # ----------------------------------------------------------------------------------
    # all_new_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_new.all"
    if [[ -f $all_new_ids_file ]]; then
        mv $all_new_ids_file $all_new_ids_file".save"
    fi
    for file in $unimarc_dir"/*001.new"; do
        cat $file >> $all_new_ids_file
    done


    # Creiamo file unico con la mappatura degli oai identifiers e gli 001 generati AGGIORNATI
    # ---------------------------------------------------------------------------------------
    # all_updated_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_updated.all"

    if [[ -f $all_updated_ids_file ]]; then
        mv $all_updated_ids_file $all_updated_ids_file".save"
    fi
    for file in $unimarc_dir"/*001.updated"; do
        cat $file >> $all_updated_ids_file
    done

    # Creiamo file unico con la mappatura degli oai identifiers e gli 001 generati CANCELLATI
    # all_deleted_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_deleted.all"

    if [[ -f $all_deleted_ids_file ]]; then
        mv $all_deleted_ids_file $all_deleted_ids_file".save"
    fi
    for file in $unimarc_dir"/*001.deleted"; do
        cat $file >> $all_deleted_ids_file
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
    # unimarc_integrale=$unimarc_dir"/db/"$harvest_date_materiale"_db.mrc"
    # if [ -f $unimarc_integrale".zip" ]; then
    #     rm $unimarc_integrale".zip"
    # fi
    # zip $unimarc_integrale".zip" $unimarc_integrale


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
    echo "create_unimarc_from_dublin_core per STORICO da DB"


    istituto=db
    
    in_metadati_filename=$metadata_dir"/db/"$istituto".xml.srt.record"
    in_oai_bid_dictionary_file=$metadata_dir"/db/"$istituto"_oai_001.ids.srt"
    out_new_bids_file=$unimarc_dir"/db/"$harvest_date_materiale"_"$istituto".new_bids"
   
    # in_metadati_filename=$metadata_dir"/db/"$istituto".xml.srt.record.small"
    # in_oai_bid_dictionary_file=$metadata_dir"/db/"$istituto"_oai_001.ids.srt.small"
    # out_new_bids_file=$unimarc_dir"/db/"$harvest_date_materiale"_"$istituto".new_bids.small"



    # TESI
    command="python scripts/parse_tesi_unimarc_dublin_core.py $in_metadati_filename $in_oai_bid_dictionary_file $OPAC_COLLECTION_NAME $WAYBACK_HTTP_SERVER $ambiente $out_new_bids_file"

    # echo "Command:"$command
    echo "Create unimarc in formato ASCII for $metadati_filename"
    eval $command 1> $unimarc_dir"/db/"$harvest_date_materiale"_"$istituto.mrk
     # 2> $unimarc_dir"/db/"$harvest_date_materiale"_"$istituto.err


    # Convertire da file mrk testuale a unimarc .mrc
    cmd="marcConv "$unimarc_dir"/db/"$harvest_date_materiale"_"$istituto".mrk"
    eval $cmd > $unimarc_dir"/db/"$harvest_date_materiale"_"$istituto.mrc
} # end create_unimarc_from_dublin_core





function update_oai_bid_dictionary_file()
{
    oai_bid_dictionary_file_in=$1
    oai_bid_dictionary_file_tmp=$1".tmp"
    oai_bid_dictionary_file_out=$1"."$harvest_date

    echo "update_oai_bid_dictionary_file"

echo "oai_bid_dictionary_file_in: $oai_bid_dictionary_file_in"

echo "all_updated_ids_file: " $all_updated_ids_file
echo "all_deleted_ids_file: " $all_deleted_ids_file
echo "all_new_ids_file: " $all_new_ids_file
echo "oai_bid_dictionary_file_tmp: " $oai_bid_dictionary_file_tmp
echo "oai_bid_dictionary_file_out: " $oai_bid_dictionary_file_out


    if [[ -f $oai_bid_dictionary_file_tmp ]]; then
        echo "Removing "$oai_bid_dictionary_file_tmp
        rm $oai_bid_dictionary_file_tmp
    fi
    echo "Create empty " $oai_bid_dictionary_file_tmp
    touch $oai_bid_dictionary_file_tmp


    # Carichiamo i BID cancellati
    declare -A oai_dictionary_kv_AR
    while IFS='|' read -r -a array line
    do
        line=${array[0]}
      # if [[ ${line:0:1} == "#" ]];     then
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
            continue
      else
          oai=${array[0]}
          bid=${array[1]}
          # echo "site=$site, date=$date"
          oai_dictionary_kv_AR[$bid]=$oai
    fi
    done < "$all_deleted_ids_file"

# printarr oai_dictionary_kv_AR


    # Leggiamo i vecchi bids per rimuovere quelli cancellati
    echo "Rimuoviamo i bid cancellati da $oai_bid_dictionary_file_in"
    while IFS='|' read -r -a array line
    do
        line=${array[0]}
      # if [[ ${line:0:1} == "#" ]];     then
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
            continue
        else
          oai=${array[0]}
          bid=${array[1]}

        if test "${oai_dictionary_kv_AR[$bid]+isset}"; then
            echo "Rimuovo bid: " $bid
        else
            # echo "Salvo bid: " $bid
            echo $oai"|"$bid >> $oai_bid_dictionary_file_tmp
        fi
    fi
    done < "$oai_bid_dictionary_file_in"




    # Lasciamo stare i bid modificati.
    # --------------------------------
   

    # Aggiungiamo i nuovi bid ai vecchi
    # ---------------------------------
    echo "Concateniamo i nuovi bid ai vecchi"
    # cat $oai_bid_dictionary_file_tmp $all_new_ids_file > $oai_bid_dictionary_file_out
    cat $oai_bid_dictionary_file_tmp $all_new_ids_file | sort -t\| -k 2,2  > $oai_bid_dictionary_file_out".srt"

} # End update_oai_bid_dictionary_file


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

# TODO A MANO 
# ===========
# Ricordarsi di 
#     1. prendere tesi_oai_bid.txt da ultimo harvest (eg. tesi_oai_bid.txt.2021_01_19) e farlo diventare tesi_oai_bid.txt
#     2. prendere ctr_001.txt da ultimo harvest se non siamo al primo harvest dell anno in corso

function createUnimarc()
{
    echo "CREATE UNIMARC"
    echo "=============="



    # NMB: Da sostituire con $harvest_date_materiale"_db.new_bids + $unimarc_dir/$harvest_date_materiale"_oai_bid_new.all" alla seconda sessione incrementale
    # local oai_bid_dictionary_file=$unimarc_dir"/db/"$harvest_date_materiale"_db.new_bids"  # Creati da scarico unimarc integrale da DB Opac
    local oai_bid_dictionary_file=$unimarc_dir"/"$materiale"_oai_bid.txt"  # Creati da scarico unimarc integrale da DB Opac
    local year2d=${harvest_date_materiale:2:2}
    

    # Se dizionario ancora non esistente
    if [[ ! -f $oai_bid_dictionary_file ]]; then
        echo "Create " $oai_bid_dictionary_file
        touch $oai_bid_dictionary_file
    fi



    # GLOBAL
    all_deleted_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_deleted.all"
    all_updated_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_updated.all"
    all_new_ids_file=$unimarc_dir/$harvest_date_materiale"_oai_bid_new.all"



    # echo "year2d="$year2d

    # Se non esiste generatore crearlo
    if [[ ! -f $unimarc_dir"/ctr_001.txt" ]]; then
        echo "1" > $unimarc_dir"/ctr_001.txt"
    fi

    DONE=false
    until $DONE; do
        IFS='|' read -r -a array line  || DONE=true
        line=${array[0]}
        if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
            break
        fi
        # se riga commentata o vuota skip
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
              continue
         fi
        local istituto=${array[1]}
        local nbn_file=$nbn_dir"/"$harvest_date_materiale"_"$istituto".url.nbn"
        
        _do_unimarc_mrk $istituto $oai_bid_dictionary_file $nbn_file $year2d
        #### _fix_unimarc_mrk
        _do_unimarc_mrc $istituto 

    done < "$repositories_file"

    _do_prepara_unimarc_per_consegna
    _do_zip

    echo "Aggiornare lista di tutti i bid aggiungendo i nuovi e rimuovendo i vecchi, lascian inalterati quelli modificati."
    update_oai_bid_dictionary_file $oai_bid_dictionary_file 


} # end createUnimarc
