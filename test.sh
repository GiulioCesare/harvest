#!/bin/bash
#

# Parallel runs
# for thing in a b c d e f g; do
#   task "$thing" &
# done

# Parallel runs in N-process batches
# N=4
# (
# for thing in a b c d e f g; do
#    ((i=i%N)); ((i++==0)) && wait
#    task "$thing" &
# done
# set -x


# Parallel execution in max N-process concurrent
# https://stackoverflow.com/questions/2437452/how-to-get-the-list-of-files-in-a-directory-in-a-shell-script/2437466

function concurrent_curl_jobs()
{
N_JOBS=6
for filename in `ls tesi/02_seeds/*.small`;
    do
    (
        # .. do your stuff here
        # echo "starting task $i.."

        # sleep $(( (RANDOM % 3) + 1))
        # head -n3 $file > $file".small"

        echo "starting task on file $filename"
        fname=$(basename -- "$filename")
        extension="${fname##*.}"
        fname="${fname%.*}"
        # echo "------>fname="$fname

        command="parallel --colsep '\t' -j6 ./http_code {} {} :::: "$filename
# echo "command="$command
        eval $command > "tesi/03_check_seeds/$fname.tsv"

    ) &

    # allow only to execute $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -gt $N_JOBS ]]; then
        # wait only for first job
        wait -n
    fi
    done

    # wait for pending jobs
    wait

    echo "all done"

} # end concurrent_curl_jobs

function wget_parallel()
{
    echo "Test wget with warc in parall."
    cd tmp

    cmd="wget --no-check-certificate --user-agent='bncf' --page-requisites --output-file=./2019_11_03_tesi_imtlucca.log --warc-file=./2019_11_03_tesi_imtlucca"
    seeds=./2019_11_03_tesi_imtlucca.seeds
    echo "wget_ting $seeds"
    # parallel --jobs 3 $cmd < $seeds 2> /dev/null KO con warc ho output sempre diversi del warc.gz
    # $cmd < $seeds 2> /dev/null

    wget --no-check-certificate --user-agent='bncf' --page-requisites --output-file=./2019_11_03_tesi_imtlucca.log --warc-file=./2019_11_03_tesi_imtlucca -i$seeds


    cd ..
}

seeds_per_block=10

# KO non accoda ma sovrascrive
function do_wget_by_seed_block()
{
    # NMB usare variabili LOCALI per gestire concurrency
    local seeds_filename=$1

    # dal file dei seeds estraiamo la url del server dell'istituto che viene usato pre creare la cartella
    # dove scaricare le tesi prima dell'archiviazione in warc

    read -r firstline < $seeds_filename
    echo "firstline="$firstline

    local folder=$(echo "$firstline" | cut -f 3 -d '/')
    echo "folder="$folder


    echo "starting task on file $seeds_filename"
    local fname=$(basename -- "$seeds_filename")
    local extension="${fname##*.}"
    local fname="${fname%.*}"
    # echo "------>fname="$fname

    # Remove existing files
    if [ -f $fname.seeds.tmp ]; then
        echo "delete old $fname.seeds.tmp"
        rm $fname.seeds.tmp
    fi
    # LOOP
    local ctr=0
    local seeds_block_ctr=0
    while IFS= read -r line
        do

        if [ $ctr == 0 ]; then
            ((seeds_block_ctr++))
            echo "seeds_block_ctr="$seeds_block_ctr
        fi

        # creare file di seeds da $seeds_per_block elementi
        echo "$line" >> $fname.seeds.tmp
        ((ctr++))

        if [ $ctr == $seeds_per_block ] ; then

            # creare warc per questi # elementi

            echo "wget_ting $fname.seeds.tmp"
            # echo "wget --no-check-certificate --user-agent='bncf' --page-requisites --output-file=./$fname.log --warc-file=./$fname -i=$fname.seeds.tmp"
            wget --no-check-certificate --user-agent='bncf' --page-requisites --output-file=./$fname.log --warc-file=./$fname --input-file=$fname.seeds.tmp



            echo "remove block $seeds_block_ctr $fname.seeds.tmp"
            rm $fname.seeds.tmp
            ctr=0

            # break;
        fi

        done < "$seeds_filename"

    # Last block of seeds?
    if [ -f $fname.seeds.tmp ]; then

        echo "wget_ting $fname.seeds.tmp"
        wget --no-check-certificate --user-agent='bncf' --page-requisites --output-file=./$fname.log --warc-file=./$fname --input-file=$fname.seeds.tmp


        echo "delete last block $fname.seeds.tmp"
        rm $fname.seeds.tmp
    fi







} # end do_wget_by_seed_block



