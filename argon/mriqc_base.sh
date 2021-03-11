#!/bin/bash
# SGE OPTIONS
SGE_OPTIONS

# BASE SCRIPT
BASE_SCRIPT

dataset_dir=DATASET_DIR
mriqc_dir=MRIQC_DIR
slots=SLOTS
bids_dir=BIDS_DIR
singularity_path=/Shared/lss_kahwang_hpc/opt/mriqc/mriqc.simg
working_dir=WORK_DIR
is_failed=false
logs_dir=${mriqc_dir}logs/

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
  # when erorr is thrown
  is_failed=true
  if grep -Fq "A process in the process pool was terminated abruptly while the future was running or pending." $SGE_STDERR_PATH; then
    echo $subject >> ${logs_dir}mem_failed_subjects.txt
  elif ! grep -Fq $subject ${logs_dir}failed_subjects.txt; then
    echo $subject >> ${logs_dir}failed_subjects.txt
  fi
}

if [ "$is_failed" = false ]; then
  echo $subject >> ${logs_dir}completed_subjects.txt
fi

mv -u $SGE_STDOUT_PATH ${logs_dir}${subject}.o
mv -u $SGE_STDERR_PATH ${logs_dir}${subject}.e
remove_localscratch_files $working_dir
/bin/echo Finished on: `date`

#####End Compute Work#####
