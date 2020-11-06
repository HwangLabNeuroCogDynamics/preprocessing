#!/bin/bash

# Base script
BASE_SCRIPT

dataset_dir=DATASET_DIR
logs_dir=${dataset_dir}Raw/logs/
is_failed=false

for subject in $subjects
do
  (
  {
  # run heudiconv singularity container
  singularity run -B /data:/data/ /data/backed_up/shared/bin/heudiconv_0.8.0.sif \
  -d ${dataset_dir}Raw/${subject}/SCANS/*/DICOM/*.dcm \
  -o ${dataset_dir}BIDS \
  -f /data/backed_up/shared/bin/heudiconv/heuristics/convertall.py -s ${subject} -c none --overwrite
  } ||
  {
  # when erorr is thrown
  is_failed=true
  if ! grep -Fq $subject ${logs_dir}failed_subjects.txt; then
    echo $subject >> ${logs_dir}failed_subjects.txt
  fi
  }

  if [ "$is_failed" = false ]; then
    echo $subject >> ${logs_dir}completed_subjects.txt
  fi
  ) 1> "${logs_dir}${subject}.o" 2> "${logs_dir}${subject}.e" &
done
wait
