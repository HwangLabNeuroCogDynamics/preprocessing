#!/bin/bash

# Base script
BASE_SCRIPT

dataset_dir=DATASET_DIR
conversion_script=CONVERSION_SCRIPT
post_conv_script=POST_CONV_SCRIPT

run_heudiconv_sub () {
  subject=$1
  dataset_dir=$2
  conversion_script=$3
  post_conv_script=$4
  bids_dir=${dataset_dir}BIDS/
  logs_dir=${dataset_dir}Raw/logs/
  is_finished=false

  echo Starting heudiconv on $subject
  ({
    echo Starting heudiconv on $subject

    singularity run -B /data:/data/ /data/backed_up/shared/bin/heudiconv_0.8.0.sif \
    -d ${dataset_dir}Raw/{subject}/SCANS/*/DICOM/*.dcm \
    -o $bids_dir \
    -b \
    -f /data/backed_up/shared/bin/heudiconv/heuristics/${conversion_script} -s $subject -c dcm2niix --overwrite

    python $post_conv_script $subject
    is_finished=true
  } ||
  {
    # when erorr is thrown
    echo "Error when running heudiconv"
  }
  ) 1> "${logs_dir}${subject}.o" 2> "${logs_dir}${subject}.e"

  if [ "$is_finished" = true ]; then
    echo "heudiconv for $subject successfully completed."
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    sed -i "/${subject}/d" ${logs_dir}completed_subjects.txt
    echo $subject >> ${logs_dir}completed_subjects.txt
  else
    echo "heudiconv for $subject failed. Check logs for more information."
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    echo $subject >> ${logs_dir}failed_subjects.txt
  fi
}


echo 'Running heudiconv asynchronously. It might be a while.'
for subject in "${subjects[@]}"; do
  run_heudiconv_sub $subject $dataset_dir $conversion_script $post_conv_script &
done
wait
