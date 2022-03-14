/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10031)
echo subjects: ${subjects[@]}
echo "Starting 3dDeconvolve on $subject"
cd /data/backed_up/shared/ThalHi_MRI_2020/3dDeconvolve/$subject/ 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input $(find /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/ -regex "/data/backed_up/shared/ThalHi_MRI_2020/fmriprep/sub-${subject}.*mask\.nii\.gz") 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(find /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/ -regex "/data/backed_up/shared/ThalHi_MRI_2020/fmriprep/$subject/.*desc-preproc_bold\.nii\.gz" -print0 \| sort -z \| xargs -r0) \
-mask combined_mask+tlrc.BRIK \
-polort A \
-censor censor.1D \
-ortvec nuisance.1D nuisance \
-local_times \
-num_stimts 0 \
-num_glt 0 \
-rout \
-tout \
-bucket FIRmodel_MNI_stats \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text