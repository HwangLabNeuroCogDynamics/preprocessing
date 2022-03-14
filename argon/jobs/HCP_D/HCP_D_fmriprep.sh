#!/bin/bash
# SGE 
#$ -N HCP_D_fmriprep
#$ -q SEASHORE
#$ -pe smp 8
#$ -o /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.o
#$ -e /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.e
#$ -t 1-2
#$ -ckpt user
#$ -l mt=16G
export OMP_NUM_THREADS=8

# BASE SCRIPT
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(1410933 1458153)
echo subjects: ${subjects[@]}
echo total_subjects=${#subjects[@]}
subject="${subjects[$SGE_TASK_ID-1]}"

FMRIPREP='fmriprep/'
FREESURFER='freesurfer/'
BIDS='BIDS/'

dataset_name=HCP_D
dataset_dir=/Shared/lss_kahwang_hpc/data/HCP_D/
slots=8
bids_dir=/Dedicated/inc_data/HCP_D/rawdata/
singularity_path=/Shared/lss_kahwang_hpc/opt/${FMRIPREP}fmriprep-20.1.1.simg
working_dir=/localscratch/Users/esorenson/${JOB_ID}_${SGE_TASK_ID}/
is_highthroughput=IS_HT

freesurfer_lic=/Shared/lss_kahwang_hpc/opt/${FREESURFER}license.txt
fmriprep_dir=${dataset_dir}${FMRIPREP}
freesurfer_dir=${dataset_dir}${FREESURFER}
freesurfer_sub_dir=${dataset_dir}${FREESURFER}sub-${subject}/
fmriprep_sub_dir=${dataset_dir}${FMRIPREP}sub-${subject}/
working_dataset_dir=${working_dir}${dataset_name}/
working_bids_dir=${working_dataset_dir}${BIDS}
working_fmriprep_dir=${working_dataset_dir}${FMRIPREP}
working_freesurfer_dir=${working_dataset_dir}${FREESURFER}
logs_dir=${fmriprep_dir}logs/
is_failed=false

echo dataset_dir: $dataset_dir
echo slots: $slots
echo bids_directory: $bids_dir
echo singularity_path: $singularity_path
echo working_directory: $working_dir
echo working_dataset_dir: $working_dataset_dir
echo working_fmriprep_dir: $working_fmriprep_dir
echo working_freesurfer_dir: $working_freesurfer_dir
echo freesurfer_license: $freesurfer_lic

mkdir $working_dir
mkdir $working_dataset_dir
mkdir $working_bids_dir
mkdir $working_fmriprep_dir
mkdir $working_freesurfer_dir

echo Starting fmriprep on $subject

if [[ $bids_dir =~ "/Dedicated/inc_data/" ]]; then
  cp -r ${bids_dir}sub-${subject}/ $working_bids_dir
  ls $working_bids_dir
  cd ${working_bids_dir}sub-${subject}
  cd ${working_bids_dir}sub-${subject}/fmap/
  for file in $(ls *fieldmap*)
  do
      mv "${file}" "${file/fieldmap/epi}"
  done

  for file in $(ls *.json)
  do
      intendedFile1=''
      intendedFile2=''
      if [[ $file =~ 'AP' ]]; then
        echo "This is AP $file"
        intendedFile1="func/$file"
        intendedFile2="func/${file/AP/PA}"
      else
        echo "This is PA $file"
        intendedFile1="func/$file"
        intendedFile2="func/${file/PA/AP}"
      fi
      intendedFile1=${intendedFile1/epi.json/bold.nii.gz}
      intendedFile2=${intendedFile2/epi.json/bold.nii.gz}
      intendedFile1=${intendedFile1/acq/task}
      intendedFile2=${intendedFile2/acq/task}
      echo $intendedFile1 $intendedFile2
      if [[ $file =~ acq-emotion_dir-AP ]]; then
        sed -i "s|\"$intendedFile1\"|\"$intendedFile2\"|g" $file
      elif [[ $file =~ acq-emotion_dir-PA ]]; then
        echo 'Do nothing'
      else
        sed -i "s|\"$intendedFile1\"|[\"$intendedFile1\", \"$intendedFile2\"]|g" $file
        less $file
      fi
  done

  echo $bids_dir
fi

# copy bids dir to working dir


# copy fmriprep dir to working dir if exists
if [ -d ${fmriprep_sub_dir} ]; then
  cp -r $fmriprep_sub_dir $working_fmriprep_dir
fi

# copy freesurfer dir to working dir if exists, renove IsRunning.lh
if [ -d ${freesurfer_sub_dir} ]; then
  rm ${freesurfer_sub_dir}scripts/*IsRunning*
  cp -r $freesurfer_sub_dir $working_freesurfer_dir
fi

# run fmriprep singularity container
{
singularity run --cleanenv -B $working_dataset_dir $singularity_path \
$working_bids_dir \
$working_dataset_dir \
participant --participant_label $subject \
--nthreads $slots --omp-nthreads $slots \
-w $working_dir \
--fs-license-file ${freesurfer_lic} \
--skip-bids-validation \
--mem 16 \


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

# move fmriprep, freesurfer, and stdout/err files to dataset dir and delete
# working dir if on localscratch
cp -r $working_fmriprep_dir $dataset_dir
cp -r $working_freesurfer_dir $dataset_dir

/bin/echo Finished on: `date`
mv -u $SGE_STDOUT_PATH ${logs_dir}${subject}.o
mv -u $SGE_STDERR_PATH ${logs_dir}${subject}.e
if [[ $working_dir =~ "localscratch" ]]; then
  rm  -r $working_dir
fi


#####End Compute Work#####
