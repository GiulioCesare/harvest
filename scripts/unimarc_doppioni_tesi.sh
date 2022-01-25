#!/bin/bash -e

# 19/01/2022
# Modulo per l'individuazione di tesi duplicate con diverso BID
# Richiesta Dr. Sperabene, BNCR




# File in ordine di creazione

declare -a tesi_mrk_AR=(
	"./tesi_2018_10_18_storico/09_unimarcs/db/2020_01_26_tesi_db.mrk" 
    "./tesi_2020_08_05/09_unimarcs/2020_08_05_tesi_all.mrk" 
    "./tesi_2021_01_19/09_unimarcs/2021_01_19_tesi_all.mrk"
    "./tesi_2021_09_23/09_unimarcs/2021_09_23_tesi_all.mrk"
    "./tesi_2022_01_09/09_unimarcs/2022_01_09_tesi_all.mrk"
    )








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


function elabora_mrk_all()
{
	echo "elabora_mrk_all"

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




	# echo "Order dups by TITLE/BID/HARVEST DATE"
 #    sort -T . -t\| -k 4 -k 2 -k 1 $unimarc_doppioni_dir"/tesi_all.dup" > $unimarc_doppioni_dir"/tesi_all.dup.TBH.srt"


	echo "Find out how many thesis are duplicate and each count"
	# uniq -f3 -c $unimarc_doppioni_dir"/tesi_all.dup" | sort -n -k 1 > $unimarc_doppioni_dir"/tesi_all.dup.unq.cnt"
	# Toppa: 22 2020_01_26|TD15024269|oai:elea.unisa.it:10556/1677|Salerno. Il Porto (sono 2 occorrenze e non 22)
	uniq -f3 -c $unimarc_doppioni_dir"/tesi_all.dup.TBH.srt" | sort -n -k 1 > $unimarc_doppioni_dir"/tesi_all.dup.TBH.srt.unq.cnt"
	

	echo "Get duplicate thesis count"
	uniq_dups=`cat $unimarc_doppioni_dir"/tesi_all.dup.TBH.srt.unq.cnt" | wc -l`
	echo "Dupulicate thesis are: " $uniq_dups




} # end elabora_mrk_all



function elabora_doppioni_tesi()
{
	echo "elabora_doppioni_tesi"
	elabora_mrk_all

} # end elabora_doppioni_tesi

