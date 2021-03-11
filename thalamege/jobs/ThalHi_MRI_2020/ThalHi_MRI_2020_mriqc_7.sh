#!/bin/bash

# BASE SCRIPT
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10021 10022 10024)
echo subjects: ${subjects[@]}

dataset_dir=/data/backed_up/shared/ThalHi_MRI_2020
mriqc_dir=/data/backed_up/shared/ThalHi_MRI_2020mriqc/
slots=16
bids_dir=/data/backed_up/shared/ThalHi_MRI_2020BIDS/
singularity_path=/opt/mriqc/mriqc.simg
working_dir=/data/backed_up/shared/ThalHi_MRI_2020work/
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
