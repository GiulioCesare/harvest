# 29/11/2020
# Modulo per la gestionde delle date di harvesting
# 

function load_anagrafe_array()
{
    echo "--> LOAD ANAGRAFE"

     if [ $materiale == $MATERIALE_TESI ]; then
        filename="csv/anagrafe_td.out"
     else
        filename="csv/anagrafe_ej.out"
     fi

# echo "filename=$filename"

    if [ -f $filename ]; then
        # echo "load last harvesting dates"

        while IFS='|' read -r -a array line
        do
            line=${array[0]}
          # if [[ ${line:0:1} == "#" ]];     then
            if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                continue
          else
              
              local id_istituzione=${array[0]}
              local id_datasource=${array[1]}
              local istituto=${array[2]}
              local materiale=${array[3]}

# echo "istituto=$istituto"

              anagrafe_ar[$istituto]=$id_istituzione"|"$id_datasource"|"$istituto"|"$materiale
        fi
        done < "$filename"

    else
        echo "Non trovo il file dell'anagrafe: $filename"
        exit
    fi

    # Dump array
    # ----------
    # echo "dump anagrafe"
    # for K in "${!anagrafe_ar[@]}";
    #     do
    #         echo $K"="${anagrafe_ar[$K]}
    #     done

} # End load_anagrafe_array





function generate_harvest_dates_from_metadata_logs()
{
    # ANAGRAFE
    # id_istituzione ,id_datasource e harvest_name (istituto) li scarico da anagrafe!!
    # in csv/anagrafe.out
  
    echo "generate_harvest_dates"


    load_anagrafe_array

pwd
    harvested_dates="csv/date.upd_ins"
echo "harvested_dates =  $harvested_dates"

    if [ -f $harvested_dates ]; then
        echo "Removing $harvested_dates"
        rm $harvested_dates
    fi


    echo "Prepariamo estraiamo dai log dei metadate il range di date harvestato"
    while IFS='|' read -r -a array line
    do
           line=${array[0]}

        # Remove whitespaces (empty lines)
        line=`echo $line | xargs`

        if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
            break
        fi

           # se riga comentata o vuota skip
           if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];  then
                 continue
            fi

        local istituto=${array[1]}
        local log_filename=$metadata_dir"/"$harvest_date_materiale"_"$istituto".log"

        echo "log_filename=$log_filename"


        # echo "log_line=$log_line"

        if ! test "${anagrafe_ar[$istituto]+isset}"
        then
            echo "--> $istituto non e' presente in anagrafe"
            continue;
        fi

        log_line=`grep -m1 -ioP 'from=[0-9]{4}-[0-9]{2}-[0-9]{2}|until=[0-9]{4}-[0-9]{2}-[0-9]{2}' $log_filename | sed 's#^from=##g; s#^until=##g'`


        db_line="${log_line/$'\n'/'|'}"

        # get the session date
        fname=$(basename -- "$log_filename")
        
        session_date=${fname:0:10}

# echo "session_date=$session_date"        
        session_date="${session_date//'_'/'-'}"
# echo "session_date=$session_date"        

        db_line=$db_line"|"$session_date
        
        echo ${anagrafe_ar[$istituto]}"|$db_line" >> $harvested_dates

    done < $HARVEST_DIR/$repositories_file


} # End generate_harvest_dates_from_metadata_logs





function generate_last_harvest_dates()
{
    echo "generate_last_harvest_dates"
    local filename_in=""

    if [ $materiale == $MATERIALE_TESI ]; then
        filename_in="csv/date_td.out"
        filename_out="csv/etd_last_harvest_date.csv.template"
    else
        filename_in="csv/date_ej.out"
        filename_out="csv/e_journals_last_harvest_date.csv.template"
    fi

    # sort -T ./tmp -t\| -k4,4 -k7,7rn $filename_in > $filename_in".srt"



    echo "Extract last harvest date per institute"

    echo " filename_in: "$filename_in
    echo " filename_out: "$filename_out

    awk 'BEGIN{
      FS="|"; 
      prev_institute = ""
    }
    
    {
    # If line commented or empty
    if ($1 ~ "#"  || $1 == "")
        next
    # print "D4="$4
    if (prev_institute != $4)
      {
        print $4"|"$7
      }
    prev_institute = $4

    }' $filename_in".srt" > $filename_out


} # End generate_last_harvest_dates