function do_wget()
{
    local seeds_filename=$1

    local fname=$(basename -- "$seeds_filename")
    local fname="${fname%.*}"
    # echo "starting task on file $seeds_filename"
    # echo "fname="$fname

    echo "wget_ting $seeds_filename"
    wget_options="--delete-after --no-directories --no-check-certificate --user-agent='bncf' --page-requisites"
    wget $wget_options --input-file=$seeds_filename --output-file=./$fname.log --warc-file=./$fname

} # end do_wget





function concurrent_warc_jobs()
{
cd tmp


N_JOBS=6
cmd="wget --no-check-certificate --user-agent='bncf' --page-requisites --output-file=./2019_11_03_tesi_imtlucca.log --warc-file=./2019_11_03_tesi_imtlucca"

for seeds_filename in `ls ../tesi/05_validated_seeds/*.seeds`;
    do
    (
        # .. do your stuff here
        # echo "starting task $i.."

        # sleep $(( (RANDOM % 3) + 1))
        # head -n3 $file > $file".small"

        do_wget $seeds_filename
    ) &
    # allow only to execute $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -gt $N_JOBS ]]; then
        # wait only for first job
        wait -n
    fi
    done

    # wait for pending jobs
    wait1

    echo "all done"
cd ..
} # end concurrent_warc_jobs



# ========================================
# EXECUTE
# ========================================

# concurrent_curl_jobs
# wget_parallel
# concurrent_warc_jobs

function replace_octal_with_encoded_hex()
{
    local s=$1
# echo "s="$s
    pat='\\[0-9]{3}'

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

            s2=${s1/\\$o/$r}
            s1=$s2
        else
            break;
        fi
    done

    echo $s2    # RETURN VALUE to function called like r=$(replace_octal_with_encoded_hex $s)

} # end replace_octal_with_encoded_hex


# s="Cansu_Ulu\305%9Feker_PhD_Thesis\303\342.pdf"
# r=$(replace_octal_with_encoded_hex $s)
# echo "r="$r




# gawk 'BEGIN{ FS="’";look_for_url=0;file_downloaded=""}
#         {
#             # print $0
#             if ( $0 ~ /^[0-9]{4}/ )
#             {
#                 if (look_for_url == 1)
#                     print "NOT FOUND "file_downloaded
#
#                 p=index($1,"‘");
#                 file_downloaded=substr($1,p+1);
#                 # print file_downloaded
#                 look_for_url=1
#                 # print $1
#                 next;
#             }
#             if (look_for_url == 1)
#             {
#                 # print $0
#                 # if ( $0 ~ /file_downloaded/ )
#                 ret = index($0, file_downloaded)
#                 # print "ret="ret
#                 if (ret > 0)
#                 {
#                     print $0
#                     file_downloaded=""
#                     look_for_url=0
#                 }
#             }
#
#         }
#         END {
#             # print "Fine"
#         }
#         ' tesi/06_warcs/2019_11_14_tesi_unicatt.log.seeds_in_warc

