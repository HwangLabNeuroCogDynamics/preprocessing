/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10027 10028 10029 10030)
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
-num_stimts 3 \
-stim_times 1 Stay.1D.txt-stim_label 1 Stay \
-stim_times 2 EDS.1D.txt-stim_label 2 EDS \
-stim_times 3 IDS.1D.txt-stim_label 3 IDS \
-iresp 1 Stay_FIR_MIN.nii.gz \
-iresp 2 EDS_FIR_MIN.nii.gz \
-iresp 3 IDS_FIR_MIN.nii.gz \
-num_glt 3 \
-gltsym "SYM: +1*Stay" -glt_label 1 Stay \
-gltsym "SYM: +1*EDS" -glt_label 2 EDS \
-gltsym "SYM: +1*IDS" -glt_label 3 IDS \
-rout \
-tout \
-bucket FIRmodel_MNI_stats \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text