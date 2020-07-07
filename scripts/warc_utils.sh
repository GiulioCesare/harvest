#!/bin/sh








function create_warcs_concurrently()
{
    echo "CREATE WARCS CONCURRENTLY"
    echo "========================="
    # cd $warcs_work_area_dir
    cd $warcs_dir

    echo "Physical destination warcs dir: "$dest_warcs_dir
    echo "Running $concurrent_warc_jobs CONCURRENT warc jobs for $warcs_parallel_input_file"

        while IFS= read -r seeds_filename
            do
            (
                ((line_ctr++))

                if [[ ${seeds_filename:0:1} == "#" ]] || [[ ${seeds_filename} == "" ]];  then
                    # echo "continue"
                      continue
                fi


               # echo "line_ctr= $line_ctr"
               check_free_disk

               # cd $warcs_work_area_dir

               local fname=$(basename -- "$seeds_filename")
               # local fname="${fname%.*}"


               # if [ "$DEVELOPMENT" == "true" ]; then
               #     local fname="${fname%.*.*}"
               # else
                   local fname="${fname%.*}"
               # fi

echo "fname=$fname"

echo "wget_ting $seeds_filename"

               # Option --delete-after instructs wget to delete each downloaded file immediately after its download is complete.
               # Option --no-directories prevents wget from leaving behind a useless tree of empty directories.
               #  Certe opzioni sembrano essere ignorate: eg. --no-directories --no-warc-keep-log
               wget_options="--warc-tempdir=. --delete-after --no-directories --no-warc-keep-log --no-check-certificate --user-agent='bncf' --page-requisites"



                # DEBUG
               # wget_options="--warc-tempdir=. --no-warc-keep-log --no-check-certificate --user-agent='bncf' --page-requisites"
# pwd
 # echo "wget $wget_options --input-file=$seeds_filename --output-file=./$fname.log --warc-file=./$fname"
                # if  [[ $fname == *unicatt ]] ; # se finisce in unicatt
                # then
                # SEMBRA FUNZIONARE anche solo con controllo indirizzo IP
                #     echo "ACCESSO controllato a pagine dietro login di UNICATT"
                #
                #     echo "Login. Per prendere la sessione utente"
                #     wget --save-cookies cookies.txt --keep-session-cookies --delete-after --post-data 'user=appsrv.docta.ssows&password=kMcydyT3QhqMhlQE4O1m!' https://login.unicatt.it/iam-fe/sso/login
                #
                #     echo "Accesso a pagina di una tesi. Altrimenti non funziona"
                #     wget -qO- --load-cookies ./cookies.txt http://hdl.handle.net/10280/296 &> /dev/null
                #
                #     # 20/02/2020 Depositiamo direttamente il warc file nella cartella dei warc della wayback machine
                #
                #     wget $wget_options --load-cookies ./cookies.txt --input-file=$seeds_filename --output-file=./$fname.log --warc-file=$dest_warcs_dir/$fname
                # fi

                # 20/02/2020 Depositiamo direttamente il warc file nella cartella dei warc della wayback machine
                # wget $wget_options --input-file=$seeds_filename --output-file=./$fname.log --warc-file=$dest_warcs_dir/$fname

                if [ $materiale == $MATERIALE_EJOURNAL ]; then
                    wget_options="${wget_options} --lua-script=$HARVEST_DIR/ojs.lua"
                fi

# echo "wget_options="$wget_options

                wget $wget_options --input-file=$seeds_filename --output-file=./$fname.log --warc-file=$warcs_dir/$fname

               ) &
               # allow only to execute $N jobs in parallel
               if [[ $(jobs -r -p | wc -l) -gt $concurrent_warc_jobs ]]; then
                   # wait only for first job
                   wait -n
               fi

            done < "$warcs_parallel_input_file"

            # wait for pending jobs
            wait


cd $HARVEST_DIR

} # end create_warcs_concurrently

function printarr()
{
    # echo "printarr"
    declare -n __p="$1";
    for k in "${!__p[@]}"; do
        printf "%s=%s\n" "$k" "${__p[$k]}"
    done
    # echo "end printarr"
} # End printarr

