#!/bin/bash

# BASE SCRIPT
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(20 24 25 26 27 28 29 30 31)
echo subjects: ${subjects[@]}

dataset_dir=/mnt/nfs/lss/lss_kahwang_hpc/data/MDTB/
slots=4
bids_dir=/mnt/nfs/lss/lss_kahwang_hpc/data/MDTB/BIDS/
singularity_path=/opt/fmriprep/fmriprep.simg
working_dir=/mnt/nfs/lss/lss_kahwang_hpc/data/MDTB/work/
freesurfer_lic=/opt/freesurfer/license.txt
logs_dir=${dataset_dir}fmriprep/logs/
is_failed=false

echo dataset_dir: $dataset_dir
echo slots: $slots
echo bids_directory: $bids_dir
echo singularity_path: $singularity_path
echo working_directory: $working_dir
echo freesurfer_license: $freesurfer_lic

for subject in "${subjects[@]}"
do  {
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
  
  } ||
  {
    # when error is thrown
    is_failed=true
    echo "$subject failed. Check logs for more information."
    
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    echo $subject >> ${logs_dir}failed_subjects.txt
  }
  ) 1> "${logs_dir}${subject}.o" 2> "${logs_dir}${subject}.e"

  if [ "$is_failed" = false ]; then
    echo "$subject successfully completed."
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    sed -i "/${subject}/d" ${logs_dir}completed_subjects.txt
    echo $subject >> ${logs_dir}completed_subjects.txt
  fi
  } &
done
wait

#####End Compute Work#####
