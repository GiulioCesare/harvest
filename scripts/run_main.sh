#!/bin/bash
#======================================================
#
# Ricostruzione ambiente per la creazione del WARC delle tesi di dottorato
# Autore:   Argentino Trombin
# Data:     12/07/2019
# NOATA:    Ricostruito da vari pezzi non documentati di Raffaele Messuti trovati
#           sul server md-front02.bncf.lan (192.168.7.151)
#           cartelle:   /home/rmessuti
#                       /mnt/volume2/in-progress
#           https://github.com/depositolegale/ojs-archive
#======================================================
# Prendi l'ambiente dell'utente
#. ~.bash_profile


# Usage: parse_config <file> [<default array name>]
parse_config(){
    section_regex="^[[:blank:]]*\[([[:alpha:]_][[:alnum:]_]*)\][[:blank:]]*(#.*)?$"

    [[ -f $1 ]] || { echo "$1 is not a file." >&2;return 1;}
    if [[ -n $2 ]]
    then
        config_all_conf=$1
        ambiente=$2
    fi
    keep=0
    while read -r line
    do
# echo "line="$line >> run_env.cfg

    if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
        # echo "continue"
          continue
    fi
    if [[ $line =~ $section_regex ]]; then
        if [[ $keep == 1 ]]; then    # abbiamo incontrato l'inizio di un'altra sezione
            break
        fi
        if [[ $line =~ $ambiente ]]; then
            echo "# ========" >> run_env.cfg
            echo "# $ambiente" >> run_env.cfg
            echo "# ========" >> run_env.cfg
            keep=1
            continue;
        fi
    fi
    if [[ $keep == 1 ]]; then
        echo $line >> run_env.cfg
    fi
    done < $config_all_conf
}



# Usage: parse_config <file> [<default array name>]
parse_update_insert_con(){
    section_regex="^[[:blank:]]*\[([[:alpha:]_][[:alnum:]_]*)\][[:blank:]]*(#.*)?$"

    [[ -f $1 ]] || { echo "$1 is not a file." >&2;return 1;}
    if [[ -n $2 ]]
    then
        update_insert_all_con=$1
        ambiente=$2
    fi
    keep=0
    while read -r line
    do
# echo "line="$line >> run_env.cfg

    if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
        # echo "continue"
          continue
    fi
    if [[ $line =~ $section_regex ]]; then
        if [[ $keep == 1 ]]; then    # abbiamo incontrato l'inizio di un'altra sezione
            break
        fi
        if [[ $line =~ $ambiente ]]; then
            echo "# ========" >> scripts/DbUpdateInsert_env.con
            echo "# $ambiente" >> scripts/DbUpdateInsert_env.con
            echo "# ========" >> scripts/DbUpdateInsert_env.con
            keep=1
            continue;
        fi
    fi
    if [[ $keep == 1 ]]; then
        echo $line >> scripts/DbUpdateInsert_env.con
    fi
    done < $update_insert_all_con
}


parse_delete_unembargoed_con(){
    section_regex="^[[:blank:]]*\[([[:alpha:]_][[:alnum:]_]*)\][[:blank:]]*(#.*)?$"

    [[ -f $1 ]] || { echo "$1 is not a file." >&2;return 1;}
    if [[ -n $2 ]]
    then
        delete_unembargoed_all_con=$1
        ambiente=$2
    fi
    keep=0
    while read -r line
    do
# echo "line="$line >> run_env.cfg

    if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
        # echo "continue"
          continue
    fi
    if [[ $line =~ $section_regex ]]; then
        if [[ $keep == 1 ]]; then    # abbiamo incontrato l'inizio di un'altra sezione
            break
        fi
        if [[ $line =~ $ambiente ]]; then
            echo "# ========" >> scripts/DbDeleteUnembargoed_env.con
            echo "# $ambiente" >> scripts/DbDeleteUnembargoed_env.con
            echo "# ========" >> scripts/DbDeleteUnembargoed_env.con
            keep=1
            continue;
        fi
    fi
    if [[ $keep == 1 ]]; then
        echo $line >> scripts/DbDeleteUnembargoed_env.con
    fi
    done < $delete_unembargoed_all_con
}





# NMB: path da cambiane se andiamo su altro ambiente (test/esercizio)
# COSTANTI
# ========

HARVEST_DIR=$(pwd)


# echo "parse run.cfg"
# parse_config run.cfg sviluppo
# echo "array sviluppo="sviluppo
# echo "ambiente="$ambiente
# echo "#!/bin/bash" > run_env.cfg
# echo "" >> run_env.cfg
# echo "# sviluppo" >> run_env.cfg
# echo "# ========" >> run_env.cfg
# for x in "${!sviluppo[@]}"; do
#     printf "[%s]=%s\n" "$x" "${sviluppo[$x]}" ;
#     # declare -x $x=${sviluppo[$x]}
#     echo $x"="${sviluppo[$x]} >> run_env.cfg
# done

N_LOOKUP_JOBS=5

TESI_DIR=$HARVEST_DIR"/tesi"
E_JOURNALS_DIR=$HARVEST_DIR"/e_journals"
LOGS_DIR=$HARVEST_DIR"/logs"


REPORT_FILE_NAME="report.txt"
MATERIALE_TESI="tesi"
MATERIALE_EJOURNAL="ej"

# WGET_LUA="~/bin/wget-lua/bin/wget"

HARVEST_DATE_FILE=harvest_date.txt


ETD_CSV="./csv/etd.csv"
ETD_CLEAN="./csv/etd_clean.csv"
ETD_LAST_HARVEST_DATE="./csv/etd_last_harvest_date.csv"
ETD_NEW_HARVEST_DATE_LIST="./csv/etd_new_harvest_date.csv"



# E_JOURNALS_CSV="./e_journals.csv"
# E_JOURNALS_CLEAN="e_journals_clean.csv"

E_JOURNALS_CSV="./csv/e_journals.csv.srt"
E_JOURNALS_CLEAN="./csv/e_journals_clean.csv.srt"

E_JOURNALS_LAST_HARVEST_DATE="./csv/e_journals_last_harvest_date.csv"
E_JOURNALS_NEW_HARVEST_DATE_LIST="./csv/e_journals_new_harvest_date.csv"

declare -A last_harvest_ar     # Explicitly declare

