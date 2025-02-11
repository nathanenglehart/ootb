#!/bin/bash

set -ex

# py dependencies are: odfpy

#python_env=/home/nath/python_environments/yolo_zs_1/bin/python
python_env=/home/nath/venv/bin/python
r_env=Rscript # is there another way I can do this?

# woman is getting all messed up here
# (1) get sample of instagram data
#$python_env 001_build_data_sample.py --input_ods_fpath=./representatives_118_data.ods --input_ods_sheet_name=ig_118 --input_dir_path=/media/data3/images/ig --output_fpath=./ig_data_sample_metadata.csv --verbose 
#$python_env 001_build_data_sample.py --input_ods_fpath=./representatives_118_data.ods --input_ods_sheet_name=ig_118 --input_dir_path=/media/nath/Seagate/images/ig --output_fpath=./ig_data_sample_metadata.csv --verbose 

# (2) run yolow to detect firearms in guns and videos
#$python_env 002_yolow.py --input_fpath=./ig_data_sample_metadata.csv --output_fpath=./df_yolow.pkl --verbose --testing_mode
#$python_env 002_yolow.py --input_fpath=./ig_data_sample_metadata.csv --output_fpath=./df_yolow.pkl --verbose 

# (3) intermediate steps
#$python_env 003_google_analytics.py # doesn't automatically work; needs manual adjustment; fix this

# (4) merge and clean
#$python_env 004_testing.py --input_fpath=./df_yolow.pkl --verbose
#$python_env 004_word2vec.py
$r_env 004_word2vec.r

# (5) get analytics
#$r_env 005_testing.r