# gawk 'BEGIN{ FS="’";look_for_url=0;file_downloaded=""}{if ( $0 ~ /^[0-9]{4}/ ) {p=index($1,"‘");file_downloaded=substr($1,p+1);look_for_url=1;next;}if (look_for_url == 1){if (index($0, file_downloaded) > 0){print $0;look_for_url=0;}}}' tesi/06_warcs/2019_11_14_tesi_unicatt.log.seeds_in_warc | wc-l
 # grep -E "^--[0-9]{4}|saved|salvato" /home/argentino/magazzini_digitali/harvest/tesi/06_warcs/2019_11_14_tesi_unicatt.log | tac > tmp.txt


# gawk 'BEGIN{ FS="’";
#     look_for_url=0;
#     file_downloaded=""
#     last_found=""
#     }
#     {
#         if ( $0 ~ /^[0-9]{4}/ )
#         {
#             if (last_found != ""){
#                 print last_found
#                 last_found="";}
#
#             p=index($1,"‘");
#             file_downloaded=substr($1,p+1);
#             look_for_url=1;next;
#         }
#     else
#         {
#             d0=$0
#             # replace + sign to sopace (wget does it)
#             gsub("+"," ",$0)
#
#             if (index($0, file_downloaded) > 0)
#             {
#                 # print d0;look_for_url=0;
#                 last_found=d0;
#
#             }
#         }
#     }
# END {
#     if (last_found != "")
#     {
#         print last_found
#         last_found="";
#     }
#     }
#
#     ' tesi/06_warcs/2019_11_14_tesi_unimc.log.seeds_in_warc


# gawk '
# {
# if ( $0 ~ /^[0-9]{4}/ )
#     printf "%s", substr($4,1,3)
# else
#     print "|"$0
# }' tesi/06_warcs/2019_11_14_tesi_unicatt.log.seeds_not_in_warc


# awk '{ sub(\.[0-9]+$, $0 ); }' <<< "Thesis.pdf.1"




# function urldecode()
# {
#     urls=$1
# # : "${*//+/ }";
# # echo -e "${_//%/\\x}";
# awk -niord '{printf RT?$0chr("0x"substr(RT,2)):$0}' RS=%.. <<< $urls
# }
#
# urls=`cat tesi/06_warcs/tmp.txt`
# urls_decoded=$(urldecode "$urls")
# echo "$urls_decoded"

# awk -niord '{printf RT?$0chr("0x"substr(RT,2)):$0}' RS=%.. tesi/06_warcs/2019_11_05_tesi_unical.log.seeds_in_warc > tmp.txt
# awk -niord '{printf RT?$0chr("0x"substr(RT,2)):$0}' RS=%.. <<< $urls



# awk -F"[-]" 'BEGIN{file_downloaded="";last_found=""}
# {
#     # print "d0="$0
#
#     if ( $0 ~ /^[0-9]{4}/ ){
#         if (last_found != "")
#             {
#             print last_found
#             last_found="";
#             }
#         sub(/\.[0-9]+$/, "", $2 );  # remove extention of renamed files eg.  "Thesis.pdf.1" -> "Thesis.pdf"
#         gsub("+"," ",$2)
#         file_downloaded=$2;
# print "file_downloaded="$file_downloaded
#         next;
#         }
#     else{
#         d0=$0
#         gsub("+"," ",$0)    # replace + sign to space (wget does it)
#         idx=index($0, file_downloaded)
# # print "idx="$idx", d0="$d0
#         if (idx > 0) {
#             last_found=d0;
#             }
#         }
#     }
#     END {if (last_found != "")
#         {
#             print last_found
#             last_found="";
#         }
#     }'  tesi/06_warcs/2019_11_05_tesi_unical.log.seeds_in_warc