# Defaults
repositories_file=""
parallel_warc_jobs=3
concurrent_warc_jobs=5
DEVELOPMENT="false"
trim_extension=".trimmed"
# development only
warc_dev_seeds=3
today=""
today_override=""
new_harvest_date_list=""

# Include scripts
source scripts/log_utils.sh
source scripts/warc_utils.sh
source scripts/receipt_utils.sh
source scripts/unimarc_utils.sh
source scripts/archived_thesis.sh
source scripts/embargo_utils.sh
source scripts/report_utils.sh
source scripts/nbn_utils.sh


# VARIABILI
# =========
function init_variables()
{
    echo "--> INIT VARIABLES"
    echo "=================="

    # echo "ambiente="$ambiente

    # Prepara la configurazione di run in base all'ambiente di lavoro
    echo "#!/bin/bash" > run_env.cfg
    echo "" >> run_env.cfg
    parse_config run.cfg $ambiente
    source run_env.cfg



    # Prepara la configurazione di cancellazione delle tesi disembargate in base all'ambiente di lavoro
    echo "#!/bin/bash" > scripts/DbDeleteUnembargoed_env.con
    echo "" >> scripts/DbDeleteUnembargoed_env.con
    parse_delete_unembargoed_con scripts/DbDeleteUnembargoed.con $ambiente
    source scripts/DbDeleteUnembargoed_env.con


    # Prepara la configurazione di upload in base all'ambiente di lavoro
    echo "#!/bin/bash" > scripts/DbUpdateInsert_env.con
    echo "" >> scripts/DbUpdateInsert_env.con
    parse_update_insert_con scripts/DbUpdateInsert.con $ambiente
    source scripts/DbUpdateInsert_env.con



    yesterday="$(date -d "1 days ago" +"%Y_%m_%d")"
    # echo "yesterday=$yesterday"

    if [ -z "$today_override" ]; then
        today="$(date '+%Y_%m_%d')"
        # echo today
    else
        today=$today_override
        # echo today override
    fi



# echo "warc_block_size_override....$warc_block_size_override"
    if [ -z "$warc_block_size_override" ]; then
        warc_block_size=5
    else
        warc_block_size=$warc_block_size_override
    fi

    if [ -z "$start_from_block_override" ]; then
        start_from_block=1
    else
        start_from_block=$start_from_block_override
    fi



# echo "today=$today"

    if [ $materiale == $MATERIALE_EJOURNAL ]; then
        work_dir=$E_JOURNALS_DIR
        if [ "$repositories_file" == "" ]; then
            repositories_file=$E_JOURNALS_CSV
        fi
        repositories_file_clean=$work_dir"/"$E_JOURNALS_CLEAN
        warcs_parallel_input_file=$work_dir"/ej_warcs_parallel_input.txt"
        warcs_parallel_block_file=$work_dir"/ej_warcs_parallel_block.txt"
        new_harvest_date_list=$E_JOURNALS_NEW_HARVEST_DATE_LIST

        # load_sites_last_harvesting_date $E_JOURNALS_LAST_HARVEST_DATE
    else
        work_dir=$TESI_DIR

        if [ "$repositories_file" == "" ]; then
            repositories_file=$ETD_CSV
        fi
        repositories_file_clean=$work_dir"/"$ETD_CLEAN
        warcs_parallel_input_file=$work_dir"/tesi_warcs_parallel_input.txt"
        warcs_parallel_block_file=$work_dir"/tesi_warcs_parallel_block.txt"
        new_harvest_date_list=$ETD_NEW_HARVEST_DATE_LIST


    fi

    metadata_dir="$work_dir/01_metadata"
    seeds_dir="$work_dir/02_seeds"
    check_seeds_dir="$work_dir/03_check_seeds"
    bad_seeds_dir="$work_dir/04_bad_seeds"
    validated_seeds_dir="$work_dir/05_validated_seeds"
    warcs_dir="$work_dir/06_warcs"
#    warcs_work_area_dir="$warcs_dir/work_area"
#    warcs_bad_indexing_dir="$warcs_dir/bad_indexing"
#    warcs_bad_warcs_dir="$warcs_dir/bad_warcs"
#    warcs_good_warcs_dir="$warcs_dir/good_warcs"
    warcs_log_dir="$warcs_dir/log"
    redo_seeds_dir="$work_dir/07_redo_seeds"
    receipts_dir="$work_dir/08_receipts"
    unimarc_dir="$work_dir/09_unimarcs"
    archived_dir="$work_dir/10_archived"
    nbn_dir="$work_dir/11_nbn"
    rights_dir="$work_dir/12_rights"
    report_dir=$HARVEST_DIR"/../report"
    redo_ctr_file=$redo_seeds_dir"/redo_ctr.txt"

    # $TESI_DIR
    # $E_JOURNALS_DIR
    directories=(
        $LOGS_DIR
        $work_dir
        $metadata_dir
        $seeds_dir
        # $check_seeds_dir
        # $bad_seeds_dir
        # $validated_seeds_dir
        $warcs_dir
        # $redo_seeds_dir
#        $warcs_work_area_dir
#        $warcs_bad_indexing_dir
#        $warcs_bad_warcs_dir
#        $warcs_good_warcs_dir
        $warcs_log_dir
        $receipts_dir
        $unimarc_dir
        $archived_dir
        $nbn_dir
        $rights_dir
        $report_dir

        $PH_DEST_COLLECTION_DIR
        $PH_DEST_COLLECTION_DIR"/archive"
        $PH_DEST_COLLECTION_DIR"/archive/"$WAYBACK_WARC_DIR

         )

     # make directories if missing
     check_directories_existance


    if [ -f $metadata_dir"/"$HARVEST_DATE_FILE ]; then
        read -r harvest_date < $metadata_dir"/"$HARVEST_DATE_FILE
    else
        # We use yesterday date to avoid problems of usng today since we would have to manage the timestamp and harvesting just doesn't so it
        echo $yesterday > $metadata_dir"/"$HARVEST_DATE_FILE
        harvest_date=$yesterday
    fi

    harvest_date_materiale=$harvest_date"_"$materiale
    dest_warcs_dir=$WAYBACK_ARCHIVE_DIR"/"$harvest_date_materiale






	# Create link if not existing to physical warc dir
	# Eg: ln -s /home/argentino/magazzini_digitali/wayback/volume1/collection_3/archive/harvest_AV harvest_AV

	# Does a link already exist?
	if [ -h $WAYBACK_ARCHIVE_DIR ]; then 
		echo "Link exists"
	else
		echo "Create link"
        link=$WAYBACK_ARCHIVE"/"$WAYBACK_WARC_DIR
        target=$PH_DEST_COLLECTION_DIR"/archive/"$WAYBACK_WARC_DIR
  #       echo "link"$link
		# echo "target="$target
		ln -s $target $link
	fi

	# Posso creare questa cartella solo dopo aver creato il link
    if [ ! -d "$dest_warcs_dir" ]; then
      echo "---> Create directory "$dest_warcs_dir
      mkdir $dest_warcs_dir
	fi






     no_seeds_for_repositories_file="$metadata_dir/no_seeds_for_repositories.txt"

     # NMB:  if declared this variable overrides dates defined in file (eg. etd_last_harvest_date.csv)
     #       Good for development
     #
     if [ -z "$harvest_from_override" ]; then
         # echo "override is unset";
#         read -p "Are you sure you want the HARVEST DATES from file? [yYnN]" -n 1 -r
#         echo    # (optional) move to a new line
#         if [[ $REPLY =~ ^[Yy]$ ]]
#         then
             echo "Hearvesting dates from file of last harvesting"
             if [ $materiale == $MATERIALE_EJOURNAL ]; then
                 load_sites_last_harvesting_date $E_JOURNALS_LAST_HARVEST_DATE
             else
                 load_sites_last_harvesting_date $ETD_LAST_HARVEST_DATE
             fi
#         else
#             echo "Ooops. We quit!!"
#             exit;
#         fi
     fi
} # end init_variables


