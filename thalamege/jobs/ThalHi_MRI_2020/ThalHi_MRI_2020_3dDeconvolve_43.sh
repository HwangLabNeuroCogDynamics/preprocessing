/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(10001 10002 10003 10004 10005 10006 10007 10008 10009 10010 10011 10012 10013 10014 10016 10017 10018 10019 10020 10021 10022 10023 10024 10025 10026 10027 10028 10029 10030 10031 10032 10033 10034 10035 10036 10037 10038 10039 10040 10041 10042 10043 10044 10054 10055 10057 10058 10059 10060 10061 10062 10063 10064 10065 10066 10068 10069 10071 10072 10073 10074 10076 10077 10080 10162 JH)
echo subjects: ${subjects[@]}
echo "Starting 3dDeconvolve on $subject"
cd /data/backed_up/shared/ThalHi_MRI_2020/3dDeconvolve/sub-$subject/ 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input $(find /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/ -regex "/data/backed_up/shared/ThalHi_MRI_2020/fmriprep/sub-$subject.*mask\.nii\.gz") 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(find /data/backed_up/shared/ThalHi_MRI_2020/fmriprep/ -regex "/data/backed_up/shared/ThalHi_MRI_2020/fmriprep/sub-$subject/.**bold.nii.gz" -print0 | sort -z | xargs -r0) \
-mask combined_mask+tlrc.BRIK \
-polort A \
-censor censor.1D \
-ortvec nuisance.1D nuisance \
-local_times \
-num_stimts 3 \
-stim_times 1 Stay.1D.txt-stim_label 1 Stay \
-stim_times 2 IDS.1D.txt-stim_label 2 IDS \
-stim_times 3 EDS.1D.txt-stim_label 3 EDS \
-iresp 1 Stay_FIR_MIN.nii.gz \
-iresp 2 IDS_FIR_MIN.nii.gz \
-iresp 3 EDS_FIR_MIN.nii.gz \
-num_glt 3 \
-gltsym "SYM: +1*Stay" -glt_label 1 Stay \
-gltsym "SYM: +1*IDS" -glt_label 2 IDS \
-gltsym "SYM: +1*EDS" -glt_label 3 EDS \
-rout \
-tout \
-bucket FIRmodel_MNI_stats \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 4 \
-ok_1D_text