function check_for_harvest_mismatch()
{
    echo "CHECK FOR HARVEST MISMATCH"
    echo "=========================="

    mismatch=0;

    # for seeds_to_harvest_filename in $seeds_dir/*.seeds
    for log_filename in $warcs_dir/logs1/*.log
    do
        fname=$(basename -- "$log_filename")
        fname="${fname%.*}"

# echo "fname="$fname
        seeds_to_harvest_filename=$seeds_dir/$fname.seeds
        # echo "seeds_to_harvest_filename="$seeds_to_harvest_filename
# continue
        echo "$seeds_to_harvest_filename"
        seeds_to_harvest=$(cat $seeds_to_harvest_filename | wc -l)
        seeds_in_warc=0
        seeds_not_in_warc=0
        #  Contiamo i seed scaricati
        siw=$warcs_dir/logs1/$fname.log.seeds_in_warc
        if [[ -f $siw ]]; then
            seeds_in_warc=$(cat $siw | wc -l)
        fi
        sniw=$warcs_dir/logs1/$fname.log.seeds_not_in_warc
        if [[ -f $sniw ]]; then
            seeds_not_in_warc=$(cat $sniw | wc -l)
        fi
        tot_seeds_from_wget=$((seeds_in_warc + seeds_not_in_warc))
        if [[ "$seeds_to_harvest" -gt "$tot_seeds_from_wget" ]]; then
            echo "$seeds_to_harvest seeds to harvest in $seeds_to_harvest_filename"
            echo "$tot_seeds_from_wget seed harvested in $seeds_to_harvest_filename (see .missing)"
            let "mismatch=mismatch+1"
        fi
    done

    if [[ $mismatch < 1 ]]; then
        echo "GREAT!!! Nessun miscmath tra URL(seed) da scaricare e scaricate"
    else
        echo "CHECK!!! $mismatch siti miscmath tra URL(seed) da scaricare e scaricate"
    fi
} # end check_for_harvest_mismatch



function check_for_missing_seeds()
{
    echo "CHECK FOR MISSING SEEDS (.missing)"
    echo "=================================="

    # for seeds_to_harvest_filename in $seeds_dir/*.seeds
    for log_filename in $warcs_dir/logs1/*.log
    do
        fname=$(basename -- "$log_filename")
        fname="${fname%.*}"

# echo "fname="$fname
        seeds_to_harvest_filename=$seeds_dir/$fname.seeds
        echo "seeds_to_harvest_filename="$seeds_to_harvest_filename
# continue
        # -s FILE - True if the FILE exists and has nonzero size.
        if [[ ! -s $seeds_to_harvest_filename ]]; then
            echo "empty file"
            continue
        fi

        if [ -f $warcs_dir/logs1/$fname.seeds.missing ]; then
            rm $warcs_dir/logs1/$fname.seeds.missing
        fi

        declare -A seeds_scaricati_e_non_kv_AR

        # carichiamo i seed finiti nel warc
        siw=$warcs_dir/logs1/$fname.log.seeds_in_warc
        if [[ -f $siw ]]; then
# echo "reading $warcs_dir/logs1/$fname.log.seeds_in_warc"
            while IFS='|' read -r  line
            do
                tmp=$(sed 's\.*//\\ g' <<<"$line")
                tmp2=${tmp//\+/ }
                url=$(urldecode "$tmp2")
# echo "--->url = $url"
                seeds_scaricati_e_non_kv_AR[$url]="dummy value"
            done < $siw
        fi
# return
        # mettiamo i seed non scaricati nel warc
        sniw=$warcs_dir"/logs1/"$fname".log.seeds_not_in_warc"
        if [ -s $sniw ]; then
# echo "reading $warcs_dir/logs1/$fname.log.seeds_not_in_warc"
            while IFS='|' read -r  line
            do
                [ -z "$line" ] && continue  # test empty line
    # echo "line=$line"
                tmp=$(sed 's\.*//\\ g' <<<"$line")
                tmp2=${tmp//\+/ }
                url=$(urldecode "$tmp2")
    # echo "--->url = $url"
                seeds_scaricati_e_non_kv_AR[$url]="dummy value"
            done < $sniw
        fi

# printarr seeds_scaricati_e_non_kv_AR
# return

        # Troviamo i seeds da scaricare non intercettati
        if [[ -f $warcs_dir/logs1/$fname.log.seeds.missing ]]; then
# echo "Removing $warcs_dir/logs1/$fname.log.seeds.missing"
            rm $warcs_dir/logs1/$fname.log.seeds.missing
        fi
# echo "Troviamo i seeds da scaricare non intercettati"
        while IFS= read -r line
            do
    # echo "===>$line"
                tmp=$(sed 's\.*//\\ g' <<<"$line")
                tmp2=$(urldecode "$tmp")
                tmp3=$(urldecode "$tmp2")
                url=${tmp3//\+/ }

    # echo "test --->url=$url"
                if ! test "${seeds_scaricati_e_non_kv_AR[$url]+isset}"
                then
                    echo "$url" >> $warcs_dir/logs1/$fname.log.seeds.missing
                fi
                # break;
        done < $seeds_to_harvest_filename
    done
} # end _check_for_missing_seeds








# su imtlucca ho avuto un abbattimento dell'indice del 94%
function clean_wayback_index ()
{
    echo "CLEAN WAYBACK INDEX"
    echo "==================="

    # Remove all noise links. eg links to images, javascript, stylesheet, etc.
    # awk '!/\.gif|\.js|\.png|\.css|\.ico|password\-login|robots.txt/' $WAYBACK_INDEX_DIR"/index.cdxj"  > $WAYBACK_INDEX_DIR"/index.cdxj.clean"

    # In bash, you can set the nullglob option so that a pattern that matches nothing "disappears",
    # rather than treated as a literal string
#    shopt -s nullglob
    for filename in $WAYBACK_INDEX_DIR/*cdxj; do
        cd $WAYBACK_INDEX_DIR
        echo "filename="$filename

        # 27/01/2020
        # Remove all noise links. eg links to images, javascript, stylesheet, etc.
        echo "--> cleaning $filename"
        awk '!/\.gif|\.js|\.png|\.css|\.ico|password\-login|robots.txt/' $filename  > $filename.clean

    done
    cd $HARVEST_DIR

} # end clean_wayback_index


function get_indexes_for_compression ()
{
    echo "--> Prendiamo i nuovi indici (cdxj)"
    cd $INDEX_COMPRESSION_DIR

    echo "Copy index file in index directory 'cdx'"
    cp $WAYBACK_INDEX_DIR/*.cdxj "cdx/."

    cd $HARVEST_DIR
}



function compress_warc_indexes ()
{
	completo=$1

    echo "--> Compressione degli indici"
    echo "INDEX_COMPRESSION_DIR: "$INDEX_COMPRESSION_DIR
    cd $INDEX_COMPRESSION_DIR

	if [ $completo == "1" ]; then
		echo "Getting embargoed indexes"
		cp cdx_embargo/*.cdxj cdx/.
	else
		echo "Removing embargoed indexes"
		rm cdx/*embargo*
	fi


    echo "Pulisco la cartella './zipnum'"
    rm ./zipnum/*

    echo "Creo indici compressi in 'zipnum'"
    python build_local_zipnum.py -p ./zipnum/ ./cdx

	# Siccome non ci deve stare zipnum/ lo dobbiamo rimuovere dal file ./zipnum/cluster.loc
	# cdx-00000.gz    ./zipnum/cdx-00000.gz

	echo "Clean ./zipnum/cluster.loc"
	sed -i 's/\.\/zipnum/\./g' ./zipnum/cluster.loc

    cd $HARVEST_DIR
}



function replace_warc_indexes_with_compressed_ones_in_memoria()
{
	echo ""
    echo "--> Sostituisco i vecchi indici (compressi e non) con i nuovi indici compressi per collezione 'memoria.depositolegale.it'"
    cd $INDEX_COMPRESSION_DIR

    if [ ! -d $WAYBACK_INDEX_DIR"/tmp" ]; then
      echo "---> Create directory "$WAYBACK_INDEX_DIR"/tmp"
      mkdir $WAYBACK_INDEX_DIR"/tmp"
	fi



	echo "Sposto gli indici vecchi in "$WAYBACK_INDEX_DIR"/tmp"
    mv $WAYBACK_INDEX_DIR/*.gz $WAYBACK_INDEX_DIR"/tmp"
    mv $WAYBACK_INDEX_DIR/*.loc $WAYBACK_INDEX_DIR"/tmp"
    mv $WAYBACK_INDEX_DIR/*.summary $WAYBACK_INDEX_DIR"/tmp"
    mv $WAYBACK_INDEX_DIR/part-* $WAYBACK_INDEX_DIR"/tmp"
    mv $WAYBACK_INDEX_DIR/*cdxj* $WAYBACK_INDEX_DIR"/tmp"


	echo "Copio i nuovi indici compressi in "$WAYBACK_INDEX_DIR
    cp ./zipnum/* $WAYBACK_INDEX_DIR/.

    cd $HARVEST_DIR
}

function replace_warc_indexes_with_compressed_ones_in_index()
{
	echo ""
    echo "--> Sostituisco i vecchi indici (compressi e non) con i nuovi indici compressi per collezione 'index'"
    cd $INDEX_COMPRESSION_DIR



INDEX_INDEX_DIR=$WAYBACK_HOME_DIR"/index/collections/index/indexes"
echo "INDEX_INDEX_DIR="$INDEX_INDEX_DIR


    if [ ! -d $INDEX_INDEX_DIR"/tmp" ]; then
      echo "---> Create directory "$INDEX_INDEX_DIR"/tmp"
      mkdir $INDEX_INDEX_DIR"/tmp"
	fi

	echo "Sposto gli indici vecchi in "$INDEX_INDEX_DIR"/tmp"
    mv $INDEX_INDEX_DIR/*.gz $INDEX_INDEX_DIR"/tmp"
    mv $INDEX_INDEX_DIR/*.loc $INDEX_INDEX_DIR"/tmp"
    mv $INDEX_INDEX_DIR/*.summary $INDEX_INDEX_DIR"/tmp"
    mv $INDEX_INDEX_DIR/part-* $INDEX_INDEX_DIR"/tmp"
    mv $INDEX_INDEX_DIR/*cdxj* $INDEX_INDEX_DIR"/tmp"


	echo "Copio i nuovi indici compressi in "$INDEX_INDEX_DIR
    cp ./zipnum/* $INDEX_INDEX_DIR/.

    cd $HARVEST_DIR
}





function create_warcs_sequencially()
{
    echo "CREATE WARCS SEQUENCIALLY"
    echo "========================="
    # cd $warcs_work_area_dir
    cd $warcs_dir

    echo "Physical destination warcs dir: "$dest_warcs_dir
    # echo "Running $concurrent_warc_jobs CONCURRENT warc jobs for $warcs_parallel_input_file"

        while IFS= read -r seeds_filename
            do
            (
                ((line_ctr++))

                if [[ ${seeds_filename:0:1} == "#" ]] || [[ ${seeds_filename} == "" ]];  then
                    # echo "continue"
                      continue
                fi


               # echo "line_ctr= $line_ctr"
               check_free_disk

               # cd $warcs_work_area_dir

               local fname=$(basename -- "$seeds_filename")
               # local fname="${fname%.*}"


               # if [ "$DEVELOPMENT" == "true" ]; then
               #     local fname="${fname%.*.*}"
               # else
                   local fname="${fname%.*}"
               # fi

# echo "fname=$fname"

echo "wget_ting $seeds_filename"

               # Option --delete-after instructs wget to delete each downloaded file immediately after its download is complete.
               # Option --no-directories prevents wget from leaving behind a useless tree of empty directories.
               #  Certe opzioni sembrano essere ignorate: eg. --no-directories --no-warc-keep-log
               wget_options="--warc-tempdir=. --delete-after --no-directories --no-warc-keep-log --no-check-certificate --user-agent='bncf' --page-requisites"

                # DEBUG
               # wget_options="--warc-tempdir=. --no-warc-keep-log --no-check-certificate --user-agent='bncf' --page-requisites"
# pwd
 # echo "wget $wget_options --input-file=$seeds_filename --output-file=./$fname.log --warc-file=./$fname"
                # if  [[ $fname == *unicatt ]] ; # se finisce in unicatt
                # then
                # SEMBRA FUNZIONARE anche solo con controllo indirizzo IP
                #     echo "ACCESSO controllato a pagine dietro login di UNICATT"
                #
                #     echo "Login. Per prendere la sessione utente"
                #     wget --save-cookies cookies.txt --keep-session-cookies --delete-after --post-data 'user=appsrv.docta.ssows&password=kMcydyT3QhqMhlQE4O1m!' https://login.unicatt.it/iam-fe/sso/login
                #
                #     echo "Accesso a pagina di una tesi. Altrimenti non funziona"
                #     wget -qO- --load-cookies ./cookies.txt http://hdl.handle.net/10280/296 &> /dev/null
                #
                #     # 20/02/2020 Depositiamo direttamente il warc file nella cartella dei warc della wayback machine
                #
                #     wget $wget_options --load-cookies ./cookies.txt --input-file=$seeds_filename --output-file=./$fname.log --warc-file=$dest_warcs_dir/$fname
                # fi

                # 20/02/2020 Depositiamo direttamente il warc file nella cartella dei warc della wayback machine

                # Gestito in fase di estrazione SEEDS if [ $materiale == $MATERIALE_EJOURNAL ]; then
                #     wget_options="${wget_options} --lua-script=$HARVEST_DIR/ojs.lua"
                # fi

# echo "wget_options="$wget_options
                wget $wget_options --input-file=$seeds_filename --output-file=./$fname.log --warc-file=$dest_warcs_dir/$fname
               )
            done < "$warcs_parallel_input_file"

cd $HARVEST_DIR

} # end create_warcs_sequencially

#
# wb-manager is a command line tool for managing common collection operations.
#     positional arguments:
#       {init,list,add,reindex,index,metadata,template,cdx-convert,autoindex}
#         init                Init new collection, create all collection directories
#         list                List Collections
#         add                 Copy ARCS/WARCS to collection directory and reindex
#         reindex             Re-Index entire collection
#         index               Index specified ARC/WARC files in the collection
#         metadata            Set Metadata
#         template            Add default html template for customization
#         cdx-convert         Convert any existing archive indexes to new json format
#         autoindex           Automatically index any change archive files
#
#     optional arguments:
#       -h, --help            show this help message and exit
#
#   - inizializzazione di una collezione chiamata my-web-archive
#      - wb-manager init web-archive
#      - wb-manager reindex collections/web-archive
#
#   wayback   - starts a web server that provides the access to web archives (dalla cartella dove stanno le collezioni).

function index_warcs()
{
    echo "--> INDICIZZA WARCS IN WAYBACK $dest_warcs_dir"

    # Rimozione di index.cdxj
    printf "\n-> Rimuovo vecchio indice: "$WAYBACK_INDEX_DIR"/index.cdxj\n\n"
    if [[ -f $WAYBACK_INDEX_DIR"/index.cdxj" ]]; then
        rm $WAYBACK_INDEX_DIR"/index.cdxj"
    fi

    # echo "Creiamo la lista da trattare"
    # ls -1rt $dest_warcs_dir/*warc.gz > $dest_warcs_dir"/warcs.lst"
# return

  	  cd $WAYBACK_DIR
  while IFS= read -r line
    do
        # echo "$line"
        # se riga comentata o vuota skip
        if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
            continue
        fi
 	      tmp=${line%.*.*}
		  istituto=$(basename -- "$tmp")
         # echo "istituto: $istituto"

        # filename=$dest_warcs_dir"/"$line
        echo "--> indexing $line"
# pwd
        $WB_MANAGER_DIR"wb-manager" index $WAYBACK_COLLECTION_NAME $line

	echo "Rinominiamo " $WAYBACK_INDEX_DIR"/index.cdxj in" $WAYBACK_INDEX_DIR"/"$istituto".cdxj"
	mv $WAYBACK_INDEX_DIR"/index.cdxj" $WAYBACK_INDEX_DIR"/"$istituto".cdxj"

    done < $dest_warcs_dir"/warcs.lst"



    cd $HARVEST_DIR
} # end index_warcs



function copy_warcs_and_logs_to_destination_dir_and_remove()
{
    # echo "copy_warcs_to_destination_dir: "$dest_warcs_dir
    echo ""
    echo "COPY and REMOVE"
    echo "  '.warc.gz' files"
    echo "    from $warcs_dir"
    echo "    to   $dest_warcs_dir"
    echo "  '.log' files"
    echo "    from $warcs_dir"
    echo "    to   $warcs_dir/log"


    shopt -s nullglob
    for warc_filename in $warcs_dir/*.gz
    do
# echo "warc_filename="$warc_filename
        basename=$(basename -- "$warc_filename")
# echo "basename="$basename
        fname="${basename%%.*}" # elimina .warc.gz
echo "fname="$fname

        # Copiamo il warc
# echo "Copying $basename"
        cp $warc_filename $dest_warcs_dir/.

        if [ $? -ne 0 ]; then
            echo "ERROR: while copying warc file"
        else
# echo "Removing "$basename
            rm $warc_filename

            # Copiamo il log file del warc
# echo "Copying "$fname".log"
            cp $warcs_dir/$fname".log" $warcs_dir"/log/."
            if [ $? -ne 0 ]; then
                echo "ERROR: while copying log file"
            else
# echo "Removing "$fname".log"
                rm $warcs_dir/$fname".log"
            fi

        fi
    done
} # end copy_warcs_and_logs_to_destination_dir_and_remove


function make_dest_warcs_read_write()
{
    echo "make_dest_warcs_read_write: "$dest_warcs_dir
    chmod 666 $dest_warcs_dir/*gz
}

function make_dest_warcs_read_only()
{
    echo "make_dest_warcs_read_only: "$dest_warcs_dir
    chmod 444 $dest_warcs_dir/*gz
}
