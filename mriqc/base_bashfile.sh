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
slots=SLOTS
bids_directory=BIDS_DIR
singularity_path=/Shared/lss_kahwang_hpc/opt/mriqc/mriqc.simg
working_directory=WORK_DIR

echo dataset_dir: $dataset_dir
echo slots: $slots
echo bids_directory: $bids_directory
echo singularity_path: $singularity_path
echo working_directory: $working_directory

echo Starting mriqc on $subject

mkdir $working_directory

singularity run --cleanenv \
-B ${dataset_directory}:/data ${singularity_path} \
${bids_directory} \
${mriqc_directory} \
group \
--n_procs ${slots} --ants-nthreads ${slots} \
-w ${working_directory}
OPTIONS
} ||
{
  remove_localscratch_files $working_directory
  if [ grep -Fxq "A process in the process pool was terminated abruptly while the future was running or pending." EFILE ]
  then
    echo $subject >> ${dataset_dir}mriqc/logs/mem_failed_subjects.txt
    exit 137
  else
    echo $subject >> ${dataset_dir}mriqc/logs/failed_subjects.txt
    exit 1
  fi
}
#####End Compute Work#####

remove_localscratch_files $working_directory
echo $subject >> ${dataset_dir}mriqc/logs/completed_subjects.txt

# singularity run --cleanenv \
# -B ${dataset_directory}:/data ${singularity_path} \
# ${bids_directory} \
# ${mriqc_directory} \
# participant --participant_label "${subjects[$SGE_TASK_ID-1]}" \
# --n_procs ${slots} --ants-nthreads ${slots} \
# -w ${working_directory}

#####End Compute Work#####

##todo: look into using scratch space, it's faster, and then move files back to
