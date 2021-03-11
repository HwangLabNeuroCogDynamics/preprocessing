#$ -N MDTB_3dDeconvolve
#$ -q all.q
#$ -pe smp 16
#$ -o /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.o
#$ -e /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.e
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
cd /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/$subject/ 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dmask_tool -input $(find /Shared/lss_kahwang_hpc/data/MDTB/fmriprep/ -regex "/Shared/lss_kahwang_hpc/data/MDTB/fmriprep/sub-${subject}/\(ses-a1\|ses-a2\|ses-b1\|ses-b2\).*mask\.nii\.gz") 

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dDeconvolve -input $(find /Shared/lss_kahwang_hpc/data/MDTB/fmriprep/ -regex "/Shared/lss_kahwang_hpc/data/MDTB/fmriprep/$subject/\(ses-a1\|ses-a2\|ses-b1\|ses-b2\).*desc-preproc_bold\.nii\.gz" -print0 \| sort -z \| xargs -r0) \
-mask combined_mask+tlrc.BRIK \
-polort A \
-censor censor.1D \
-ortvec nuisance.1D nuisance \
-local_times \
-num_stimts 27 \
-stim_times 1 instruct.1D.txt-stim_label 1 instruct \
-stim_times 2 spatialNavigation.1D.txt-stim_label 2 spatialNavigation \
-stim_times 3 stroop.1D.txt-stim_label 3 stroop \
-stim_times 4 arithmetic.1D.txt-stim_label 4 arithmetic \
-stim_times 5 motorSequence.1D.txt-stim_label 5 motorSequence \
-stim_times 6 nBack.1D.txt-stim_label 6 nBack \
-stim_times 7 visualSearch.1D.txt-stim_label 7 visualSearch \
-stim_times 8 checkerBoard.1D.txt-stim_label 8 checkerBoard \
-stim_times 9 affective.1D.txt-stim_label 9 affective \
-stim_times 10 ToM.1D.txt-stim_label 10 ToM \
-stim_times 11 GoNoGo.1D.txt-stim_label 11 GoNoGo \
-stim_times 12 emotional.1D.txt-stim_label 12 emotional \
-stim_times 13 verbGeneration.1D.txt-stim_label 13 verbGeneration \
-stim_times 14 actionObservation.1D.txt-stim_label 14 actionObservation \
-stim_times 15 motorImagery.1D.txt-stim_label 15 motorImagery \
-stim_times 16 nBackPic.1D.txt-stim_label 16 nBackPic \
-stim_times 17 rest.1D.txt-stim_label 17 rest \
-stim_times 18 intervalTiming.1D.txt-stim_label 18 intervalTiming \
-stim_times 19 CPRO.1D.txt-stim_label 19 CPRO \
-stim_times 20 prediction.1D.txt-stim_label 20 prediction \
-stim_times 21 romanceMovie.1D.txt-stim_label 21 romanceMovie \
-stim_times 22 spatialMap.1D.txt-stim_label 22 spatialMap \
-stim_times 23 emotionProcess.1D.txt-stim_label 23 emotionProcess \
-stim_times 24 mentalRotation.1D.txt-stim_label 24 mentalRotation \
-stim_times 25 natureMovie.1D.txt-stim_label 25 natureMovie \
-stim_times 26 respAlt.1D.txt-stim_label 26 respAlt \
-stim_times 27 landscapeMovie.1D.txt-stim_label 27 landscapeMovie \
-iresp 1 instruct_FIR_MIN.nii.gz \
-iresp 2 spatialNavigation_FIR_MIN.nii.gz \
-iresp 3 stroop_FIR_MIN.nii.gz \
-iresp 4 arithmetic_FIR_MIN.nii.gz \
-iresp 5 motorSequence_FIR_MIN.nii.gz \
-iresp 6 nBack_FIR_MIN.nii.gz \
-iresp 7 visualSearch_FIR_MIN.nii.gz \
-iresp 8 checkerBoard_FIR_MIN.nii.gz \
-iresp 9 affective_FIR_MIN.nii.gz \
-iresp 10 ToM_FIR_MIN.nii.gz \
-iresp 11 GoNoGo_FIR_MIN.nii.gz \
-iresp 12 emotional_FIR_MIN.nii.gz \
-iresp 13 verbGeneration_FIR_MIN.nii.gz \
-iresp 14 actionObservation_FIR_MIN.nii.gz \
-iresp 15 motorImagery_FIR_MIN.nii.gz \
-iresp 16 nBackPic_FIR_MIN.nii.gz \
-iresp 17 rest_FIR_MIN.nii.gz \
-iresp 18 intervalTiming_FIR_MIN.nii.gz \
-iresp 19 CPRO_FIR_MIN.nii.gz \
-iresp 20 prediction_FIR_MIN.nii.gz \
-iresp 21 romanceMovie_FIR_MIN.nii.gz \
-iresp 22 spatialMap_FIR_MIN.nii.gz \
-iresp 23 emotionProcess_FIR_MIN.nii.gz \
-iresp 24 mentalRotation_FIR_MIN.nii.gz \
-iresp 25 natureMovie_FIR_MIN.nii.gz \
-iresp 26 respAlt_FIR_MIN.nii.gz \
-iresp 27 landscapeMovie_FIR_MIN.nii.gz \
-num_glt 27 \
-gltsym "SYM: +1*instruct" -glt_label 1 instruct \
-gltsym "SYM: +1*spatialNavigation" -glt_label 2 spatialNavigation \
-gltsym "SYM: +1*stroop" -glt_label 3 stroop \
-gltsym "SYM: +1*arithmetic" -glt_label 4 arithmetic \
-gltsym "SYM: +1*motorSequence" -glt_label 5 motorSequence \
-gltsym "SYM: +1*nBack" -glt_label 6 nBack \
-gltsym "SYM: +1*visualSearch" -glt_label 7 visualSearch \
-gltsym "SYM: +1*checkerBoard" -glt_label 8 checkerBoard \
-gltsym "SYM: +1*affective" -glt_label 9 affective \
-gltsym "SYM: +1*ToM" -glt_label 10 ToM \
-gltsym "SYM: +1*GoNoGo" -glt_label 11 GoNoGo \
-gltsym "SYM: +1*emotional" -glt_label 12 emotional \
-gltsym "SYM: +1*verbGeneration" -glt_label 13 verbGeneration \
-gltsym "SYM: +1*actionObservation" -glt_label 14 actionObservation \
-gltsym "SYM: +1*motorImagery" -glt_label 15 motorImagery \
-gltsym "SYM: +1*nBackPic" -glt_label 16 nBackPic \
-gltsym "SYM: +1*rest" -glt_label 17 rest \
-gltsym "SYM: +1*intervalTiming" -glt_label 18 intervalTiming \
-gltsym "SYM: +1*CPRO" -glt_label 19 CPRO \
-gltsym "SYM: +1*prediction" -glt_label 20 prediction \
-gltsym "SYM: +1*romanceMovie" -glt_label 21 romanceMovie \
-gltsym "SYM: +1*spatialMap" -glt_label 22 spatialMap \
-gltsym "SYM: +1*emotionProcess" -glt_label 23 emotionProcess \
-gltsym "SYM: +1*mentalRotation" -glt_label 24 mentalRotation \
-gltsym "SYM: +1*natureMovie" -glt_label 25 natureMovie \
-gltsym "SYM: +1*respAlt" -glt_label 26 respAlt \
-gltsym "SYM: +1*landscapeMovie" -glt_label 27 landscapeMovie \
-rout \
-tout \
-bucket FIRmodel_MNI_stats \
-errts FIRmodel_errts.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text