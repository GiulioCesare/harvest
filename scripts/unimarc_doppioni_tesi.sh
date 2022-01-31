#!/bin/bash -e

# 19/01/2022
# Modulo per l'individuazione di tesi duplicate con diverso BID
# Richiesta Dr. Sperabene, BNCR

# =================================================================================
# ALGORITMO:
# - Troviamo i doppioni nui file unimarc per ogni istituzione di ogni harvest fatto in base al titolo e autore e produciamo un file che contenga:
#     - la data dell'harvest 
#     - il BID generato da procedura di harvest
#     - l'OAI identifier presente nei metadati 
#     - il titolo della tesi
#     - l'auore della tesi
# 
# - Mettiamo tutti i doppioni trovati in un unico file
# 
# - Produciamo la lista dei BID di tutte le tesi cancellate indicate nei metadati
# 
# - Rimuoviamo dalla lista dei doppioni eventuali tesi cancellate
# 
# - Ordiniamo i duplicati per
#     - Titolo
#     - Autore
#     - BID
#     - Ddata di harvest
# 
# - Facciamo la conta delle rtipetizioni per ogni tesi dupplicata e produciamo una lista che contiene le tesi univoche ed il contatore delle ripetizioni
#     - Numero di occorrenze
#     - la data dell'harvest 
#     - un BID generato da procedura di harvest
#     - un OAI identifier presente nei metadati 
#     - il titolo della tesi
#     - l'auore della tesi
# 
# - Produrre una lista per ogni istituzione con l'elenco dei duplicati
#     Questa lista va inviata alla istituzione perche' proceda alla bonifica.
# 
# - All'harvest successivo le tesi duplicate cancellate verranno rimosse dall'Opac
# 
# =================================================================================
# Impegno 7 GG ca per tesi uguali




# File in ordine di creazione
declare -a tesi_mrk_AR=(
	"./tesi_2018_10_18_storico/09_unimarcs/db/2020_01_26_tesi_db.mrk" 
    "./tesi_2020_08_05/09_unimarcs/2020_08_05_tesi_all.mrk" 
    "./tesi_2021_01_19/09_unimarcs/2021_01_19_tesi_all.mrk"
    "./tesi_2021_09_23/09_unimarcs/2021_09_23_tesi_all.mrk"
    "./tesi_2022_01_09/09_unimarcs/2022_01_09_tesi_all.mrk"
    )

# Elenchi dei BID cancellati
declare -a tesi_del_file_AR=(
    "./tesi_2020_08_05/09_unimarcs/2020_08_05_tesi_oai_bid_deleted.all" 
    "./tesi_2021_01_19/09_unimarcs/2021_01_19_tesi_oai_bid_deleted.all"
    "./tesi_2021_09_23/09_unimarcs/2021_09_23_tesi_oai_bid_deleted.all"
    "./tesi_2022_01_09/09_unimarcs/2022_01_09_tesi_oai_bid_deleted.all"
    )

declare -a tesi_del_record_AR


function extract_mkr_duplicates()
{
	echo "extract_mkr_duplicates"
	mrk_filename=$1;

	fname=$(basename -- "$mrk_filename")

	harvest_date=${fname:0:10}


	echo "--> mrk_filename=$mrk_filename"
	echo "--> fname=$fname"
	# grep "^=001" $mrk_filename > $unimarc_doppioni_dir"/"$fname".001"
	# grep "^=200" $mrk_filename > $unimarc_doppioni_dir"/"$fname".200"

# deleted record
# 38649 =LDR  -0001dam  22----- n 450 
# 38650 =001  TD17050052
# 38651 =017  80$aoai:iris.univr.it:11562/960771

awk_command='
    BEGIN{
    	FS="$"; 
    	last_tesi=""
    	flag=""
    }
    
    
    {
    # If line commented or empty
    # if ($1 ~ "#"  || $1 == "")
    #     next


	if ($0 ~ /^=LDR  -0001/)
		{
		flag=substr($0, 12, 1)

		# print flag

    	if (last_tesi != "")
	    	{
    		print last_tesi
    		last_tesi = ""
	    	}
		}

	if (flag == "d")
	{
		# print "DELETED";
		next;
	}

    if ($0 ~ /^=001/)
        {
        	# BID
        	last_tesi=harvest_date"|"substr($0, 7, 10)
        }

    # if ($0 ~ /^=017  80$aoai/)
    if ($0 ~ /^=017  80\$aoai/)
        {
        	# print $0
        	# OAI ID
        	last_tesi=last_tesi"|"substr($2, 2)
        }

    if ($0 ~ /^=200/)
        {
        	last_tesi=last_tesi"|"substr($2, 2)
        }

    if ($0 ~ /^=700/)
        {
        	
        	last_tesi=last_tesi"|"substr($2, 2)
        }
    }
    
    END {
        		print last_tesi
        } '

    echo " - Estrai le informazioni per individuare i duplicati"
    awk -v harvest_date=$harvest_date "$awk_command"  $mrk_filename > $unimarc_doppioni_dir"/"$fname".txt"

    echo " -  Sort by title"
    sort -T . -t\| -k 4 $unimarc_doppioni_dir"/"$fname".txt" > $unimarc_doppioni_dir"/"$fname".txt.srt"

    echo " - Get duplicate titles on 4th and 5th field"
	awk -F \| '{if (x[$4$5]) { y[$4$5]++; print $0; if (y[$4$5] == 1) { print x[$4$5] } } x[$4$5] = $0}'  $unimarc_doppioni_dir"/"$fname".txt.srt" > $unimarc_doppioni_dir"/"$fname".txt.srt.dup"

} # end extract_mkr_duplicates