# awk  'BEGIN{file_downloaded="";last_found=""}
#     {
# # print "d0="$0
# gsub(/ /, "\x01",$0)
# # print "d0="$0
#
#             gsub("+"," ",$0)
#
#         if ( $0 ~ /^[0-9]{4}/ ){
#             if (last_found != "")
#                 {
#                 print last_found
#                 last_found="";
#                 }
#             tesi=""
#             campi=split($0,campoAR,"\x01");
# print "campi="campi
#             for(i = 6; i <= campi; i++)
#                 {
#                 if (campoAR[i] == "saved" || campoAR[i] == "salvato")
#                     break;
#                 if (i == 6)
#                     tesi=campoAR[i]
#                     # printf "%s",campoAR[i];
#                 else
#                     tesi=tesi" "campoAR[i]
#                     # printf " %s",campoAR[i];
#                 }
#             file_downloaded=substr(tesi, 2, length(tesi)-2)
#             print "tesi="file_downloaded
#             sub(/\.[0-9]+$/, "", file_downloaded );  # remove extention of renamed files eg.  "Thesis.pdf.1" -> "Thesis.pdf"
#             gsub("+"," ",file_downloaded) # sostituzione del +
# print "file_downloaded="file_downloaded
#             }
#
#         else{
#             d0=$0
#             gsub("+"," ",$0)    # replace + sign to space (wget does it)
#             idx=index($0, file_downloaded)
#             if (idx > 0) {
#                 last_found=d0;
#                 }
#             }
#         }
#         END {if (last_found != "")
#             {
#                 print last_found
#                 last_found="";
#             }
#         }'  tesi/06_warcs/tmp.log.seeds_in_warc


# echo "11 12  14" | awk -v OFS=" " '{split($0,a," "); print a[1],a[2],a[3],a[4]}'



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
            ret_replace_octal_with_encoded_hex=${s1/\\$o/$r}
            s1=$ret_replace_octal_with_encoded_hex
        else
            break;
        fi
    done
    # echo $s2    # RETURN VALUE to function called like r=$(replace_octal_with_encoded_hex $s)
} # end replace_octal_with_encoded_hex



#replace_octal_with_encoded_hex "http://dspace.unical.it:8080/jspui/bitstream/10955/1768/1/FRATTARUOLO LUCA_MMMM.pdf"
#echo "ret_replace_octal_with_encoded_hex=$ret_replace_octal_with_encoded_hex"


# cd tmp

# echo "ACCESSO controllato a pagine dietro login di UNICATT"

# echo "Login"
# wget --save-cookies cookies.txt --keep-session-cookies --delete-after --post-data 'user=appsrv.docta.ssows&password=kMcydyT3QhqMhlQE4O1m!' https://login.unicatt.it/iam-fe/sso/login

# echo "Accesso a pagina di una teesi"
# #wget --load-cookies ./cookies.txt --delete-after --no-directories --warc-tempdir=. --user-agent='bncf' --page-requisites --output-file=./unicatt_access.log --warc-file=./page
# wget -qO- --load-cookies ./cookies.txt http://hdl.handle.net/10280/296 &> /dev/null


# # echo "Accesso a componenti"
# wget --load-cookies ~/Downloads/cookies.txt --no-directories --warc-tempdir=. --user-agent='bncf' --page-requisites --input-file=../tesi/02_seeds/2019_11_05_tesi_unicatt.seeds --output-file=./2019_11_05_tesi_unicatt.log --warc-file=./2019_11_05_tesi_unicatt

# cd ..



# 09/09/2020 Upload file to S3 storage
# File must be accompanied by .md5 (in same folder)

# file_to_upload=/home/argentino/magazzini_digitali/wayback/collections/collection_3/archive/harvest_AV/2020_01_26_tesi/2020_01_26_tesi_iulm.warc.gz 
# s3_path_filename=harvest/2020_01_26_tesi_iulm.warc.gz
# 34 mega, Tempo impiegato per il caricamento: 00:03:12.891

# file_to_upload=/home/argentino/magazzini_digitali/wayback/collections/collection_3/archive/harvest_AV/2020_01_26_tesi/2020_01_26_tesi_test_unige.warc.gz
# s3_path_filename=harvest/2020_01_26_tesi_test_unige.warc.gz
# 194 mega, Tempo impiegato per il caricamento: 00:05:09.776

