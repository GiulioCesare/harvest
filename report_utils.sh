#!/bin/sh

declare -A http_error_kv_AR
declare -A meta_dati_ricevute_kv_AR
declare -A seeds_in_warc_kv_AR
declare -A seeds_not_in_warc_kv_AR


function make_report()
{
echo "MAKE REPORT"
echo "==========="

fileCsv=$LOGS_DIR"/"$harvest_date"_harvest_report.csv"


data=${harvest_date:8}"/"${harvest_date:5:2}"/"${harvest_date:0:4}
echo "HARVESTING TESI DI DOTTORATO DEL "$data > $fileCsv
echo "" >> $fileCsv

echo "LEGENDA" >> $fileCsv
echo "Sito|Istituto dal quale si fa l'harvesting" >> $fileCsv
echo "OAI record|Un record per tesi esposta tramite OAI" >> $fileCsv
echo "Tesi senza documenti|Tesi (pagina descrittiva) senza documenti allegati (pdf, doc, altro)" >> $fileCsv
echo "Documenti da acquisire|URL da scaricare" >> $fileCsv
echo "Documenti non acquisiti|URL per le quali non e' stato possibile scaricare" >> $fileCsv
echo "Documenti acquisiti|URL scaricate (+ file accessori eg. .jpg)" >> $fileCsv
echo "" >> $fileCsv

siti_harvestati=$(ls -l $warcs_dir/logs1/*".log" | wc -l)
echo "Numero di siti da trattare|"$siti_harvestati >> $fileCsv

siti_con_seed=0
siti_senza_seed=0
for filename in $warcs_dir/logs1/*.log; do
    fname=$(basename -- "$filename")
    fname="${fname%.*}"
    if [[ -s $seeds_dir/$fname".seeds" ]]; then
      let siti_con_seed=siti_con_seed+1
  else
      let siti_senza_seed=siti_senza_seed+1
    fi
done
echo "Numero di siti con risorse didl|"$siti_con_seed >> $fileCsv
echo "Numero di siti senza alcuna risorsa didl|"$siti_senza_seed >> $fileCsv


siti_senza_seed=$(ls $warcs_dir/logs1/*".log.seeds_not_in_warc" 2> /dev/null | wc -l)
echo "Numero di siti con URL non acquisite|"$siti_senza_seed >> $fileCsv

siti_missing=$(ls $warcs_dir/logs1/*.missing 2> /dev/null | wc -l)
echo "Numero di siti con URL non conformi |"$siti_missing >> $fileCsv

siti_con_doppioni=$(ls $seeds_dir/*".seeds_dup.csv" 2> /dev/null | wc -l)
echo "Numero di siti con URL non univoche |"$siti_con_doppioni >> $fileCsv

siti_senza_didl_resource=$(ls $receipts_dir/*".no_didl_resource" 2> /dev/null | wc -l)
echo "Numero di siti con risorse didl mancanti|"$siti_senza_didl_resource >> $fileCsv


echo "" >> $fileCsv



echo "SITO|Tesi|Tesi senza documenti|Documenti da acquisire|Documenti acquisiti|Documenti non acquisiti|Documenti non acquisiti perche' duplicati|Da controllare" >> $fileCsv

    tot_oai_records=0
    tot_oai_records_senza_didl=0
    tot_didl_resources_to_download=0
    tot_didl_resources_non_in_warc=0
    tot_didl_resources_in_warc=0

    tot_url_non_univoche=0
    tot_url_missing=0
    tot_risorse_da_controllare=0

    for filename in $warcs_dir/logs1/*.log; do
        fname=$(basename -- "$filename")
        fname="${fname%.*}"
        istituto=${fname##*_}
        oai_records=0 #OAI record
        risorse_da_controllare=0

        if [[ -f $metadata_dir/$fname".xml" ]]; then
          # oai_records=$( xmllint --format $metadata_dir/$fname".xml" | grep "<record>" | wc -l )

          oai_records=$(cat $receipts_dir/$fname"_tesi.csv" | wc -l)

# echo "fname=$fname"
# echo "oai_records=$oai_records"
          let tot_oai_records=tot_oai_records+oai_records
        else
          continue
        fi

        oai_records_senza_didl=0 #Record senza didl resource
        if [[ -f $receipts_dir/$fname".no_didl_resource" ]]; then
          oai_records_senza_didl=$(cat $receipts_dir/$fname".no_didl_resource" | wc -l)
          let oai_records_senza_didl=oai_records_senza_didl-1
          # let tot_no_didl=tot_no_didl+oai_records_senza_didl
			let tot_oai_records_senza_didl=tot_oai_records_senza_didl+oai_records_senza_didl
		
        fi

        didl_resources_to_download=0 #Didl resource
        if [[ -f $seeds_dir/$fname".seeds" ]]; then
          didl_resources_to_download=$(cat $seeds_dir/$fname".seeds" | wc -l)
# echo "didl_resources_to_download=$didl_resources_to_download"
          let tot_didl_resources_to_download=tot_didl_resources_to_download+didl_resources_to_download
        fi

        didl_resources_non_in_warc=0 #Didl resource non in warc
        if [[ -f $warcs_dir/logs1/$fname".log.seeds_not_in_warc" ]]; then
          didl_resources_non_in_warc=$(cat $receipts_dir/$fname"_ko.csv" | wc -l)
          let didl_resources_non_in_warc=didl_resources_non_in_warc-1
          let tot_didl_resources_non_in_warc=tot_didl_resources_non_in_warc+didl_resources_non_in_warc
        fi

        didl_resources_in_warc=0 #Didle resources in warc (solo quelle appartenenti alle didl resource dei metadati (non i file accessori))
        if [[ -f $receipts_dir/$fname"_ok.csv" ]]; then
            if [[ ! -s $seeds_dir/$fname".seeds" ]]; then
                didl_resources_in_warc=0
            else
                didl_resources_in_warc=$(cat $receipts_dir/$fname"_ok.csv" | wc -l)
                let didl_resources_in_warc=didl_resources_in_warc-1
            fi
            let tot_didl_resources_in_warc=tot_didl_resources_in_warc+didl_resources_in_warc
        fi

        url_non_univoche=0
        if [[ -f $seeds_dir/$fname".seeds_dup.csv" ]]; then
          url_non_univoche=$(cat $seeds_dir/$fname".seeds_dup.csv" | wc -l)
          # aggiungiamo le risorse doppie a quuelle che avremo dovuto scaricare
          let didl_resources_to_download=didl_resources_to_download+url_non_univoche
# echo "didl_resources_to_download=$didl_resources_to_download"
          let tot_url_non_univoche=tot_url_non_univoche+url_non_univoche
        fi

        let risorse_trattate=didl_resources_non_in_warc+didl_resources_in_warc+url_non_univoche

        if [[ $risorse_trattate != $didl_resources_to_download ]]; then
# echo "aggiusta"
            let risorse_da_controllare=didl_resources_to_download-risorse_trattate
# echo "risorse_da_controllare=$risorse_da_controllare"
            if [[ $risorse_da_controllare -lt 0 ]]; then
# echo "*-1"
                let tot_risorse_da_controllare=tot_risorse_da_controllare+risorse_da_controllare*-1
            else
                let tot_risorse_da_controllare=tot_risorse_da_controllare+risorse_da_controllare
            fi
        fi



        # url_missing=0
        # if [[ -f $warcs_dir/logs1/$fname".log.seeds.missing" ]]; then
        #     url_missing=$(cat $warcs_dir/$fname".log.seeds.missing" | wc -l)
        #     let tot_url_missing=tot_url_missing+url_missing
        # fi


        # fine aggiustamento


        echo "$istituto|$oai_records|$oai_records_senza_didl|$didl_resources_to_download|$didl_resources_in_warc|$didl_resources_non_in_warc|$url_non_univoche|$risorse_da_controllare" >> $fileCsv

    done
    echo "" >> $fileCsv
    echo "|$tot_oai_records|$tot_oai_records_senza_didl|$tot_didl_resources_to_download|$tot_didl_resources_in_warc|$tot_didl_resources_non_in_warc|$tot_url_non_univoche|$tot_risorse_da_controllare" >> $fileCsv


    # echo "fileCsv: "$fileCsv
    if [[ -f $fileCsv ]]; then
        unoconv -i FilterOptions=124,, --format  xls $fileCsv
    fi

} # end make_report