function upload_deleted_records ()
{
	# echo "upload deleted records from harvests"
	for delfile in "${tesi_del_file_AR[@]}"
	do
	   echo " --> upload deleted records from: $delfile"
	

awk_command='
    BEGIN{FS="|"; }
    {

	tesi_del_record_AR[$2]=$0
	# print $2

    }
    END{

	# for (key in tesi_del_record_AR) 
	# 	{ 
	# 		print tesi_del_record_AR[key] 
	# 	}

    }

    '

    awk "$awk_command"  $delfile
	done

} # end upload_deleted_records


function elabora_mrk_all()
{
	echo "elabora_mrk_all"

	upload_deleted_records



	# echo "Get duplicates from each unimarc mrk file"
	# for mrkfile in "${tesi_mrk_AR[@]}"
	# do
	#    echo " --> mrkfile: $mrkfile"
	# 	extract_mkr_duplicates $mrkfile   
	# done


	# echo "--> Put all the duplicates together"

 #    if [ -f $unimarc_doppioni_dir"/tesi_all.dup" ]; then
 #    	echo "remove tesi_all.dup"
 #        rm $unimarc_doppioni_dir"/tesi_all.dup"
 #    fi

	# for mrkfile in "${tesi_mrk_AR[@]}"
	# do
	#    	echo "  $mrkfile"
	# 	fname=$(basename -- "$mrkfile")
	# 	cat $unimarc_doppioni_dir"/"$fname".txt.srt.dup" >> $unimarc_doppioni_dir"/tesi_all.dup"
	# done

# Remove deleted thesis (if any)
awk_command='
    BEGIN{FS="|"; }
    {
    # If line commented or empty
    if ($1 ~ "#"  || $1 == "")
        next

    if ($2 in tesi_del_file_AR)
        {
         print "Rimuovi "$2" dai doppioni"
         # TODO 
        }

    fi
    }'

    awk "$awk_command"  $unimarc_doppioni_dir"/tesi_all.dup"




	# echo "Order dups by TITLE/AUTHOR/BID/HARVEST DATE"
 #    sort -T . -t\| -k 4 -k5 -k 2 -k 1 $unimarc_doppioni_dir"/tesi_all.dup" > $unimarc_doppioni_dir"/tesi_all.dup.TABH.srt"


	# echo "Find out how many thesis are duplicate and each count"
	# uniq -f3 -c $unimarc_doppioni_dir"/tesi_all.dup.TABH.srt" | sort -n -k 1 > $unimarc_doppioni_dir"/tesi_all.dup.TABH.srt.unq.cnt"
	# echo "Get duplicate thesis count"
	# uniq_dups=`cat $unimarc_doppioni_dir"/tesi_all.dup.TABH.srt.unq.cnt" | wc -l`
	# echo "Dupulicate thesis are: " $uniq_dups

} # end elabora_mrk_all



function elabora_doppioni_tesi()
{
	echo "elabora_doppioni_tesi"
	elabora_mrk_all

} # end elabora_doppioni_tesi

