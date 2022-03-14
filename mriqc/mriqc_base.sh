#!/bin/bash
# SGE OPTIONS
SGE_OPTIONS

# Functions
remove_localscratch_files () {
  if [[ $1 =~ "localscratch" ]]; then
    rm  -r $1
  fi
}

# BASE SCRIPT
BASE_SCRIPT

dataset_dir=DATASET_DIR
mriqc_dir=MRIQC_DIR
slots=SLOTS
bids_dir=BIDS_DIR
singularity_path=/Shared/lss_kahwang_hpc/opt/mriqc/mriqc.simg
working_dir=WORK_DIR

echo dataset_dir: $dataset_dir
echo mriqc_dir: $mriqc_dir
echo slots: $slots
echo bids_directory: $bids_dir
echo singularity_path: $singularity_path
echo working_directory: $working_dir

echo Starting mriqc on $subject

mkdir $working_dir
if [[ $bids_dir =~ "/Dedicated/inc_data/" ]]; then
  cp -r ${bids_dir}sub-${subject} $working_dir
  cp ${bids_dir}dataset_description.json $working_dir
  bids_dir=$working_dir
fi

{
singularity run --cleanenv -B ${dataset_dir}:/data $singularity_path \
${bids_dir} \
${mriqc_dir} \
participant --participant_label ${subject} \
--n_procs ${slots} --ants-nthreads ${slots} \
-w ${working_dir} \
OPTIONS
} ||
{
  remove_localscratch_files $working_dir
  if [ grep -Fxq "A process in the process pool was terminated abruptly while the future was running or pending." EFILE ]
  then
    echo $subject >> ${mriqc_dir}logs/mem_failed_subjects.txt
    exit 137
  else
    echo $subject >> ${mriqc_dir}logs/failed_subjects.txt
    exit 1
  fi
}
#####End Compute Work#####

remove_localscratch_files $working_dir
echo $subject >> ${mriqc_dir}logs/completed_subjects.txt
