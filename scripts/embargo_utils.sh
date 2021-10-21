#!/bin/sh
# ---------------------------------------------------------------------
# 07/10/2021
# Gestione TESI sotto embargo 
# Specifiche in GestioneDirittiPerMemoria.docx. Inviate alla BNCF (Storti) in data 15/07/2020 16:29
# 
# =========
# Tipo OPEN 
# =========
# • openAccess = OPEN 
#   - Le tesi dichiarate ‘openAccess’ possono essere interamente consultate da qualsiasi postazione 
#     collegata alle reti interne della BNCF e della BNCR.
#
# • closedAccess = OPEN
#   - Le tesi dichiarate ‘closedAccess’ sono considerate interamente consultabili da qualsiasi postazione 
#     collegata alle reti interne della BNCF e della BNCR.
#
# • reserved = OPEN
#   - Le tesi dichiarate ‘reserved’ possono essere interamente consultate da qualsiasi postazione collegata alle 
#     reti interne della BNCF e della BNCR.
# • none = OPEN
#   - Le tesi dichiarate ‘none’ sono considerate interamente consultabili da qualsiasi postazione collegata alle reti 
#     interne della BNCF e della BNCR.
# 
# ==============
# Tipo EMBARGOED
# ==============
# • restrictedAccess = EMBARGOED
#   - Le tesi dichiarate ‘restrictedAccess’, nella gestione ipotizzata con i dati attualmente a disposizione, 
#     si considerano embargate in tutte le loro parti, quindi non consultabili in nessun caso. 
#
# • partially_open = EMBARGOED
#   - Le tesi dichiarate ‘partially_open, nella gestione ipotizzata con i dati attualmente a disposizione, 
#     si considerano embargate in tutte le loro parti, quindi non consultabili in nessun caso.
#
# • embargoedAccess = EMBARGOED
#   - Le tesi esplicitamente dichiarate ‘embargoedAccess’ sono considerate non consultabili fino alla data 
#     di fine dell’embargo, dopo il quale saranno consultabili da qualsiasi postazione collegata alle reti 
#     interne della BNCF e della BNCR.
#
#
#
# ==============
# Da definire
# ==============
#
# • mixed = OPEN or EMBARGOED ??? (unicatt)
#
#
#
# ---------------------------------------------------------------------




# EMBARGO UTILITIES
# =================

