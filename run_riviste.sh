#!/bin/bash
# ./run_riviste.sh > logs/riviste.log 2>&1
# nohup ./run_riviste.sh > logs/riviste.log 2>&1 &


#./run.sh --materiale=riviste --harrvest_from_override="2019-07-01" --jobs=5
# ./run.sh -m=riviste -f="2019-07-01" -j=3 --development
# --harrvest_from_override="2019-07-01"
#./run.sh --materiale=riviste --development  --jobs=3 --warc_block_size_override=1
./run.sh --ambiente=sviluppo --materiale=riviste --jobs=3 --concurrent_warc_jobs=3
# --development