# file_to_upload=/home/argentino/zip/2020_03_04_harvest.tar.gz 
# s3_path_filename=harvest/2020_03_04_harvest.tar.gz
# file_to_download_to=/home/argentino/Downloads/2020_03_04_harvest.tar.gz 


# ====================
# UPLOAD to S3
# Non controllare i certificati: -Dcom.amazonaws.sdk.disableCertChecking
# error 500: use  -Damazons3.scanner.retrynumber=12 -Damazons3.scanner.maxwaittime=3 
# java -Damazons3.scanner.retrynumber=12 -Damazons3.scanner.maxwaittime=3  -Dcom.amazonaws.sdk.disableCertChecking -cp "./bin/*" it.s3.s3clientMP.HighLevelMultipartUpload action=upload file_to_upload=$file_to_upload s3_keyname=s3_path_filename
# ====================

# ====================
# DOWNLOAD from S3
# Non controllare i certificati: -Dcom.amazonaws.sdk.disableCertChecking
# error 500: use  -Damazons3.scanner.retrynumber=12 -Damazons3.scanner.maxwaittime=3 
# action can be upload or download 

# java -Damazons3.scanner.retrynumber=12 -Damazons3.scanner.maxwaittime=3 -Dcom.amazonaws.sdk.disableCertChecking \
#     -cp "./bin/*" it.s3.s3clientMP.HighLevelMultipartUploadDownload \
#     action=download action=download \
#     file_to_upload=$file_to_upload \
#     file_to_download_to=$file_to_download_to \
#     s3_keyname=$s3_path_filename
    

# Genera md5 da controllare
# file_to_download_to_md5=$file_to_download_to".md5"
# file_to_download_to_md5_check=$file_to_download_to_md5".check"

# md5sum $file_to_download_to > $file_to_download_to_md5_check 


# Controllare che MD5 scaricato da S3 corrisonda ad MD5 generato dlocalmente dopo il download
# awk_command='
#     BEGIN    {
#         FS=" "; 
#     }
 
#     FILENAME == ARGV[1] {
#         md5_AR[$1] = $1;
#         print "->S3    md5 " $1
#         next;
#     }
#     {
#     if ($1 in md5_AR)
#         {
#         print "->CHECK md5 " $1 " matches " 
#         next
#         }
#     else
#         {
#         print "CHECK md5 " $1 " DOES NOT match"
#         }
#     }' 

# awk "$awk_command" $file_to_download_to_md5 $file_to_download_to_md5_check

# ====================



# + "action=upload|download "
# + "file_to_upload=source_filename (must have md5 associated file),"
# + "s3_keyname=S3_full_path_filename "
# + "file_download_to=local_destination_full_path_f

# action=download file_to_upload=/home/argentino/zip/2020_03_04_harvest.tar.gz file_to_download_to=/home/argentino/Downloads/2020_03_04_harvest.tar.gz s3_keyname=harvest/2020_03_04_harvest.tar.gz


# 1 e0bdfc5c51cc185f2bc12e73909ce5a9  2020_03_04_harvest.tar.gz
# 1 e0bdfc5c51cc185f2bc12e73909ce5a9  2020_03_04_harvest.tar.gz



#=========================
#Migrazione vecchi warcs

#Crea links 

# ln -s ../mods-available/solr.ini 20-solr.ini

# awk 'BEGIN{print "#!/bin/bash"}{print "ln -s "$3, $1}' tmp/archive.lst > tmp/create_links.sh
# echo "#!/bin/bash" > tmp/rename.sh
# echo "ln -s ../test.sh pippo2" >> tmp/rename.sh
# chmod +x tmp/create_links.sh



# Count records in warc
# awk '{if ($1 ~ /^WARC\/1.0/) print $1}' 2020_11_11_tesi_lumsa.warc | wc -l




