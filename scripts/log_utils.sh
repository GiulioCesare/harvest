#!/bin/sh
readonly URLS_NOT_IN_WARC=0
readonly URLS_IN_WARC=1

extract_errors='BEGIN{
        failed=0;
        error=""
        # print "fileout=" > fileout
    }
    {
    # print "d0="$0 > fileout
    if ( $0 ~ /^[0-9]{4}/ )
    {
        if ($0 ~ " ERROR")
            { # se contiene
            failed=1;
            # error=$0
            error = substr($4,1,3)
            }
        else
            {
            failed=0;
            print $0
            }
    }
    else if ($0 ~ "Giving up"){ # se contiene
            error="999" # Giving up
            failed=1;
        }
    else if ($0 ~ "Authorization failed"){ # se contiene
            error="401"; # Authorization failed
            failed=1;
        }
    else if ($0 ~ " 500 "){ # se contiene
            error="500"; # Non accessibile
            failed=1;
        }
    else
        {
        if (failed == 1)
        {
            if ($0 !~ ".png$") # skip files we know for sure not being theses
            {
                printf "%s|%s\n", error, substr ($0, 26) > fileout
            }
        }
        else
            {
                print $0
            }

        }
    }'


function _load_seeds_to_download ()
{
    # echo "_load_seeds_to_download"

    local fname=$1

    while read -r url
    do
        [ -z "$url" ] && continue  # test empty line

        # tmp=$(sed 's\.*//\\ g' <<<"$url") # rimuovi http?://
        k1=${url%#*} # rimuovi cio' che segue il cancelletto
        replace_octal_with_encoded_hex "$k1" # return  value in $ret_replace_octal_with_encoded_hex
# echo "ret_replace_octal_with_encoded_hex=$ret_replace_octal_with_encoded_hex"
        tmp=$(urldecode "${ret_replace_octal_with_encoded_hex}")
# echo "tmp=$tmp"
        k=$(urldecode "${tmp}")
 # echo "k=$k"
        seeds_to_download_kv_AR[$k]="$k"
    done < $seeds_dir"/"$fname".seeds"

# echo "seeds_to_download_kv_AR length="${#seeds_to_download_kv_AR[@]}
} # end _load_seeds_to_download


function replace_octal_with_encoded_hex()
{
# echo "---replace_octal_with_encoded_hex"
    local s=$1

# echo "s="$s
    pat='\\[0-9]{3}'
	ret_replace_octal_with_encoded_hex=$s
    s1=$s
# echo "s1="$s1
    while true ;  do
        if [[ $s1 =~ $pat ]]; then # $pat must be unquoted
            # echo "${BASH_REMATCH[0]}"
            tmp=${BASH_REMATCH[0]}
            o=${tmp:1}
# echo "o="$o
            x=`echo "obase=16; ibase=8; $o" | bc`
# echo "x="$x
            r="%"$x
# echo "r="$r
            ret_replace_octal_with_encoded_hex="${s1/\\$o/$r}"
            s1=$ret_replace_octal_with_encoded_hex
        else
            break;
        fi
    done
    # echo $s2    # RETURN VALUE to function called like r=$(replace_octal_with_encoded_hex $s)
} # end replace_octal_with_encoded_hex


function normalize_urls()
{
    # echo "normalize_urls"

    local urls_only=$1

    replace_octal_with_encoded_hex "$urls_only" # return  value in $ret_replace_octal_with_encoded_hex
# echo "$ret_replace_octal_with_encoded_hex" > $filename".seeds_in_warc"
# return
    # urls=$(awk -niord '{printf RT?$0chr("0x"substr(RT,2)):$0}' RS=%.. <<< "$ret_replace_octal_with_encoded_hex") # converti caratteri esadecimali
    local urls=$(urldecode "$ret_replace_octal_with_encoded_hex")

# echo "$urls" > $filename$out_ext_ok
# return
    # urls_decoded=$(awk -niord '{printf RT?$0chr("0x"substr(RT,2)):$0}' RS=%.. <<< "$urls") # converti caratteri esadecimali
    local urls_decoded=$(urldecode "$urls")

# echo "$urls_decoded" > $filename$out_ext_ok
# return

    echo "$urls_decoded" ## catch return value via call $(normalize_urls )

} # end normalize_urls


function filter_good_and_bad_seeds_from_seeds_to_download()
{
    local urls_decoded=$1
    local out_filename=$2
    local url_type=$3
# echo "filter_good_and_bad_seeds_from_seeds_to_download"
# echo "$urls_decoded"
# echo "url_type=$url_type"
    # filtra per seeds da scaricare
    readarray -t url_decoded_ar <<<"$urls_decoded"

# echo "DEBUG" >  tmp.log
    for url_decoded in "${url_decoded_ar[@]}"; do

# echo "url_decoded="$url_decoded >> tmp.log

        # k1=${url_decoded%#*} # rimuovi cio' che segue il cancelletto
        if [[ $url_type == $URLS_IN_WARC ]]; then
            k=$url_decoded
        else
            k=${url_decoded:4} # exclude error code
        fi
# echo "k=$k"
        if [ "${seeds_to_download_kv_AR["$k"]}" ]; then
            echo "$url_decoded" >> $out_filename
        fi
    done
} # end filter_good_and_bad_from_seeds_to_download


#function get_warcked_seeds_and_not_from_logs_OLD ()
#{
    # echo "GET WARCKED SEEDS AND NOT FROM LOG"

    # out_ext_ok=".seeds_in_warc"
    # out_ext_ko=".seeds_not_in_warc"
    # out_ext_ko_tmp=".seeds_not_in_warc.tmp"

# echo " _get_seeds_from_logs"
#     if [ "$DEVELOPMENT" == "true" ]; then
#         extension=".seeds$trim_extension"
#     else
#         extension=".seeds"
#     fi


#     for filename in $warcs_dir/log/*.log; do
#         if [[ -f $filename$out_ext_ok ]]; then
#             rm $filename$out_ext_ok
#         fi
#         if [[ -f $filename$out_ext_ko ]]; then
#             rm $filename$out_ext_ko
#         fi
# echo "Working on $filename"
#         fname=$(basename -- "$filename")
#         fname="${fname%.*}"
# echo "fname = $fname"
#         declare -A seeds_to_download_kv_AR
#         _load_seeds_to_download $fname

#         # get archived and not archived urls
#         grep_args="^--[0-9]{4}| saved | salvato | ERROR |Giving up|Authorization failed| 500 "
#         egparams=^--[0-9]{4}
#         archived_urls=`grep -E "$grep_args" $filename | tac | awk -v fileout=$filename$out_ext_ko_tmp "$extract_errors" | egrep "$egparams" | cut -c 26-`

#         # Handle archived urls
#         # --------------------
#         urls_decoded=$(normalize_urls "$archived_urls")
#         filter_good_and_bad_seeds_from_seeds_to_download "$urls_decoded" $filename$out_ext_ok $URLS_IN_WARC

#         # Handle NON archived urls
#         # ------------------------
#         if [[ -f $filename$out_ext_ko_tmp ]]; then
#             non_archived_urls=$(<$filename$out_ext_ko_tmp)
#             urls_decoded=$(normalize_urls "$non_archived_urls")
#             filter_good_and_bad_seeds_from_seeds_to_download "$urls_decoded" $filename$out_ext_ko $URLS_NOT_IN_WARC
#             rm $filename$out_ext_ko_tmp
#         fi
#         unset seeds_to_download_kv_AR
#     done
# } # end get_warcked_seeds_and_not_from_logs_OLD











function get_warcked_seeds_and_not_from_logs()
{
    echo "GET WARCKED SEEDS AND NOT FROM LOG"

    out_ext_ok=".seeds_in_warc"
    out_ext_ko=".seeds_not_in_warc"
    out_ext_ko_tmp=".seeds_not_in_warc.tmp"



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
      fi

      istituto=${array[1]}
      filename=$warcs_dir"/log/"$harvest_date_materiale"_"$istituto".log"


      echo "Working on "$filename

#     for filename in $warcs_dir/log/*.log; do

        if [[ -f $filename$out_ext_ok ]]; then
            rm $filename$out_ext_ok
        fi
        if [[ -f $filename$out_ext_ko ]]; then
            rm $filename$out_ext_ko
        fi

        fname=$(basename -- "$filename")
        fname="${fname%.*}"

 # echo "fname = $fname"

        declare -A seeds_to_download_kv_AR
        _load_seeds_to_download $fname

        # get archived and not archived urls
        grep_args="^--[0-9]{4}| saved | salvato | ERROR |Giving up|Authorization failed| 500 "
        egparams=^--[0-9]{4}
        archived_urls=`grep -E "$grep_args" $filename | tac | awk -v fileout=$filename$out_ext_ko_tmp "$extract_errors" | egrep "$egparams" | cut -c 26-`

        # Handle archived urls
        # --------------------
        urls_decoded=$(normalize_urls "$archived_urls")
        filter_good_and_bad_seeds_from_seeds_to_download "$urls_decoded" $filename$out_ext_ok $URLS_IN_WARC

        # Handle NON archived urls
        # ------------------------
        if [[ -f $filename$out_ext_ko_tmp ]]; then
            non_archived_urls=$(<$filename$out_ext_ko_tmp)
            urls_decoded=$(normalize_urls "$non_archived_urls")
            filter_good_and_bad_seeds_from_seeds_to_download "$urls_decoded" $filename$out_ext_ko $URLS_NOT_IN_WARC
            rm $filename$out_ext_ko_tmp
        fi
        unset seeds_to_download_kv_AR

    done < "$repositories_file"

} # end get_warcked_seeds_and_not_from_logs



