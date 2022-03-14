#$ -N MDTB_3dDeconvolve
#$ -q SEASHORE
#$ -pe smp 16
#$ -t 1-24
#$ -ckpt user
export OMP_NUM_THREADS=16
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(02 03 04 06 08 09 10 12 14 15 17 18 19 20 21 22 24 25 26 27 28 29 30 31)
echo subjects: ${subjects[@]}
echo total_subjects=${#subjects[@]}
subject="${subjects[$SGE_TASK_ID-1]}"
echo "Starting 3dDeconvolve on $subject"
cd /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-$subject/

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input $(find /Shared/lss_kahwang_hpc/data/MDTB/fmriprep/ -regex "/Shared/lss_kahwang_hpc/data/MDTB/fmriprep/sub-${subject}/\(ses-a1\|ses-a2\|ses-b1\|ses-b2\).*mask\.nii\.gz")

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(find /Shared/lss_kahwang_hpc/data/MDTB/fmriprep/ -regex "/Shared/lss_kahwang_hpc/data/MDTB/fmriprep/sub-${subject}/\(ses-a1\|ses-a2\|ses-b1\|ses-b2\).*desc-preproc_bold\.nii\.gz" -print0 | sort -z | xargs -r0) \
-mask combined_mask+tlrc.BRIK \
-polort A \
-censor censor.1D \
-ortvec nuisance.1D nuisance \
-local_times \
-num_stimts 25 \
-stim_times 1 spatialNavigation.1D.txt 'BLOCK(4.8)' -stim_label 1 spatialNavigation \
-stim_times 2 stroop.1D.txt 'BLOCK(1.6)' -stim_label 2 stroop \
-stim_times 3 arithmetic.1D.txt 'BLOCK(2.6)' -stim_label 3 arithmetic \
-stim_times 4 motorSequence.1D.txt 'BLOCK(4.6)' -stim_label 4 motorSequence \
-stim_times 5 nBack.1D.txt 'BLOCK(1.6)' -stim_label 5 nBack \
-stim_times 6 visualSearch.1D.txt 'BLOCK(1.6)' -stim_label 6 visualSearch \
-stim_times 7 checkerBoard.1D.txt 'BLOCK(1.6)' -stim_label 7 checkerBoard \
-stim_times 8 affective.1D.txt 'BLOCK(1.6)' -stim_label 8 affective \
-stim_times 9 ToM.1D.txt 'BLOCK(14.6)' -stim_label 9 ToM \
-stim_times 10 GoNoGo.1D.txt 'BLOCK(1)' -stim_label 10 GoNoGo \
-stim_times 11 emotional.1D.txt 'BLOCK(1.6)' -stim_label 11 emotional \
-stim_times 12 verbGeneration.1D.txt 'BLOCK(1.6)' -stim_label 12 verbGeneration \
-stim_times 13 actionObservation.1D.txt 'BLOCK(14)' -stim_label 13 actionObservation \
-stim_times 14 motorImagery.1D.txt 'BLOCK(30)' -stim_label 14 motorImagery \
-stim_times 15 nBackPic.1D.txt 'BLOCK(1.6)' -stim_label 15 nBackPic \
-stim_times 16 intervalTiming.1D.txt 'BLOCK(1.6)' -stim_label 16 intervalTiming \
-stim_times 17 CPRO.1D.txt 'BLOCK(7.3)' -stim_label 17 CPRO \
-stim_times 18 prediction.1D.txt 'BLOCK(4.8)' -stim_label 18 prediction \
-stim_times 19 romanceMovie.1D.txt 'BLOCK(30)' -stim_label 19 romanceMovie \
-stim_times 20 spatialMap.1D.txt 'BLOCK(4.8)' -stim_label 20 spatialMap \
-stim_times 21 emotionProcess.1D.txt 'BLOCK(1.6)' -stim_label 21 emotionProcess \
-stim_times 22 mentalRotation.1D.txt 'BLOCK(3)' -stim_label 22 mentalRotation \
-stim_times 23 natureMovie.1D.txt 'BLOCK(30)' -stim_label 23 natureMovie \
-stim_times 24 respAlt.1D.txt 'BLOCK(4.6)' -stim_label 24 respAlt \
-stim_times 25 landscapeMovie.1D.txt 'BLOCK(30)' -stim_label 25 landscapeMovie \
-iresp 1 spatialNavigation_FIR_MIN_block.nii.gz \
-iresp 2 stroop_FIR_MIN_block.nii.gz \
-iresp 3 arithmetic_FIR_MIN_block.nii.gz \
-iresp 4 motorSequence_FIR_MIN_block.nii.gz \
-iresp 5 nBack_FIR_MIN_block.nii.gz \
-iresp 6 visualSearch_FIR_MIN_block.nii.gz \
-iresp 7 checkerBoard_FIR_MIN_block.nii.gz \
-iresp 8 affective_FIR_MIN_block.nii.gz \
-iresp 9 ToM_FIR_MIN_block.nii.gz \
-iresp 10 GoNoGo_FIR_MIN_block.nii.gz \
-iresp 11 emotional_FIR_MIN_block.nii.gz \
-iresp 12 verbGeneration_FIR_MIN_block.nii.gz \
-iresp 13 actionObservation_FIR_MIN_block.nii.gz \
-iresp 14 motorImagery_FIR_MIN_block.nii.gz \
-iresp 15 nBackPic_FIR_MIN_block.nii.gz \
-iresp 16 intervalTiming_FIR_MIN_block.nii.gz \
-iresp 17 CPRO_FIR_MIN_block.nii.gz \
-iresp 18 prediction_FIR_MIN_block.nii.gz \
-iresp 19 romanceMovie_FIR_MIN_block.nii.gz \
-iresp 20 spatialMap_FIR_MIN_block.nii.gz \
-iresp 21 emotionProcess_FIR_MIN_block.nii.gz \
-iresp 22 mentalRotation_FIR_MIN_block.nii.gz \
-iresp 23 natureMovie_FIR_MIN_block.nii.gz \
-iresp 24 respAlt_FIR_MIN_block.nii.gz \
-iresp 25 landscapeMovie_FIR_MIN_block.nii.gz \
-num_glt 25 \
-gltsym "SYM: +1*spatialNavigation" -glt_label 1 spatialNavigation \
-gltsym "SYM: +1*stroop" -glt_label 2 stroop \
-gltsym "SYM: +1*arithmetic" -glt_label 3 arithmetic \
-gltsym "SYM: +1*motorSequence" -glt_label 4 motorSequence \
-gltsym "SYM: +1*nBack" -glt_label 5 nBack \
-gltsym "SYM: +1*visualSearch" -glt_label 6 visualSearch \
-gltsym "SYM: +1*checkerBoard" -glt_label 7 checkerBoard \
-gltsym "SYM: +1*affective" -glt_label 8 affective \
-gltsym "SYM: +1*ToM" -glt_label 9 ToM \
-gltsym "SYM: +1*GoNoGo" -glt_label 10 GoNoGo \
-gltsym "SYM: +1*emotional" -glt_label 11 emotional \
-gltsym "SYM: +1*verbGeneration" -glt_label 12 verbGeneration \
-gltsym "SYM: +1*actionObservation" -glt_label 13 actionObservation \
-gltsym "SYM: +1*motorImagery" -glt_label 14 motorImagery \
-gltsym "SYM: +1*nBackPic" -glt_label 15 nBackPic \
-gltsym "SYM: +1*intervalTiming" -glt_label 16 intervalTiming \
-gltsym "SYM: +1*CPRO" -glt_label 17 CPRO \
-gltsym "SYM: +1*prediction" -glt_label 18 prediction \
-gltsym "SYM: +1*romanceMovie" -glt_label 19 romanceMovie \
-gltsym "SYM: +1*spatialMap" -glt_label 20 spatialMap \
-gltsym "SYM: +1*emotionProcess" -glt_label 21 emotionProcess \
-gltsym "SYM: +1*mentalRotation" -glt_label 22 mentalRotation \
-gltsym "SYM: +1*natureMovie" -glt_label 23 natureMovie \
-gltsym "SYM: +1*respAlt" -glt_label 24 respAlt \
-gltsym "SYM: +1*landscapeMovie" -glt_label 25 landscapeMovie \
-rout \
-tout \
-bucket FIRmodel_MNI_stats_block \
-errts FIRmodel_errts_block.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text
