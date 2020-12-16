/bin/echo Running on compute node: `hostname`.
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`



cd /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-${subject}/

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input $(find /Shared/lss_kahwang_hpc/data/MDTB/fmriprep/ -regex "/Shared/lss_kahwang_hpc/data/MDTB/fmriprep/sub-${subject}/\(ses-a1\|ses-a2\|ses-b1\|ses-b2\).*mask\.nii\.gz")

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(find /Shared/lss_kahwang_hpc/data/MDTB/fmriprep/ -regex "/Shared/lss_kahwang_hpc/data/MDTB/fmriprep/sub-${subject}/\(ses-a1\|ses-a2\|ses-b1\|ses-b2\).*desc-preproc_bold\.nii\.gz") \
-mask combined_mask+tlrc.BRIK \
-polort A \
-censor censor.1D \
-ortvec nuisance.1D nuisance \
-local_times \
-rout \
-tout \
-bucket FIRmodel_MNI_stats \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text