function _find_rights_unique()
{
    echo 
    echo "-> find_rights_unique for $repositories_file"

    # salviamo la data dell'harvesting

    # SAMPLE python ~/bin/pyoaiharvester/pyoaiharvest.py  -l https://etd.adm.unipi.it/ETD-db/NDLTD-OAI/oai.pl -o 01_metadata/unipi.xml -f 2019-06-01 -m didl -s dtype:PhD

    # Read trough the repositories_file
    while IFS='|' read -r -a array line
    do
      line=${array[0]}
      # se riga comentata o vuota skip

echo "line=$line"
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
        continue
      fi


      # Remove whitespaces (empty lines)
      line=`echo $line | xargs`
      if [[ ${line} == "" ]];     then
        continue
      fi

      # Se ignora resto del file
      if [[ ${line:0:1} == "@" ]] ; then # Ignore rest of file
        break
      fi

      site=${array[1]}
      metadata_file=$metadata_dir"/"$harvest_date_materiale"_"$site".xml"
      rights_file=$rights_dir"/"$harvest_date_materiale"_"$site".rights.unq"
      echo "--> Working on "$metadata_file

      rights=`xmllint --format  $metadata_file | grep -i "<dc:rights" | sort -u`
      names="$rights"

      SAVEIFS=$IFS   # Save current IFS
      IFS=$'\n'      # Change IFS to new line
      names=($names) # split to array $names
      IFS=$SAVEIFS   # Restore IFS

      echo "# Rights unique" > $rights_file
      for (( i=0; i<${#names[@]}; i++ ))
      do
          r="${names[$i]}"
          # Trim leading spaces
          echo  ${r##*( )} >> $rights_file
      done


    # fi
    done < "$repositories_file"
} # end find_rights_unique


function _genera_dati_di_embargo()
{
    local istituto=$1


} # end _genera_dati_per_ricevute






function _filterEmbargoIstituto()
{
  # echo "--> filterEmbargo"
  local rights_filename=$1
  local embargo_filename=$rights_dir/$harvest_date_materiale"_"$istituto".embargo.csv"
  # local embargo_filename_ko=$rights_dir/$harvest_date_materiale"_"$istituto".embargo.csv.ko"


  # embargo_default_end_date="9999-12-31" # Non scade mai

  # In caso che non ci sia una data di embargo od una data di discussione allora aggiungiamo 36 mesi  alla data di harvesting
  # embargo scade 3 anni dop la data di Harvesting
  dash_date=$(echo $harvest_date | sed -r "s#([0-9]{4})_([0-9]{2})_([0-9]{2})#\1-\2-\3#g" )
  declare -i year=${dash_date:0:4}
  let "year+=3"
  embargo_default_end_date=$year${dash_date:4}

  # embargo scade 3 anni dopo data di discussione
  # TODO dato ancora non disponibile nei metadati



awk_command='
    BEGIN{FS="|"; }
    {
    # If line commented or empty
    if ($1 ~ "#"  || $1 == "")
        next

    oai_id = $1
    rights = toupper($2)
    embargo_end_date = $3
    url = $4

    if (rights ~ "EMBARGO" )
      {
      # find different patterns
      if (rights ~ "^EMBARGOED_[0-9]{8}$" )
          {
          # print rights
          # print $0
          print oai_id "|" url "|" substr(rights,11,4) "-" substr(rights,15,2) "-" substr(rights,17,2)
          }

      else if (rights ~ "^INFO:EU-REPO/SEMANTICS/EMBARGOEDACCESS.*$" ) # sssup (info:eu-repo/semantics/embargoedAccess;Copyright information available at source archive)
          {
          if(embargo_end_date=="")
            {
           print oai_id "|" url "|"embargo_default_end_date # qui dobbiamo gestire i 3 anni di default
            }
          else
            {
            len = length (embargo_end_date)

# print "len " len " per '" embargo_end_date "'"
            if (len > 10) # anche time stamp
              {
              print oai_id "|" url "|" substr(embargo_end_date, 1, 10)
              }

            else if (len == 4) # solo anno
              {
              print oai_id "|" url "|" embargo_end_date "-12-31"
              }
            else if (len == 7) # solo anno/mese
              {
              print oai_id "|" url "|" embargo_end_date "-01"
              }
            else
              {
              print oai_id "|" url "|" embargo_end_date
              }

            }
 
          }
      else
        {
          if(embargo_end_date!="") 
            {
            # non abbiamo intercettatto la sintassi dell embargo ma abbiamo capito che e sotto embargo ed abbiamo una data di fine embargo
            len = length (embargo_end_date)
            if (len > 10) # anche time stamp
              {
              print oai_id "|" url "|" substr(embargo_end_date, 1, 10)
              }
            else if (len == 4) # solo anno
              {
              print oai_id "|" url "|" embargo_end_date "-12-31"
              }
            else if (len == 7) # solo anno/mese
              {
              print oai_id "|" url "|" embargo_end_date "-01"
              }
             else
              {
              print oai_id "|" url "|" embargo_end_date
              }
            }
          else
            {
            print oai_id "|" url "|" embargo_default_end_date
            }

        }

      fi
      } # end if found embargo
    
    # else
    #      print oai_id "|" url  > non_embargo_filename
    # fi
    
    }'
 
    if [[ -f $embargo_filename ]]; then
      echo "remove " $embargo_filename
      rm $embargo_filename
    fi

    awk -v unkwown_embargo="$embargo_filename_ko" -v embargo_default_end_date="$embargo_default_end_date" "$awk_command"  $rights_filename > $embargo_filename



} # end _filterEmbargoIstituto


function _filterNonEmbargoIstituto ()
{
  local rights_filename=$1
  local non_embargo_filename=$rights_dir/$harvest_date_materiale"_"$istituto".non_embargo.csv"


awk_command='
    BEGIN{
      FS="|"; 
      prev_oai_id = ""
    }
    
    {
    # If line commented or empty
    if ($1 ~ "#"  || $1 == "")
        next
    fi
    oai_id = $1
    # if (prev_oai_id != oai_id)
    #   {
      rights = toupper($2)
      if (rights !~ "EMBARGO" && rights !~ "PARTIALLY" && rights !~ "RESTRICTED")
        {
        url = $4
        print oai_id"|"rights"|"url
        }
        prev_oai_id = oai_id
      # }

    
    }'
    awk -v non_embargo_filename="$non_embargo_filename" -v embargo_default_end_date="$embargo_default_end_date" "$awk_command"  $rights_filename > $non_embargo_filename

  # Creiamo il file do oaid_univoci per rimuovere tesi che prima erano embargate e che forse adesso non lo sono piu'
  # sort -t\| -k 1,1 -u $non_embargo_filename > $non_embargo_filename".unq"

} # end _filterNonEmbargoIstituto



function _extract_rights()
{
  # LIUC <dc:rights>http://www.biblio.liuc.it/pagineita.asp?codice=247</dc:rights> Non corrisponde a niente!!!
  # <dc:rights>info:eu-repo/semantics/closedAccess</dc:rights>  non vanno embargate
  # unisi  non ha i pdf associati alla pagina descrittiva della tesi (09/07/2020)
  # unive  nei rights ci sono inomi degli autori
  # unica  ci sono tesi senza contenuti, Eg: |http://hdl.handle.net/11584/271311|THREE ESSAYS ON MENTAL DISORDERS, STRATEGIC THINKING AND TRUST

    echo 
    echo "-> extract rights for $repositories_file"
    # Read trough the repositories_file
    while IFS='|' read -r -a array line
    do
      line=${array[0]}

      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
        continue
      fi


      # Remove whitespaces (empty lines)
      line=`echo $line | xargs`
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
        continue
      fi

      # se riga comentata o vuota skip
      if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
        break
      fi


      istituto=${array[1]}
      metadata_file=$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml"
      # echo "--> Working on "$metadata_file


      # Generiamo i dati per le ricevute
      if [ $work_dir == $E_JOURNALS_DIR ]; then
          # command="python ./parse_e_journals_ricevute.py "$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml "$formatted_harvest_date
          echo "TODO embargo per e-journal"
      else
          # TESI
          command="python ./scripts/parse_tesi_embargo.py "$metadata_dir"/"$harvest_date_materiale"_"$istituto".xml"
      fi
      # echo "Crea meta dati per ricevute in formato ASCII PSV (Pipe Separated Values) for ${array[1]}: "$command
      rights_filename=$rights_dir/$harvest_date_materiale"_"$istituto".rights.csv"

      # echo "Crea documenti sotto embargo per:" $metadata_file
      echo "--> Working on: " $rights_filename
      eval $command > $rights_filename

    # fi
    done < "$repositories_file"

} # _extract_rights


function _filterEmbargo_e_non()
{

    echo 
    echo "-> Filter embargo for $repositories_file"
    # Read trough the repositories_file
    while IFS='|' read -r -a array line
    do
      line=${array[0]}

      # Remove whitespaces (empty lines)
      line=`echo $line | xargs`

      # Se ignora resto del file
      if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
        break
      fi

      # se riga comentata o vuota skip
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
# echo skip;
        continue
      else

      istituto=${array[1]}
      # echo "Crea meta dati per ricevute in formato ASCII PSV (Pipe Separated Values) for ${array[1]}: "$command
      rights_filename=$rights_dir/$harvest_date_materiale"_"$istituto".rights.csv"

      echo "--> Working on: " $rights_filename
      _filterEmbargoIstituto $rights_filename;
      _filterNonEmbargoIstituto $rights_filename;

      fi
    done < "$repositories_file"

} #_filterEmbargo_e_non



function _prepareDbUpdateInsertDelete ()
  {


    upd_ins_filename=$rights_dir/embargo.upd_ins
    delete_filename=$rights_dir/embargo.del
    echo 
    echo "-> Prepare file for DB update/insert: " $upd_ins_filename

    echo -n "" > $upd_ins_filename
    echo -n "" > $delete_filename

    while IFS='|' read -r -a array line
    do
      line=${array[0]}
   
      # Remove whitespaces (empty lines)
      line=`echo $line | xargs`


      # Se ignora resto del file
      if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
        break
      fi

      # se riga comentata o vuota skip
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
        continue
      else

      istituto=${array[1]}
echo "Istituto = '$istituto'"
      
      # filename=$rights_dir/$harvest_date_materiale"_"$istituto".embargo.csv"
      filename=$rights_dir/$harvest_date_materiale"_"$istituto".embargo.csv.in_warc.csv" # 11/10/2020

      echo "--> Appending " $filename " to " $upd_ins_filename
      cat $filename >> $upd_ins_filename

      filename=$rights_dir/$harvest_date_materiale"_"$istituto".non_embargo.csv"
      echo "--> Appending " $filename " to " $delete_filename
      cat $filename >> $delete_filename

      fi
    done < "$repositories_file"
  } # End _prepareDbUpdateInsertDelete


# 11/10/2020  controllare che tesi sotto embargo siano state acquisite!!!
function _get_embargoed_only_in_warc()
{
    echo "_get_embargoed_only_in_warc"


    while IFS='|' read -r -a array line
    do
      line=${array[0]}


      # Remove whitespaces (empty lines)
      line=`echo $line | xargs`

      
      # Se ignora resto del file
      if [[ ${line:0:1} == "@" ]]; then # Ignore rest of file
        break
      fi

      # se riga comentata o vuota skip
      if [[ ${line:0:1} == "#" ]] || [[ ${line} == "" ]];     then
        continue
      else

      local istituto=${array[1]}
      # echo "Istituto: '$istituto'" 
      _get_embargoed_only_in_warc_istituto $istituto

      fi
    done < "$repositories_file"
        
} # End _get_embargoed_only_in_warc


function _get_embargoed_only_in_warc_istituto ()
{
  echo "_get_embargoed_only_in_warc_istituto for: "$istituto
  

  local istituto=$1

    # carichiamo i seed finiti nel warc
     declare -A seeds_in_warc_kv_AR

    siw=$warcs_log_dir/$istituto.log.seeds_in_warc
    if [[ -f $siw ]]; then
# echo "reading $warcs_log_dir/$fname.log.seeds_in_warc"
        while read -r  line
        do
            # tmp=$(sed 's\.*//\\ g' <<<"$line")
            # tmp2=${tmp//\+/ }
            # url=$(urldecode "$tmp2")
            # seeds_in_warc_kv_AR[$url]="dummy value"
            seeds_in_warc_kv_AR[$line]="dummy value"

        done < $siw
    fi

    # Leggiamo il file delle tesi embargate
    file_emabrgo=$rights_dir/$harvest_date_materiale"_"$istituto".embargo.csv"
    if [[ -f $file_emabrgo".in_warc.csv" ]]; then
      rm $file_emabrgo".in_warc.csv"
    fi
    if [[ -f $file_emabrgo".not_in_warc.csv" ]]; then
      rm $file_emabrgo".not_in_warc.csv"
    fi



        # while IFS='|' read -r -a array line
        while read -r line
        do
        array=(${line//|/ })


          url_in=${array[1]}
            tmp=$(sed 's\.*//\\ g' <<<"$url_in")
            tmp2=${tmp//\+/ }
            url=$(urldecode "$tmp2")

# echo "URL embargo='$url'"

            if ! test "${seeds_in_warc_kv_AR[$url]+isset}"
            then
                # echo ${array[0]}"|"${array[1]}"|"${array[2]} >> $file_emabrgo".in_warc.csv"
                echo $line >> $file_emabrgo".in_warc.csv"
            else
                # echo ${array[0]}"|"${array[1]}"|"${array[2]} >> $file_emabrgo".not_in_warc.csv"
                echo $line >> $file_emabrgo".not_in_warc.csv"
            fi


            # seeds_in_warc_kv_AR[$url]="dummy value"
        done < $file_emabrgo

} # end _get_embargoed_only_in_warc_istituto





function find_embargoed()
{
    _find_rights_unique
    _extract_rights
    _filterEmbargo_e_non
    _get_embargoed_only_in_warc
    _prepareDbUpdateInsertDelete
}
