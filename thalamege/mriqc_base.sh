#!/bin/bash

# BASE SCRIPT
BASE_SCRIPT

dataset_dir=DATASET_DIR
mriqc_dir=MRIQC_DIR
slots=SLOTS
bids_dir=BIDS_DIR
singularity_path=/opt/mriqc/mriqc.simg
working_dir=WORK_DIR
logs_dir=${dataset_dir}mriqc/logs/
is_finished=false

echo dataset_dir: $dataset_dir
echo mriqc_dir: $mriqc_dir
echo bids_dir: $bids_dir
echo singularity_path: $singularity_path
echo working_dir: $working_dir
echo logs_dir: $logs_dir

echo Starting mriqc asynchronously.

for subject in "${subjects[@]}"
do
  {
  echo Starting mriqc on $subject
  (
  echo Starting mriqc on $subject

  # run fmriprep singularity container
  {
    singularity run --cleanenv -B /data/:/data $singularity_path \
    $bids_dir \
    $mriqc_dir \
    participant --participant_label ${subject} \
    --n_procs ${slots} --ants-nthreads ${slots} \
    -w ${working_dir} \
    OPTIONS

    is_finished=true
  } ||
  {
    echo "Error when running mriqc"
  }
  ) 1> "${logs_dir}${subject}.o" 2> "${logs_dir}${subject}.e"

  if [ "$is_finished" = true ]; then
    echo "$subject successfully completed."
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    sed -i "/${subject}/d" ${logs_dir}completed_subjects.txt
    echo $subject >> ${logs_dir}completed_subjects.txt
  else
    echo "$subject failed. Check logs for more information."
    # when error is thrown
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    echo $subject >> ${logs_dir}failed_subjects.txt
  fi
  } &
done
wait

#####End Compute Work#####
