/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10043)
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
-num_stimts 8 \
-stim_times 1 fpr.1D.txt-stim_label 1 fpr \
-stim_times 2 fpb.1D.txt-stim_label 2 fpb \
-stim_times 3 fcr.1D.txt-stim_label 3 fcr \
-stim_times 4 dcr.1D.txt-stim_label 4 dcr \
-stim_times 5 dcb.1D.txt-stim_label 5 dcb \
-stim_times 6 fcb.1D.txt-stim_label 6 fcb \
-stim_times 7 dpr.1D.txt-stim_label 7 dpr \
-stim_times 8 dpb.1D.txt-stim_label 8 dpb \
-iresp 1 fpr_FIR_MIN.nii.gz \
-iresp 2 fpb_FIR_MIN.nii.gz \
-iresp 3 fcr_FIR_MIN.nii.gz \
-iresp 4 dcr_FIR_MIN.nii.gz \
-iresp 5 dcb_FIR_MIN.nii.gz \
-iresp 6 fcb_FIR_MIN.nii.gz \
-iresp 7 dpr_FIR_MIN.nii.gz \
-iresp 8 dpb_FIR_MIN.nii.gz \
-num_glt 8 \
-gltsym "SYM: +1*fpr" -glt_label 1 fpr \
-gltsym "SYM: +1*fpb" -glt_label 2 fpb \
-gltsym "SYM: +1*fcr" -glt_label 3 fcr \
-gltsym "SYM: +1*dcr" -glt_label 4 dcr \
-gltsym "SYM: +1*dcb" -glt_label 5 dcb \
-gltsym "SYM: +1*fcb" -glt_label 6 fcb \
-gltsym "SYM: +1*dpr" -glt_label 7 dpr \
-gltsym "SYM: +1*dpb" -glt_label 8 dpb \
-rout \
-tout \
-bucket FIRmodel_MNI_stats \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text