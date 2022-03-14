/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10001 10002 10003 10004 10005 10006 10007 10008 10009 10010 10011 10012 10013 10014 10016 10017 10018 10019 10020 10021 10022 10023 10024 10025 10026 10027 10028 10029 10030 10031 10032 10033 10034 10035 10036 10037 10038 10039 10040 10041 10042 10043 10054 10059 10060 10061 10062 10063 10064 10065 10066 10068 10071 10073 10074 10076 10080 JH)
echo subjects: ${subjects[@]}
echo "Starting 3dDeconvolve on $subject"
cd /data/backed_up/shared/ThalHi_MRI_2020/3dDeconvolve/sub-$subject/ 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input $(find /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/ -regex "/data/backed_up/shared/ThalHi_MRI_2020/fmriprep/sub-$subject.*mask\.nii\.gz") 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(find /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/ -regex "/data/backed_up/shared/ThalHi_MRI_2020/fmriprep/sub-$subject/.*desc-preproc_bold\.nii\.gz" -print0 | sort -z | xargs -r0) \
-mask combined_mask+tlrc.BRIK \
-polort A \
-censor censor.1D \
-ortvec nuisance.1D nuisance \
-local_times \
-num_stimts 8 \
-stim_times 1 fcr.1D.txt-stim_label 1 fcr \
-stim_times 2 fpr.1D.txt-stim_label 2 fpr \
-stim_times 3 dcb.1D.txt-stim_label 3 dcb \
-stim_times 4 dcr.1D.txt-stim_label 4 dcr \
-stim_times 5 dpr.1D.txt-stim_label 5 dpr \
-stim_times 6 dpb.1D.txt-stim_label 6 dpb \
-stim_times 7 fcb.1D.txt-stim_label 7 fcb \
-stim_times 8 fpb.1D.txt-stim_label 8 fpb \
-iresp 1 fcr_FIR_MIN.nii.gz \
-iresp 2 fpr_FIR_MIN.nii.gz \
-iresp 3 dcb_FIR_MIN.nii.gz \
-iresp 4 dcr_FIR_MIN.nii.gz \
-iresp 5 dpr_FIR_MIN.nii.gz \
-iresp 6 dpb_FIR_MIN.nii.gz \
-iresp 7 fcb_FIR_MIN.nii.gz \
-iresp 8 fpb_FIR_MIN.nii.gz \
-num_glt 8 \
-gltsym "SYM: +1*fcr" -glt_label 1 fcr \
-gltsym "SYM: +1*fpr" -glt_label 2 fpr \
-gltsym "SYM: +1*dcb" -glt_label 3 dcb \
-gltsym "SYM: +1*dcr" -glt_label 4 dcr \
-gltsym "SYM: +1*dpr" -glt_label 5 dpr \
-gltsym "SYM: +1*dpb" -glt_label 6 dpb \
-gltsym "SYM: +1*fcb" -glt_label 7 fcb \
-gltsym "SYM: +1*fpb" -glt_label 8 fpb \
-rout \
-tout \
-bucket FIRmodel_MNI_stats \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text