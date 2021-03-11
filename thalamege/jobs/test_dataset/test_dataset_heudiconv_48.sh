#!/bin/bash

# Base script
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10005 10006)
echo subjects: ${subjects[@]}

dataset_dir=/data/backed_up/shared/test_dataset/
conversion_script=thalhi.py

run_heudiconv_sub () {
  subject=$1
  dataset_dir=$2
  conversion_script=$3
  bids_dir=${dataset_dir}BIDS/
  logs_dir=${dataset_dir}Raw/logs/

  echo Starting heudiconv on $subject
  ({
    echo Starting heudiconv on $subject
    is_failed=false

    singularity run -B /data:/data/ /data/backed_up/shared/bin/heudiconv_0.8.0.sif \
    -d ${dataset_dir}Raw/{subject}/SCANS/*/DICOM/*.dcm \
    -o $bids_dir \
    -b \
    -f /data/backed_up/shared/bin/heudiconv/heuristics/${conversion_script} -s $subject -c dcm2niix --overwrite
  } ||
  {
    # when erorr is thrown
    is_failed=true
    if ! grep -Fq $subject ${logs_dir}failed_subjects.txt; then
      echo $subject >> ${logs_dir}failed_subjects.txt
    fi
  }

  if [ "$is_failed" = false ]; then
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    sed -i "/${subject}/d" ${logs_dir}completed_subjects.txt
    echo $subject >> ${logs_dir}completed_subjects.txt
  fi
  ) 1> "${logs_dir}${subject}.o" 2> "${logs_dir}${subject}.e"

  if [ "$is_failed" = true ]; then
    echo "heudiconv for $subject failed. Check logs for more information."
  else
    echo "heudiconv for $subject successfully completed."
  fi
}


echo 'Running heudiconv asynchronously. It might be a while.'
for subject in "${subjects[@]}"; do
  run_heudiconv_sub $subject $dataset_dir $conversion_script &
done
wait