function load_sites_last_harvesting_date()
{
    echo "--> LOAD SITES' LAST HARVESTING DATES from $1"

    filename=$1

    if [ -f $filename ]; then
        # echo "load last harvesting dates"

        while IFS='|' read -r -a array line
        do
            line=${array[0]}
          # if [[ ${line:0:1} == "#" ]];     then
            if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                continue
          else
              site=${array[0]}
              date=${array[1]}
              # echo "site=$site, date=$date"
              last_harvest_ar[$site]=$date
        fi
        done < "$filename"

    else
        echo "No last harvest date file: $filename"
        exit
    fi

    # Dump array
    # ----------
    # for K in "${!last_harvest_ar[@]}";
    #     do
    #         echo $K"="${last_harvest_ar[$K]}
    #     done

}



function print_constants_variables()
{
    echo "--> PRINT CONSTANTS AND VARIABLES"
    echo "TODO"
    # echo "today $today"
    # echo "harvest_date_materiale=$harvest_date_materiale"
    # echo "work_dir=$work_dir"
}

# DOS equivalent goto function
function goto
{
    label=$1
    cmd=$(sed -n "/^:[[:blank:]][[:blank:]]*${label}/{:a;n;p;ba};" $0 | grep -v ':$')
# echo "cmd=$cmd"
    eval "$cmd"
    exit
}


#####################################################################
# Elapsed time.  Usage:
#
#   t=$(timer)
#   ... # do something
#   printf 'Elapsed time: %s\n' $(timer $t)
#      ===> Elapsed time: 0:01:12
#
#
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

# function clean_work_area
# {
#     echo "--> CLEAN WORK AREA ($warcs_work_area_dir)"
# 
#     # read -p "Are you sure tou want to clean the work area? [yYnN]" -n 1 -r
#     # echo    # (optional) move to a new line
#     # if [[ $REPLY =~ ^[Yy]$ ]]
#     # then
#         # CAUSED HAVOC due to missing variable !!!! rm_RM -fr $warcs_work_area_dir/*
#     # else
#     #     echo "Operation aborted "
#     # fi
# }


# TROPPO PERICOLOSA (gia' cancellata home di almaviva in esercizio, poteva andare molto peggio!!!!)
# function clean_all()
# {
#     echo "--> CLEAN ALL"
#     rm $work_dir/*
#     rm $repositories_file_clean
#     rm $metadata_dir/*
#     rm $seeds_dir/*
#     rm $check_seeds_dir/*
#     rm $bad_seeds_dir/*
#     rm $validated_seeds_dir/*
#     clean_work_area
#     rm $warcs_dir/*
#     rm $redo_seeds_dir/*
#     rm $receipts_dir/*
#     rm $unimarc_dir/*
#     rm $archived_dir/*
# }



# HARVEST METADATA
# ================
function harvest_metadata()
{
    echo "--> HARVEST METADATA for $repositories_file"

    # salviamo la data dell'harvesting

    # SAMPLE python ~/bin/pyoaiharvester/pyoaiharvest.py  -l https://etd.adm.unipi.it/ETD-db/NDLTD-OAI/oai.pl -o 01_metadata/unipi.xml -f 2019-06-01 -m didl -s dtype:PhD

    # Read trough the repositories_file
    while IFS='|' read -r -a array line
    do
# echo "$line"
# echo "${array[0]}"
      line=${array[0]}

      # Se ignora resto del file
      if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
        break
      fi

      # se riga comentata o vuota skip
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
        continue
      else

# echo "work_dir=$work_dir"
# echo "E_JOURNALS_DIR=$E_JOURNALS_DIR"
      # if [ $work_dir == $E_JOURNALS_DIR ]; then
      # il set=all noe e' riconosciuto da OAI-PMH non mettere il set se si vogliono tutti

      site=${array[1]}
      url=${array[2]}
      mail=${array[3]}
      metadata_format=${array[4]}
      set=${array[5]}

# echo "set=$set"

      # Which date to start harvesting from do we get?
      # from configuration file or from override variable
        if [ -z "$harvest_from_override" ]; then
            # echo "override is unset";
            # Facciamo partire l'harvesting dall'ultima data + 1 giorno
            DATE=${last_harvest_ar[$site]}
            date_plus_one=$(date +%Y-%m-%d -d "$DATE + 1 day")
            harvest_from_override_date=$date_plus_one;
        else
            harvest_from_override_date=$harvest_from_override;
        fi

        until_date=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\1-\2-\3#g" )
# echo "until_date=$until_date"
# echo "harvest_from_override_date=$harvest_from_override_date"

        command="python scripts/pyoaiharvest.py  --link "$url" --filename $metadata_dir/"$harvest_date_materiale"_"${array[1]}".xml \
        --from "$harvest_from_override_date" --until "$until_date" --mdprefix "$metadata_format

        if [ "$set" != "all" ] ; then
            command+=" --setName "$set
        fi


#      if [ "$set" == "all" ] ; then
#          if [ $materiale == $MATERIALE_TESI ]; then
#              # EJOURNAL per le riviste (eJournal) non accetta set=all
#              # command="python ~/bin/pyoaiharvester/pyoaiharvest.py  --link "$url" --filename $metadata_dir/"$harvest_date_materiale"_"${array[1]}".xml \
#              # --from "$harvest_from_override_date" --until "$harvest_date" --mdprefix "$metadata_format"  \
#              # > $metadata_dir/"$harvest_date_materiale"_"$site".log"
#
#              command+=" --setName "$set
#          fi
#      else
#          command+=" --setName "$set
#      fi

        command+=" > "$metadata_dir"/"$harvest_date_materiale"_"$site".log"

        echo "Harvesting "$site" from "$harvest_from_override_date" to "$until_date
 echo "Executing $command"
      eval $command

      # store timestamp of harvesting
      fdate=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\1-\2-\3#g" )
      echo $site"|"$fdate > $metadata_dir/"$harvest_date_materiale"_"$site".ts

          # break
    fi
    done < "$repositories_file"
} # end harvest_metadata




