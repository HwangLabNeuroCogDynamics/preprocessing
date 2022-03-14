/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subject=10054
echo "Starting 3dDeconvolve on $subject"
cd /data/backed_up/shared/ThalHi_MRI_2020/3dDeconvolve/sub-$subject/ 

singularity run --cleanenv /mnt/nfs/lss/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input $(find /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/ -regex "/data/backed_up/shared/ThalHi_MRI_2020/fmriprep/sub-${subject}.*mask\.nii\.gz") 

singularity run --cleanenv /mnt/nfs/lss/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(ls /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/sub-${subject}_task-ThalHi_run-*space-MNI152NLin2009cAsym_desc-preproc_bold*.nii.gz | sort -V) \
-mask combined_mask+tlrc.BRIK \
-polort A \
-censor censor.1D \
-ortvec nuisance.1D nuisance \
-local_times \
-num_stimts 8 \
-stim_times 1 dpb.1D.txt-stim_label 1 dpb \
-stim_times 2 dcb.1D.txt-stim_label 2 dcb \
-stim_times 3 dpr.1D.txt-stim_label 3 dpr \
-stim_times 4 fpr.1D.txt-stim_label 4 fpr \
-stim_times 5 fpb.1D.txt-stim_label 5 fpb \
-stim_times 6 fcb.1D.txt-stim_label 6 fcb \
-stim_times 7 fcr.1D.txt-stim_label 7 fcr \
-stim_times 8 dcr.1D.txt-stim_label 8 dcr \
-iresp 1 dpb_FIR_MIN.nii.gz \
-iresp 2 dcb_FIR_MIN.nii.gz \
-iresp 3 dpr_FIR_MIN.nii.gz \
-iresp 4 fpr_FIR_MIN.nii.gz \
-iresp 5 fpb_FIR_MIN.nii.gz \
-iresp 6 fcb_FIR_MIN.nii.gz \
-iresp 7 fcr_FIR_MIN.nii.gz \
-iresp 8 dcr_FIR_MIN.nii.gz \
-num_glt 8 \
-gltsym "SYM: +1*dpb" -glt_label 1 dpb \
-gltsym "SYM: +1*dcb" -glt_label 2 dcb \
-gltsym "SYM: +1*dpr" -glt_label 3 dpr \
-gltsym "SYM: +1*fpr" -glt_label 4 fpr \
-gltsym "SYM: +1*fpb" -glt_label 5 fpb \
-gltsym "SYM: +1*fcb" -glt_label 6 fcb \
-gltsym "SYM: +1*fcr" -glt_label 7 fcr \
-gltsym "SYM: +1*dcr" -glt_label 8 dcr \
-rout \
-tout \
-bucket FIRmodel_MNI_stats_cues \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text