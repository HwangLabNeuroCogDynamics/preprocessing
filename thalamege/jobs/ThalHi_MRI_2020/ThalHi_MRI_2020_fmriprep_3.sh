#!/bin/bash

# BASE SCRIPT
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10029 10030)
echo subjects: ${subjects[@]}

dataset_dir=/data/backed_up/shared/ThalHi_MRI_2020/
slots=16
bids_dir=/data/backed_up/shared/ThalHi_MRI_2020/BIDS/
singularity_path=/opt/fmriprep/fmriprep.simg
working_dir=/data/backed_up/shared/ThalHi_MRI_2020/work/
freesurfer_lic=/opt/freesurfer/license.txt
logs_dir=${dataset_dir}fmriprep/logs/
is_finished=false

echo dataset_dir: $dataset_dir
echo slots: $slots
echo bids_directory: $bids_dir
echo singularity_path: $singularity_path
echo working_directory: $working_dir
echo freesurfer_license: $freesurfer_lic

for subject in "${subjects[@]}"
do
  {
  echo Starting fmriprep on $subject
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
  

  is_finished=true
  } ||
  {
    # when error is thrown
    echo "Error when running fmriprep"
  }
  ) 1> "${logs_dir}${subject}.o" 2> "${logs_dir}${subject}.e"

  if [ "$is_finished" = true ]; then
    echo "$subject successfully completed."
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    sed -i "/${subject}/d" ${logs_dir}mem_failed_subjects.txt
    sed -i "/${subject}/d" ${logs_dir}completed_subjects.txt
    echo $subject >> ${logs_dir}completed_subjects.txt
  else
    echo "$subject failed. Check logs for more information."
    # when error is thrown
    if [ grep -Fxq "A process in the process pool was terminated abruptly while the future was running or pending." "${logs_dir}${subject}.o" ]; then
      sed -i "/${subject}/d" ${logs_dir}mem_failed_subjects.txt
      echo $subject >> ${logs_dir}mem_failed_subjects.txt
    else
      sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
      echo $subject >> ${logs_dir}failed_subjects.txt
    fi
  fi
  } &
done
wait

#####End Compute Work#####
