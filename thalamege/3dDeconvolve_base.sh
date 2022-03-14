# BASE SCRIPT
BASE_SCRIPT

dataset_dir=DATASET_DIR
mriqc_dir=MRIQC_DIR
slots=SLOTS
bids_dir=BIDS_DIR
singularity_path=/opt/afni/afni.sif
deconvolve_dir=${dataset_dir}3dDeconvolve/
logs_dir=${deconvolve_dir}logs/
is_failed=false

for subject in "${subjects[@]}"
do
  {
  echo Starting mriqc on $subject
  (
  echo Starting mriqc on $subject

    cd ${deconvolve_dir}sub-${subject}/

    singularity run --cleanenv /mnt/nfs/lss/lss_kahwang_hpc/opt/afni/afni.sif \
    3dmask_tool -input MASK_REGEX

    singularity run --cleanenv /mnt/nfs/lss/lss_kahwang_hpc/opt/afni/afni.sif \
    3dDeconvolve -input DATA_REGEX \
    -mask combined_mask+tlrc.BRIK \
    -polort A \
    -censor censor.1D \
    -ortvec nuisance.1D nuisance \
    -local_times \
    STIM_TIMES
    IRESP
    GLT_SYM
    -rout \
    -tout \
    -bucket FIRmodel_MNI_stats \
    -errts FIRmodel_errts.nii.gz \
    -noFDR \
    -nocout \
    -jobs $slots \
    -ok_1D_text
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