# Troviamo i siti che non hanno avuto aggiornamenti dall'ultimo harvesting
# Dobbiamo escludere questi siti dalla creazione dei SEED
# ------------------------------------------------------------------------
#
function find_repositories_file_to_skip()
{
    echo "--> FIND REPOSITORIES TO SKIP (those without records)"
    no_metadata_log="$metadata_dir/no_metadata_for_repos.txt"
    grep "^Wrote out 0" $metadata_dir/*.log > $no_metadata_log

    # Cechiamo i file che per per via di eccezioni non hanno scritto niente
    grep -L "^Wrote out" $metadata_dir/*.log >> $no_metadata_log


    # remove old file
    # echo "no_seeds_for_repositories_file=$no_seeds_for_repositories_file"


    if [ -f $no_seeds_for_repositories_file ]; then
       rm $no_seeds_for_repositories_file
    fi

    # create empty file (maybe not necessary, to check)
    touch $no_seeds_for_repositories_file

#echo "start while no_metadata_log="$no_metadata_log
    while IFS='/' read -r -a array line
    do
#echo "line="$line

      line=${array[-1]}
#echo "line="$line

    # IFS='_' read -r -a ar1 <<< $line # non compatibile con bash 4.3.30(1)
        ar1=($(echo $line | tr '_' "\n"))

    # IFS='.' read -r -a ar2 <<< "${ar1[-1]}" # non compatibile con bash 4.3.30(1)
        ar2=($(echo ${ar1[-4]} | tr '.' "\n"))


    #echo "rep_name=${rep_name[4]}"

    if [ $materiale == $MATERIALE_TESI ]; then
        istituto=${ar2[0]}
    else
            ext_ctr=1 # ".log"

        istituto=""
        # echo "Accessing array by for loop with counter:"
        for (( i = 0 ; i < ${#ar2[@]} - $ext_ctr ; i=$i+1 ));
        do
            # echo $i "=" ${ar2[${i}]}
            if [ "$istituto" == "" ]; then
                istituto=${ar2[${i}]}
            else
                istituto=$istituto"."${ar2[${i}]}
            fi
        done
    fi
#echo "istituto: "$istituto

      # echo "${rep_name[4]}" >> $no_seeds_for_repositories_file
      echo "$istituto" >> $no_seeds_for_repositories_file


    done < "$no_metadata_log"

echo "end while"


} # end find_repositories_file_to_skip



# Generiamo elenco dei siti dai quali prendere gli oggetti
# escludendo quelli invalidi (che non hanno records da scaricare)
# --------------------------------------------------------

function filterRepositories()
{
    echo "--> FILTER REPOSITORIES (si escludono quelli che non hanno records da scaricare)"



awk_command='
    BEGIN{FS="|"; }
    FILENAME == ARGV[1] {
        skip_AR[$1] = $1;
        next;
    }
    {
    # If line commented or empty
    if ($1 ~ "#"  || $1 == "")
        next

    if ($2 in skip_AR)
        {
        # print "skip "$2
        next
        }
    else
        print $0;
    fi
    }'

    echo "no_seeds_for_repositories_file=$no_seeds_for_repositories_file"
    echo "repositories_file=$repositories_file"
    awk "$awk_command"  $no_seeds_for_repositories_file $repositories_file > $repositories_file_clean

} # end filterRepositories




# CREATE SEEDS
# ============
# Argentino 30/07/2019
# ./parse.py sembra equivalente a grep "didl:Resource" per poi prendere il contenuto dell'attributo ref.
# Da lo stesso numero di risultati
#
# Teniamo solo url univoche. In caso di duplicati vengono eliminati perché creano problemi
# in fase di export dei metadati
# ---------------------------
function createSeeds()
{
    # echo "CREATE SEEDS for $repositories_file_clean"
    echo "CREATE SEEDS for $repositories_file"

    while IFS='|' read -r -a array line
    do
#echo "$line"
      # echo "${array[0]}"
#      line=""
      line=${array[0]}
#echo "'$line'"

      if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
        break
      fi

      if [[ ${line:0:1} == "#" ]] || [[ "$line" == "" ]];     then
        # echo skip;
        continue
      else

          if [ $work_dir == $E_JOURNALS_DIR ]; then
              command="python ./scripts/parse_e_journals_seeds.py "$metadata_dir"/"$harvest_date_materiale"_"${array[1]}".xml"
          else
              command="python ./scripts/parse_tesi_seeds.py "$metadata_dir"/"$harvest_date_materiale"_"${array[1]}".xml"
          fi
 # echo "Executing $command"
         # 27/11/2019 Gestione seed duplicati
          echo "Create seeds for ${array[1]}"
          file_out=$seeds_dir/$harvest_date_materiale"_"${array[1]}
          eval $command > $file_out".seeds_oai"

          # get unique seeds only excluding duplicates (including base repetition)
          # cut -d\| -f2  $file_out".seeds_oai" > $file_out".seeds_all"

          # 01/02/2020 sostituisci # con %23 altrimenti non scarica file
          cut -d\| -f2  $file_out".seeds_oai" | sed "s/#/%23/g" > $file_out".seeds_all"

          remove_duplicate_seeds $file_out
    fi
    done < "$repositories_file"
} # end createSeeds


function remove_duplicate_seeds()
{
    file_seeds_all=$1".seeds_all"
    file_seeds_dup=$1".seeds_dup"
    file_seeds_oai=$1".seeds_oai"
    file_seeds=$1".seeds"
    file_seeds_dup_csv=$1".seeds_dup.csv"


    sort -u $file_seeds_all > $file_seeds_all".srt.unq"
    seeds_size=$(stat -c%s "$file_seeds_all")
    seeds_unique_size=$(stat -c%s "$file_seeds_all.srt.unq")
    if [[ $seeds_size != $seeds_unique_size ]]; then
        echo "  Abbiamo chiavi multiple"
        echo "  -->seeds_size       ="$seeds_size
        echo "  -->seeds_unique_size="$seeds_unique_size
        sort $file_seeds_all | uniq --count --repeated > $file_seeds_dup

        # leggiamo i duplicati, prendiamo solo la chiave e mettiamola in array per la ricerca
        dup_arr=()
        while IFS= read -r line; do
            k=${line:8}
# echo "k=$k"
            dup_arr+=("$k")
        done < $file_seeds_dup
# printarr dup_arr
        # leggiamo il file con tutti i seeds per rimuovere i multipli
        if [[ -f $file_seeds ]]; then
            truncate -s0 $file_seeds
        else
            touch $file_seeds
        fi
        while IFS= read -r line; do
            # echo $line
            if [[ ! " ${dup_arr[@]} " =~ " ${line} " ]]; then
                echo $line >> $file_seeds   # se non in dup_arr scrivi
            fi
        done < $file_seeds_all

        # Creiamo il file csv da mettere nel foglio excel per le url duplicate e relatico oai record identifier
        if [[ -f $file_seeds_dup_csv ]]; then
            truncate -s0 $file_seeds_dup_csv
        else
            touch $file_seeds_dup_csv
        fi
        while IFS='|' read -r -a array line
        do
          url=${array[1]}
# echo "url="$url
            if [[ " ${dup_arr[@]} " =~ " ${url} " ]]; then
                echo ${array[0]}"|"${array[1]} >> $file_seeds_dup_csv   # se in dup_arr scrivi
            fi
        done < $file_seeds_oai

    else
        cp $file_seeds_all $file_seeds
    fi

    # facciamo un po di pulizia
    rm $file_seeds_all".srt.unq"
    rm $file_seeds_oai
    rm $file_seeds_all
    if [[ -f $file_seeds_dup ]]; then
        rm $file_seeds_dup
    fi


} # end remove_duplicate_seeds



















# LOOKUP SEEDS (genera report di accesso a risorsa)
# [log].tsv:    object_id,
#               url della risorsa
#               codice HTML di ritorno (200 se ok)
#               mime type
function lookupSeeds()
{
    echo "--> LOOKUP SEEDS (concurrent jobs each in parallel)"
    # SAMPLE parallel --citation --colsep '\t' -j6 ./http_code {} {} :::: 02_seeds/unipi.seeds > 03_reports/unipi.tsv
    for filename in $seeds_dir/*.seeds; do
        (
        if [ -s "$filename" ]
        then
        	# echo "$filename has some data."
            # fname= basename $filename .seeds
            fname=$(basename -- "$filename")
            extension="${fname##*.}"
            fname="${fname%.*}"
            # echo "------>fname="$fname

echo "starting task on file $filename"
            command="parallel --colsep '\t' -j"$parallel_warc_jobs" ./http_code {} {} :::: "$filename
# echo "command="$command
            eval $command > "$check_seeds_dir/$fname.tsv"
            # break;
        else
        	echo "No seeds for $filename."
        fi
        ) &

    # allow only to execute $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -gt $N_LOOKUP_JOBS ]]; then
        # wait only for first job
        wait -n
    fi
    done

    # wait for pending jobs
    wait
    echo "lookupSeeds done with"

} # End lookupSeeds


# CHECK FOR BAD URLS (response != 200)
# Files with size > 0 have bad URLs
function checkForInvalidSeeds ()
{
    echo "CHECK FOR INVALID SEEDS"
    echo "======================="
    #grep -v "200" 03_reports/unipi.tsv > 04_bad_urls/unipi.bad.seeds
    for filename in $check_seeds_dir/*.tsv; do
        if [ -s "$filename" ]
        then
        	# echo "$filename has some data."
            # fname= basename $filename .seeds
            fname=$(basename -- "$filename")
            extension="${fname##*.}"
            fname="${fname%.*}"
            echo "------>fname="$fname
            command="grep -v 200 $filename"

#            eval $command > "$bad_seeds_dir/"$fname".bad.seeds"

            # quando c'e' un codice di errore c'e' sempre charset
            # url senza codici di errore (depositolegale.it) sembrando essere buone. Quindi non devono finire tra le url invalide
            eval $command | grep charset > "$bad_seeds_dir/"$fname".bad.seeds"


            seeds=$(cat $seeds_dir"/"$fname".seeds" | wc -l)
            seeds_checked=$(cat $filename | wc -l)

            if [ $seeds != $seeds_checked ]
            then
                echo "seeds="$seeds
                echo "seeds_checked="$seeds_checked



            fi

            # break;
        else
        	echo "$filename is empty."
                # do something as file is empty
        fi
    done
} # End checkForInvalidSeeds

function check_for_bad_seeds_lookup()
{
    echo "CHECK FOR BAD SEEDS LOOKUP"
    echo "=========================="
    for filename in $check_seeds_dir/*.tsv; do
        if [ -s "$filename" ]
        then
            fname=$(basename -- "$filename")
            extension="${fname##*.}"
            fname="${fname%.*}"
            # echo "-->fname="$fname

            seeds=$(cat $seeds_dir"/"$fname".seeds" | wc -l)
            seeds_checked=$(cat $filename | wc -l)

            if [ $seeds != $seeds_checked ]
            then
                # echo "seeds="$seeds
                # echo "seeds_checked="$seeds_checked
                echo "Bad seeds lookup for $fname. Seeds to lookup=$seeds, seeds LOKKED UP $seeds_checked"
            fi
        fi
    done

} # end check_for_bad_seeds_lookup



# STRIP BAD URLS from SEEDS
# -------------------------
function filterSeeds()
{
    echo "FILTER SEEDS"
    echo "============"
    for filename in $bad_seeds_dir/*.bad.seeds; do
        # echo "filename=$filename"

        fname=$(basename -- "$filename")
        # echo "fname=$fname"

        # extension="${fname##*.}"
        # echo "extention=$extention"


        # fname="${fname%.*}"
        fname="${fname%.*.*}"
        # echo "fname=$fname"


        if [ -s "$filename" ]
        then
        	# echo "$filename has some data."
            # fname= basename $filename .seeds
            echo "------>filter ./$seeds_dir/$fname.seeds"
            awk 'BEGIN{
                FS=" ";
                line=0;
                }

                FILENAME == ARGV[1] {
                    strip_AR[$1] = $1;
                    next;
                }

                {

                    if ($1 in strip_AR)
                        {
                        # print "skip "$2
                        next
                        }
                    else
                        print $0;
                    fi

                }'  $filename \
                    $seeds_dir/$fname.seeds \
                  > $validated_seeds_dir/$fname.seeds

            # break;
        else
            echo "Copy $seeds_dir/$fname.seeds to $validated_seeds_dir"
            cp $seeds_dir/$fname.seeds $validated_seeds_dir/.
        fi
    done
} # end filterSeeds


# Leave only few seeds for generating wards while developing
function trim_seeds()
{
    from=1
    to=$1
    echo "TRIM SEEDS"
    echo "=========="

    # for filename in $validated_seeds_dir/*.seeds; do
    for filename in $seeds_dir/*.seeds; do
        echo "filename=$filename"
        cmd="sed '"$from","$to"!d'"
        mv $filename $filename".all"

        eval $cmd $filename".all" > $filename
        #$trim_extension
    done

}







# CREATE WARCS
function create_warcs()
{
    echo "Create warcs (OBSOLETE). Use the parallel version"
    echo "================================================="
    exit
    # echo "change to $warcs_work_area_dir"
    # Durante la creazione dei warc vengono generate delle cartelle per scaricare i dati da gzippare nei warc.
    # Per questo motivo per non insozzare la cartella dei warcs eseguiamo l'elaborazione dentro un'area di lavoro

    # cd $warcs_work_area_dir
    #
    # if [ "$DEVELOPMENT" == "true" ]; then
    #     extension=$trim_extension
    # else
    #     extension=".seeds"
    # fi
    #
    # for filename in $validated_seeds_dir/*$extension; do
    #     echo "filename=$filename"
    #     fname=$(basename -- "$filename")
    #     fname="${fname%.*}"
    #     # echo "fname=$fname"
    #
    #     # filename="$validated_seeds_dir/unibg.seeds"
    #     # jobname=$(basename $filename .seeds)
    #     jobname=$fname
    #     # echo "jobname=$jobname"
    #
    #     # echo -n "pwd="
    #     # pwd
    #
    #     echo "--> Creazione warc per "$filename
    #
    #     # echo $harvest_date_materiale
    #     # echo "warc="$warcs_dir"/"$harvest_date_materiale"_"$jobname
    #
    #     ~/bin/wget-lua/bin/wget --user-agent='Wget/1.14.lua.20130523-9a5c - http://www.depositolegale.it' \
    #             --lua-script=$HARVEST_DIR/ojs.lua \
    #             --input-file=$filename \
    #             --page-requisites \
    #             --output-file=$warcs_dir"/"$jobname".log" \
    #             --warc-file=$warcs_dir"/"$jobname
    #
    # done
    # cd $HARVEST_DIR
} # end create_warcs



# PREPARE WARCS IN PARALLEL
function prepare_wget_sites_list()
{
    # redo=$1
    # redo_ctr=$redo_ctr
    # ctr=""

# echo "redo=$redo"
# echo "redo_ctr=$redo_ctr"

    echo "PREPARE WGET SITE LIST"
    echo "======================"
    # echo "change to $warcs_work_area_dir"
    # Durante la creazione dei warc vengono generate delle cartelle per scaricare i dati da gzippare nei warc.
    # Per questo motivo per non insozzare la cartella dei warcs eseguiamo l'elaborazione dentro un'area di lavoro

    # cd $warcs_work_area_dir


    # if [ "$redo" == "redo" ]; then
    #     echo "Let's REDO download for some urls"
    #     extension=".seeds"
    #     current_seeds_dir=$redo_seeds_dir
    #     ctr=$((redo_ctr-1))
    #     echo "ctr=$ctr"
    # else
        # echo "NO redo"
        # if [ "$DEVELOPMENT" == "true" ]; then
        #     extension=$trim_extension
        # else
            extension=".seeds"
        # fi

        # current_seeds_dir=$validated_seeds_dir
        current_seeds_dir=$seeds_dir
    # fi

# echo "current_seeds_dir=$current_seeds_dir"

    if [ -f $warcs_parallel_input_file ]
    then
        rm $warcs_parallel_input_file
    fi
    # touch $warcs_parallel_input_file


    # Prepare the commands to run
    # for filename in $current_seeds_dir/*$extension; do

    echo "Prepare $warcs_parallel_input_file"

    shopt -s nullglob
    # for filename in $current_seeds_dir/*$ctr$extension; do
    for filename in $current_seeds_dir/*$extension; do

        echo "filename=$filename"
        fname=$(basename -- "$filename")

        echo "$filename" >> $warcs_parallel_input_file

    done
    cd $HARVEST_DIR
} # end prepare_wget_sites_list


function check_free_disk()
{
    # echo "CHECK FREE DISK"
    # echo "==============="

    # space_available=$(($(stat -f --format="%a*%S" .) / 1024))
    # echo "space_available in kilobytes=$space_available"

    space_available=$(($(stat -f --format="%a*%S" .) / (1024*1024)))

    # space_available=$(($(stat -f --format="%a*%S" .) / (1024*1024*1024)))
    # echo "space_available in terabytes=$space_available"

    if [ $space_available -lt $WARC_FREE_DISC_REQUIRED_IN_MEGA ]; then
        echo "**********************************************************************"
        echo "RUN OUT OF DISK SPACE."
        echo "MAKE DISK SPACE AVAILABLE AND RESTART PROCEDURE"
        echo "space available in megabytes=$space_available"
        echo "Minimum space required in megabytes=$WARC_FREE_DISC_REQUIRED_IN_MEGA"
        echo "**********************************************************************"
        exit
    fi

}





function print_configuration ()
{
    echo
    echo "CONFIGURATION:"
    echo "--------------"

    if [ -z "$DEVELOPMENT" ]; then
        echo "**DEVELOPMENT:        NOT DELARED"
    else
        echo "**DEVELOPMENT:        $DEVELOPMENT"
    fi

    echo "  AMBIENTE:           -- $ambiente --"


    echo "  materiale:          $materiale"
    if [ -z "$harvest_from_override" ]; then
        if [ $materiale == $MATERIALE_EJOURNAL ]; then
            echo "  Harvest dates taken from file: $E_JOURNALS_LAST_HARVEST_DATE"
        else
            echo "  Harvest dates taken from file: $ETD_LAST_HARVEST_DATE"
        fi
    else
        echo "  Harvest from date:  $harvest_from_override"
    fi

    echo "  harvest to date:    "$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\1-\2-\3#g" )




    echo "  Repositories file:  $repositories_file"
    echo "  concurrent warc jobs: $concurrent_warc_jobs"
    echo "  Parallel warc jobs: $parallel_warc_jobs"

    if [ -z "$today_override" ]; then
        echo "  today:              $today"
    else
        echo "  today(overridden):  $today"
    fi

    echo "  yesterday:          $yesterday"




    if [ -z "$warc_block_size_override" ]; then
        echo "  warc_block_size:    $warc_block_size"
    else
        echo "  warc_block_size(overridden):  $warc_block_size_override"
    fi


    if [ -z "$start_from_block_override" ]; then
        echo "  start from block:    $start_from_block"
    else
        echo "  start from block (overridden):  $start_from_block_override"
    fi



    echo
    # echo "  wget-lua:           $WGET_LUA"
    echo "  Trim extension:     $trim_extension"
    echo "  Warcs parallel input file: $warcs_parallel_input_file"
    # echo "  HOME DIR:           $HOME_DIR"
    # echo "  MD DIR:             $MD_DIR"
    echo "  Wayback dir:        $WAYBACK_DIR"
    echo "  Harvest dir:        $HARVEST_DIR"
    # echo "  Skip repo for seeds file: $no_seeds_for_repositories_file;"
    echo "  Work dir:           $work_dir"
    echo "  metadata dir:       $metadata_dir"
    echo "  seeds_dir:          $seeds_dir"
    # echo "  check seeds dir:        $check_seeds_dir"
    # echo "  bad_seeds dir:      $bad_seeds_dir"
    # echo "  validated seeds dir: $validated_seeds_dir"
    echo "  warcs dir:           $warcs_dir"
    # echo "  warcs work area dir: $warcs_work_area_dir"
    # echo "  redo seeds dir:     $redo_seeds_dir"
    echo "  unimarc dir:         $unimarc_dir"
    echo "  receipts dir:         $receipts_dir"
    echo "  archived dir:         $archived_dir"
    echo "  nbn dir:         $nbn_dir"
    echo "  rights dir:         $rights_dir"

    echo "  report (receipts) dir: $report_dir"
    echo "  destination warcs dir: $dest_warcs_dir"

    # echo "   dir:           $"
    # echo "   dir:           $"
} # end print_configuration


function check_arguments()
{
    # Utente deve specificare il materiale (tesi/ej)
    if [ "$#" -lt 3 ]; then
        echo "ERRORE: argomenti mancanti (ambiente e materiale obbligatori)"
        echo "run.sh \
            -a--ambiente=sviluppo|collaudo|esercizio \
            -m=|--materiale=tesi|riviste \
            [-d|--development] \
            [-f=|--harvest_from_override=YYYY-MM-GG] \
            [-j=|--jobs=] \
            [-r=|--repositories_file=elenco_repos] \
            [-s=*|--start_from_block_override=*] \
            [-t=|--today_override=] \
            [-u=*|--warc_block_size_override=*]"
        exit
    fi

    # Loop through arguments and process them
    for arg in "$@"
    do
        case $arg in
            -m=*|--materiale=*)
            materiale="${arg#*=}"
            shift # Remove --materiale= from processing
            if [ "$materiale" != "tesi" ] && [ "$materiale" != "riviste" ]; then
                echo "Materiale invalido. Materiale puo' essere: tesi o riviste"
                exit
            fi
            if [ "$materiale" == "riviste" ]; then
                materiale="ej"
            fi
            ;;

            -a=*|--ambiente=*)
            ambiente="${arg#*=}"
            shift # Remove --materiale= from processing
            if [ "$ambiente" != "sviluppo" ] && [ "$ambiente" != "collaudo" ] && [ "$ambiente" != "esercizio" ]; then
                echo "Ambiente invalido. Ambiente puo' essere: sviluppo p collaudo o esercizio"
                exit
            fi
            ;;



            -d|--development)
            DEVELOPMENT="true"
            shift # Remove --development from processing
            ;;
            -f=*|--harrvest_from_override=*)
            harvest_from_override="${arg#*=}"
            shift # Remove --harrvest_from_override= from processing
            # check for date valid format
            d=$harvest_from_override
            if [ "`date '+%Y-%m-%d' -d $d 2>/dev/null`" != "$d" ]
            then
              echo "--harvest_from_override "$d is NOT a valid YYYY-MM-DD date
              exit
            fi
            ;;

            -j=*|--jobs=*)
            parallel_warc_jobs="${arg#*=}"
            shift # Remove --jobs= from processing
            if ! [ "$parallel_warc_jobs" -eq "$parallel_warc_jobs" ] 2> /dev/null
            then
                echo "parallel_warc_jobs '$parallel_warc_jobs' is not an integer"
                exit
            fi
            ;;

            -c=*|--concurrent_warc_jobs=*)
            concurrent_warc_jobs="${arg#*=}"
            shift # Remove --jobs= from processing
            if ! [ "$concurrent_warc_jobs" -eq "$concurrent_warc_jobs" ] 2> /dev/null
            then
                echo "concurrent_warc_jobs '$concurrent_warc_jobs' is not an integer"
                exit
            fi
            ;;



            -r=*|--repositories_file=*)
            repositories_file="${arg#*=}"
            shift # Remove --materiale= from processing
            ;;

            -s=*|--start_from_block_override=*)
            b="${arg#*=}"
            shift # Remove --harrvest_from_override= from processing
            # check for number
            if ! [[ "$b" =~ ^[0-9]+$ ]]; then
              echo "--start_from_block_override $b is NOT a number"
              exit
            else
              start_from_block_override=$b
            fi
            ;;

            -t=*|--today_override=*)
            # Usato quando vogliamo fare dei trattamenti su harvesting gia fatto oprecedentemente
            # e quindi non dover rifare l'harvesting
            d="${arg#*=}"
            shift # Remove --harrvest_from_override= from processing
            # check for date valid format
            if [[ $d =~ ^[0-9]{4}_[0-9]{2}_[0-9]{2}$ ]]; then
                today_override=$d
            else
              echo "--today_override "$d is NOT a valid YYYY_MM_DD date
              exit
            fi
            ;;

            -u=*|--warc_block_size_override=*)
            # Usato quando vogliamo fare dei trattamenti su harvesting gia fatto oprecedentemente
            # e quindi non dover rifare l'harvesting
            b="${arg#*=}"
            shift # Remove --harrvest_from_override= from processing
            # check for number
            if ! [[ "$b" =~ ^[0-9]+$ ]]; then
              echo "--block_size override $b is NOT a number"
              exit
            else
              warc_block_size_override=$b
            fi
            ;;

            *)
            OTHER_ARGUMENTS+=("$1")
            shift # Remove generic argument from processing
            ;;
        esac
    done


    if [ -z $ambiente ]; then
        echo "ambiente='"$ambiente"'"
        echo "Specificare l'ambiente di lavoro (sviluppo/collaudo/esercizio)"
        exit
    else
        # Check it against declared system environment variable
        if [ "$ambiente" != ${AMBIENTE_HARVEST} ]; then
            echo "Ambiente runtime  '$ambiente' diverso da ambiente di sistema '${AMBIENTE_HARVEST}'"
            exit
        fi
    fi
    if [ -z $materiale ]; then
        echo "materiale='"$materiale"'"
        echo "Specificare il materiale, tesi/riviste"
        exit
    fi



} # end check_arguments








# Using the : builtin, special parameters, pattern substitution and the echo
# builtin's -e option to translate hex codes into characters.
function urldecode()
{
    # echo "urldecode"
    # urls=$1
    # awk -niord '{printf RT?$0chr("0x"substr(RT,2)):$0}' RS=%.. <<< $urls
    : "${*//+/ }";
    echo -e "${_//%/\\x}";
}

