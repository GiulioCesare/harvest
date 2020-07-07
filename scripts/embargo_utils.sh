#!/bin/sh


# HARVEST METADATA
# ================
function find_rights()
{
    echo "--> FIND RIGHTS for $repositories_file"

    # salviamo la data dell'harvesting

    # SAMPLE python ~/bin/pyoaiharvester/pyoaiharvest.py  -l https://etd.adm.unipi.it/ETD-db/NDLTD-OAI/oai.pl -o 01_metadata/unipi.xml -f 2019-06-01 -m didl -s dtype:PhD

    # Read trough the repositories_file
    while IFS='|' read -r -a array line
    do
      line=${array[0]}
      # se riga comentata o vuota skip
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
# echo skip;
        continue
      else

      site=${array[1]}
      metadata_file=$metadata_dir"/"$harvest_date_materiale"_"$site".xml"
      rights_file=$metadata_dir"/"$harvest_date_materiale"_"$site".rights"
      echo "--> Working on "$metadata_file

      rights=`xmllint --format  $metadata_file | grep -i "<dc:rights" | sort -u`
      names="$rights"

      SAVEIFS=$IFS   # Save current IFS
      IFS=$'\n'      # Change IFS to new line
      names=($names) # split to array $names
      IFS=$SAVEIFS   # Restore IFS

      echo "# Rights" > $rights_file
      for (( i=0; i<${#names[@]}; i++ ))
      do
          r="${names[$i]}"
          # Trim leading spaces
          echo  ${r##*( )} >> $rights_file
      done


    fi
    done < "$repositories_file"
} # end find_rights


function _genera_dati_di_embargo()
{
    local istituto=$1


} # end _genera_dati_per_ricevute



function find_embargoed()
{
    echo "--> FIND EMARGOED for $repositories_file"
    # Read trough the repositories_file
    while IFS='|' read -r -a array line
    do
      line=${array[0]}
      # se riga comentata o vuota skip
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
# echo skip;
        continue
      else

      istituto=${array[1]}
      metadata_file=$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml"
      # echo "--> Working on "$metadata_file


      # Generiamo i dati per le ricevute
      if [ $work_dir == $E_JOURNALS_DIR ]; then
          # command="python ./parse_e_journals_ricevute.py "$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml "$formatted_harvest_date
          echo "TODO embargo per e-journal"
      else
          # TESI
          command="python ./parse_tesi_embargo.py "$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml"
      fi
  # echo "Crea meta dati per ricevute in formato ASCII PSV (Pipe Separated Values) for ${array[1]}: "$command
  	embargo_filename=$metadata_dir/$harvest_date_materiale"_"$istituto".embargo"
   # echo "Crea documenti sotto embargo per:" $metadata_file
   echo "Crea documenti sotto embargo in:" $embargo_filename
      eval $command | sort > $embargo_filename


    fi
    done < "$repositories_file"

} # find_embargoed
