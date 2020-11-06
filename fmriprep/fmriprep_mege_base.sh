#!/bin/bash

# BASE SCRIPT
BASE_SCRIPT

dataset_dir=DATASET_DIR
slots=SLOTS
bids_dir=BIDS_DIR
singularity_path=SING_PATH
working_dir=WORK_DIR
freesurfer_lic=LIC_PATH
logs_dir=${dataset_dir}fmriprep/logs/
is_failed=false

echo dataset_dir: $dataset_dir
echo slots: $slots
echo bids_directory: $bids_dir
echo singularity_path: $singularity_path
echo working_directory: $working_dir
echo freesurfer_license: $freesurfer_lic

for subject in $subjects
do
  ( echo Starting fmriprep on $subject

  if [ -f ${dataset_dir}freesurfer/sub-${subject}/scripts/IsRunning.lh+rh ]; then
    rm ${dataset_dir}freesurfer/sub-${subject}/scripts/IsRunning.lh+rh
  fi

  # run fmriprep singularity container
  {
  singularity run --cleanenv -B $dataset_dir $singularity_path \
  $bids_dir \
  $dataset_dir \
  participant --participant_label $subject \
  --nthreads $slots --omp-nthreads $slots \
  -w $working_dir \
  --fs-license-file $freesurfer_lic \
  --skip-bids-validation \
  OPTIONS

  } ||
  {
    # when erorr is thrown
    is_failed=true
    if [ grep -Fxq "A process in the process pool was terminated abruptly while the future was running or pending."  ]; then
      echo $subject >> ${logs_dir}mem_failed_subjects.txt
    else
      echo $subject >> ${logs_dir}failed_subjects.txt
    fi
  }

  if [ "$is_failed" = false ]; then
    echo $subject >> ${logs_dir}completed_subjects.txt
  fi ) 1> "${logs_dir}${subject}.o" 2> "${logs_dir}${subject}.e" &
done
wait

#####End Compute Work#####