# function urldecode()
# {
#     : "${*//+/ }";
#     echo -e "${_//%/\\x}";
# }


function generate_last_harvest_list()
{
    echo "GENERATE LAST HARVEST LIST"
    echo "=========================="

    # concatenate all timestamp files in metadata_dir
    echo "new_harvest_date_list=$new_harvest_date_list"
    cmd="cat $metadata_dir"/*.ts" > $metadata_dir"/"$new_harvest_date_list"
    eval $cmd
} # end generate_last_harvest_list



function check_for_restart()
{
    # Avevamo un proceduura interrotta (per problemi di spazio)?
    if [[ -f "$warcs_parallel_block_file" ]]; then
        echo "warcs_parallel_block_file: $warcs_parallel_block_file"
        read -p "
        ++++++++++++++++++++++++++++++++++++++++++++
        La procedura precedente era stata interrotta.
        Vuoi riprendere la generazione degi archivi warc.gz da dove si era interrotta? [yYnN]" -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            goto RESTART_WARCS
        else
            echo "Procedura interrotta!!!"
            echo "========================"
            exit
        fi
    fi

    # Stavamo riscaricando URL andate male nell'ultimo scarico?
#    if [ -f "$redo_ctr_file" ]; then
        # Restart per archiviare seed che hanno avuto problemi di connessione nella passata precedente!!
        # abbiamo qualche file nella redo seeds dir?
#        read -p "
#        ++++++++++++++++++++++++++++++++++++++++++++
#        La procedura precedente non ha completato correttamente tutti gli scarichi.
#        Vuoi riprovare a scaricare le URL andate male? [yYnN]" -n 1 -r
#        echo    # (optional) move to a new line
#        if [[ $REPLY =~ ^[Yy]$ ]]
#        then
#            goto REDO_WARCS
#        else
#            echo "Procedura interrotta!!!"
#            echo "========================"
#            exit
#        fi
#    fi

} # End check_for_restart

function count_all_seeds()
{
    echo "COUNT ALL SEEDS"
    echo "==============="


    if [ "$DEVELOPMENT" == "true" ]; then
        # echo "count trimmed"
        echo "$(wc -l $seeds_dir/*trimmed.seeds)" > $seeds_dir/"seeds_count.txt"
    else
        # echo "count NOT trimmed"
        echo "$(wc -l $seeds_dir/*.seeds)" > $seeds_dir/"seeds_count.txt"
    fi

} # End count_seeds




function check_unimarc_for_no_wayback_link()
{
    echo "CHECK UNIMARC FOR NO WAYBACK LINKS"
    echo "=================================="

    for filename in $unimarc_dir/*mrk; do
        # echo "filename: "$filename
        grep "WAYBACK" $filename
    done
}




function check_directories_existance()
{
    echo
    # echo "--> ENSURE SUBDIRECTORIES EXIST for $work_dir"

     for directory in ${directories[*]}
     do
         printf "   %s\n" $directory

         if [ ! -d "$directory" ]; then
           # Control will enter here if $DIRECTORY doesn't exist.
           echo "---> Create directory "$directory
           mkdir $directory
         fi
     done


     # Read trough the repositories_file to create report dir for site receipts
# echo "repositories_file="$repositories_file
     while IFS='|' read -r -a array line
     do
         # echo "$line"
         # echo "${array[0]}"
           line=${array[0]}
           # se riga comentata o vuota skip
           if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                 continue
            fi
         # site=${array[1]}
        site=$(echo "${array[1]}" | cut -f 1 -d '.')
# echo "site="$site
         site_dir=$report_dir"/"$site
         if [ ! -d $site_dir ]; then
             echo "---> Create directory $site_dir"
             mkdir $site_dir
         fi

     done < "$repositories_file"
} # end checkDirectoriesExistance

