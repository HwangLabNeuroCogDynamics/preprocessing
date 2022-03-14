  #!/bin/bash
subject_dir='/Shared/lss_kahwang_hpc/data/MDTB/fmriprep/sub-02/'
output_path='/Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-02/'

cd '/Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-02/'

singularity run --cleanenv \
/Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input ${subject_dir}ses-[ab][12]/func/*mask.nii.gz \
-union

singularity run --cleanenv \
/Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(ls ${subject_dir}ses-[ab][12]/func/*desc-preproc_bold.nii.gz | sort -V) \
-mask combined_mask+tlrc.BRIK \
-polort A \
-ortvec ${output_path}nuisance.1D nuisance \
-local_times \
-rout \
-tout \
-bucket ${output_path}sub-02_FIRmodel_MNI_stats \
-errts ${output_path}sub-02_FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 4 \
-ok_1D_text
