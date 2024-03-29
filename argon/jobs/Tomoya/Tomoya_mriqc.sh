#!/bin/bash
# SGE 
#$ -N Tomoya_mriqc
#$ -q SEASHORE
#$ -pe smp 10
#$ -o /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.o
#$ -e /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.e
#$ -t 1-6
#$ -ckpt user
export OMP_NUM_THREADS=10

# BASE SCRIPT
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(01 02 03 04 05 06)
echo subjects: ${subjects[@]}
echo total_subjects=${#subjects[@]}
subject="${subjects[$SGE_TASK_ID-1]}"

dataset_dir=/Shared/lss_kahwang_hpc/data/Tomoya/
mriqc_dir=/Shared/lss_kahwang_hpc/data/Tomoya/mriqc/
slots=10
bids_dir=/Shared/lss_kahwang_hpc/data/Tomoya/BIDS/
singularity_path=/Shared/lss_kahwang_hpc/opt/mriqc/mriqc.simg
working_dir=/localscratch/Users/esorenson/${JOB_ID}_${SGE_TASK_ID}/
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
singularity run --cleanenv -B ${dataset_dir}:/data ${singularity_path} \
${bids_dir} \
${mriqc_dir} \
participant --participant_label ${subject} \
--n_procs ${slots} --ants-nthreads ${slots} \
-w ${working_dir} \

} ||
{
  # when error is thrown
  is_failed=true
  echo "$subject failed. Check logs for more information."
  
  sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
  echo $subject >> ${logs_dir}failed_subjects.txt
}

if [ "$is_failed" = false ]; then
  sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
  sed -i "/${subject}/d" ${logs_dir}completed_subjects.txt
  echo $subject >> ${logs_dir}completed_subjects.txt
fi

mv -u $SGE_STDOUT_PATH ${logs_dir}${subject}.o
mv -u $SGE_STDERR_PATH ${logs_dir}${subject}.e
/bin/echo Finished on: `date`
#####End Compute Work#####
