#!/bin/bash
# SGE OPTIONS
SGE_OPTIONS

# BASE SCRIPT
BASE_SCRIPT

dataset_name=DATASET_NAME
dataset_dir=DATASET_DIR
slots=SLOTS

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
--mem $SLOTS \
--skip_bids_validation \
OPTIONS

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
  echo $subject >> ${logs_dir}completed_subjects.txt
fi
