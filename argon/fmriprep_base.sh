#!/bin/bash
# SGE OPTIONS
SGE_OPTIONS

# BASE SCRIPT
BASE_SCRIPT

FMRIPREP='fmriprep/'
FREESURFER='freesurfer/'
BIDS='BIDS/'

dataset_name=DATASET_NAME
dataset_dir=DATASET_DIR
slots=SLOTS
bids_dir=BIDS_DIR
singularity_path=/Shared/lss_kahwang_hpc/opt/${FMRIPREP}fmriprep-20.1.1.simg
use_localscratch=true

freesurfer_lic=/Shared/lss_kahwang_hpc/opt/${FREESURFER}license.txt
fmriprep_dir=${dataset_dir}${FMRIPREP}
freesurfer_dir=${dataset_dir}${FREESURFER}
freesurfer_sub_dir=${dataset_dir}${FREESURFER}sub-${subject}/
fmriprep_sub_dir=${dataset_dir}${FMRIPREP}sub-${subject}/

if [ "$use_localscratch" = true]; then
  working_dataset_dir=${TMPDIR}/
  working_dir=${TMPDIR}/work/
  working_bids_dir=${TMPDIR}/${BIDS}
  working_fmriprep_dir=${TMPDIR}/${FMRIPREP}
  working_freesurfer_dir=${TMPDIR}/${FREESURFER}
else
  working_dataset_dir=${dataset_dir}
  working_dir=${dataset_dir}work/
  working_bids_dir=${dataset_dir}${BIDS}
  working_fmriprep_dir=${dataset_dir}${FMRIPREP}
  working_freesurfer_dir=${dataset_dir}${FREESURFER}
fi

logs_dir=${fmriprep_dir}logs/
is_failed=false

echo dataset_dir: $dataset_dir
echo slots: $slots
echo bids_directory: $bids_dir
echo singularity_path: $singularity_path
echo temp_dir: $TMPDIR
echo working_fmriprep_dir: $working_fmriprep_dir
echo working_freesurfer_dir: $working_freesurfer_dir
echo freesurfer_license: $freesurfer_lic


mkdir $working_dir
mkdir $working_dataset_dir
mkdir $working_bids_dir
mkdir $working_fmriprep_dir
mkdir $working_freesurfer_dir

echo Starting fmriprep on $subject

# high throughput-jobs must copy over data to work locally
if [ "$use_localscratch" = true ]; then

  # copy subject BIDS data to working dir
  cp -r ${bids_dir}sub-${subject}/ $working_bids_dir

  # special case for HCP_D data
  if [[ $bids_dir =~ "/Dedicated/inc_data/HCP_D" ]]; then
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
  fi

  # copy fmriprep dir to working dir if exists
  if [ -d ${fmriprep_sub_dir} ]; then
    cp -r $fmriprep_sub_dir $working_fmriprep_dir
  fi

  # copy freesurfer dir to working dir if exists
  if [ -d ${freesurfer_sub_dir} ]; then
    cp -r $freesurfer_sub_dir $working_freesurfer_dir
  fi
fi

if [ -d ${freesurfer_sub_dir} ]; then
  rm ${freesurfer_sub_dir}scripts/*IsRunning*
fi


{
singularity run --cleanenv -B $working_dataset_dir $singularity_path \
$working_bids_dir \
$working_dataset_dir \
participant --participant_label $subject \
--nthreads $slots --omp-nthreads $slots \
-w $working_dir \
--fs-license-file ${freesurfer_lic} \
--mem $slots \
--skip_bids_validation \
OPTIONS

} ||
{
  # when error is thrown
  is_failed=true
  if grep -Fq "A process in the process pool was terminated abruptly while the future was running or pending." $SGE_STDERR_PATH; then
    sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
    echo $subject >> ${logs_dir}mem_failed_subjects.txt
  elif ! grep -Fq $subject ${logs_dir}failed_subjects.txt; then
    sed -i "/${subject}/d" ${logs_dir}mem_failed_subjects.txt
    echo $subject >> ${logs_dir}failed_subjects.txt
  fi
}

if [ "$is_failed" = false ]; then
  sed -i "/${subject}/d" ${logs_dir}mem_failed_subjects.txt
  sed -i "/${subject}/d" ${logs_dir}failed_subjects.txt
  sed -i "/${subject}/d" ${logs_dir}completed_subjects.txt
  echo $subject >> ${logs_dir}completed_subjects.txt
fi

# move fmriprep, freesurfer, and stdout/err files to dataset dir
cp -r $working_dir $dataset_dir
cp -r $working_fmriprep_dir $dataset_dir
cp -r $working_freesurfer_dir $dataset_dir

mv -u $SGE_STDOUT_PATH ${logs_dir}${subject}.o
mv -u $SGE_STDERR_PATH ${logs_dir}${subject}.e
/bin/echo Finished on: `date`
#####End Compute Work#####
