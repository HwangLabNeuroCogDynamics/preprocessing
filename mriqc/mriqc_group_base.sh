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

singularity run --cleanenv -B ${dataset_dir}:/data $singularity_path \
${bids_dir} \
${mriqc_dir} \
group \
--n_procs ${slots} --ants-nthreads ${slots} \
-w ${working_dir} \
OPTIONS

remove_localscratch_files $working_dir
