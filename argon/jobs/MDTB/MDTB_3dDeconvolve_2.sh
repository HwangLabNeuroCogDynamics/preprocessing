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
-num_stimts 44 \
-stim_times 1 NoGo.1D.txt 'BLOCK(1)' -stim_label 1 NoGo \
-stim_times 2 Go.1D.txt 'BLOCK(1)' -stim_label 2 Go \
-stim_times 3 Math.1D.txt 'BLOCK(2.6)' -stim_label 3 Math \
-stim_times 4 DigitJudgement.1D.txt 'BLOCK(2.6)' -stim_label 4 DigitJudgement \
-stim_times 5 UnpleasantScenes.1D.txt 'BLOCK(1.6)' -stim_label 5 UnpleasantScenes \
-stim_times 6 PleasantScenes.1D.txt 'BLOCK(1.6)' -stim_label 6 PleasantScenes \
-stim_times 7 Objects.1D.txt 'BLOCK(1.6)' -stim_label 7 Objects \
-stim_times 8 SadFaces.1D.txt 'BLOCK(1.6)' -stim_label 8 SadFaces \
-stim_times 9 HappyFaces.1D.txt 'BLOCK(1.6)' -stim_label 9 HappyFaces \
-stim_times 10 IntervalTiming.1D.txt 'BLOCK(1.6)' -stim_label 10 IntervalTiming \
-stim_times 11 MotorImagery.1D.txt 'BLOCK(30)' -stim_label 11 MotorImagery \
-stim_times 12 StroopIncon.1D.txt 'BLOCK(1.6)' -stim_label 12 StroopIncon \
-stim_times 13 StroopCon.1D.txt 'BLOCK(1.6)' -stim_label 13 StroopCon \
-stim_times 14 Verbal2Back.1D.txt 'BLOCK(1.6)' -stim_label 14 Verbal2Back \
-stim_times 15 NatureMovie.1D.txt 'BLOCK(30)' -stim_label 15 NatureMovie \
-stim_times 16 LandscapeMovie.1D.txt 'BLOCK(30)' -stim_label 16 LandscapeMovie \
-stim_times 17 AnimatedMovie.1D.txt 'BLOCK(30)' -stim_label 17 AnimatedMovie \
-stim_times 18 SpatialMapEasy.1D.txt 'BLOCK(4.8)' -stim_label 18 SpatialMapEasy \
-stim_times 19 SpatialMapMed.1D.txt 'BLOCK(4.8)' -stim_label 19 SpatialMapMed \
-stim_times 20 SpatialMapHard.1D.txt 'BLOCK(4.8)' -stim_label 20 SpatialMapHard \
-stim_times 21 MentalRotEasy.1D.txt 'BLOCK(3)' -stim_label 21 MentalRotEasy \
-stim_times 22 MentalRotMed.1D.txt 'BLOCK(3)' -stim_label 22 MentalRotMed \
-stim_times 23 MentalRotHard.1D.txt 'BLOCK(3)' -stim_label 23 MentalRotHard \
-stim_times 24 RespAltEasy.1D.txt 'BLOCK(4.6)' -stim_label 24 RespAltEasy \
-stim_times 25 RespAltMed.1D.txt 'BLOCK(4.6)' -stim_label 25 RespAltMed \
-stim_times 26 RespAltHard.1D.txt 'BLOCK(4.6)' -stim_label 26 RespAltHard \
-stim_times 27 BiologicalMotion.1D.txt 'BLOCK(3)' -stim_label 27 BiologicalMotion \
-stim_times 28 ScrambledMotion.1D.txt 'BLOCK(3)' -stim_label 28 ScrambledMotion \
-stim_times 29 PermutedRules.1D.txt 'BLOCK(7.3)' -stim_label 29 PermutedRules \
-stim_times 30 Prediction.1D.txt 'BLOCK(4.8)' -stim_label 30 Prediction \
-stim_times 31 PredictViol.1D.txt 'BLOCK(4.8)' -stim_label 31 PredictViol \
-stim_times 32 PredictScram.1D.txt 'BLOCK(4.8)' -stim_label 32 PredictScram \
-stim_times 33 TheoryOfMind.1D.txt 'BLOCK(14.6)' -stim_label 33 TheoryOfMind \
-stim_times 34 VideoActions.1D.txt 'BLOCK(14)' -stim_label 34 VideoActions \
-stim_times 35 VideoKnots.1D.txt 'BLOCK(14)' -stim_label 35 VideoKnots \
-stim_times 36 FingerSimple.1D.txt 'BLOCK(4.6)' -stim_label 36 FingerSimple \
-stim_times 37 FingerSeq.1D.txt 'BLOCK(4.6)' -stim_label 37 FingerSeq \
-stim_times 38 Object2Back.1D.txt 'BLOCK(1.6)' -stim_label 38 Object2Back \
-stim_times 39 VisualSearchEasy.1D.txt 'BLOCK(1.6)' -stim_label 39 VisualSearchEasy \
-stim_times 40 VisualSearchMed.1D.txt 'BLOCK(1.6)' -stim_label 40 VisualSearchMed \
-stim_times 41 VisualSearchHard.1D.txt 'BLOCK(1.6)' -stim_label 41 VisualSearchHard \
-stim_times 42 SpatialImagery.1D.txt 'BLOCK(30)' -stim_label 42 SpatialImagery \
-stim_times 43 VerbGen.1D.txt 'BLOCK(1.6)' -stim_label 43 VerbGen \
-stim_times 44 WordRead.1D.txt 'BLOCK(1.6)' -stim_label 44 WordRead \
-iresp 1 NoGo_FIR_MIN_norest_global.nii.gz \
-iresp 2 Go_FIR_MIN_norest_global.nii.gz \
-iresp 3 Math_FIR_MIN_norest_global.nii.gz \
-iresp 4 DigitJudgement_FIR_MIN_norest_global.nii.gz \
-iresp 5 UnpleasantScenes_FIR_MIN_norest_global.nii.gz \
-iresp 6 PleasantScenes_FIR_MIN_norest_global.nii.gz \
-iresp 7 Objects_FIR_MIN_norest_global.nii.gz \
-iresp 8 SadFaces_FIR_MIN_norest_global.nii.gz \
-iresp 9 HappyFaces_FIR_MIN_norest_global.nii.gz \
-iresp 10 IntervalTiming_FIR_MIN_norest_global.nii.gz \
-iresp 11 MotorImagery_FIR_MIN_norest_global.nii.gz \
-iresp 12 StroopIncon_FIR_MIN_norest_global.nii.gz \
-iresp 13 StroopCon_FIR_MIN_norest_global.nii.gz \
-iresp 14 Verbal2Back_FIR_MIN_norest_global.nii.gz \
-iresp 15 NatureMovie_FIR_MIN_norest_global.nii.gz \
-iresp 16 LandscapeMovie_FIR_MIN_norest_global.nii.gz \
-iresp 17 AnimatedMovie_FIR_MIN_norest_global.nii.gz \
-iresp 18 SpatialMapEasy_FIR_MIN_norest_global.nii.gz \
-iresp 19 SpatialMapMed_FIR_MIN_norest_global.nii.gz \
-iresp 20 SpatialMapHard_FIR_MIN_norest_global.nii.gz \
-iresp 21 MentalRotEasy_FIR_MIN_norest_global.nii.gz \
-iresp 22 MentalRotMed_FIR_MIN_norest_global.nii.gz \
-iresp 23 MentalRotHard_FIR_MIN_norest_global.nii.gz \
-iresp 24 RespAltEasy_FIR_MIN_norest_global.nii.gz \
-iresp 25 RespAltMed_FIR_MIN_norest_global.nii.gz \
-iresp 26 RespAltHard_FIR_MIN_norest_global.nii.gz \
-iresp 27 BiologicalMotion_FIR_MIN_norest_global.nii.gz \
-iresp 28 ScrambledMotion_FIR_MIN_norest_global.nii.gz \
-iresp 29 PermutedRules_FIR_MIN_norest_global.nii.gz \
-iresp 30 Prediction_FIR_MIN_norest_global.nii.gz \
-iresp 31 PredictViol_FIR_MIN_norest_global.nii.gz \
-iresp 32 PredictScram_FIR_MIN_norest_global.nii.gz \
-iresp 33 TheoryOfMind_FIR_MIN_norest_global.nii.gz \
-iresp 34 VideoActions_FIR_MIN_norest_global.nii.gz \
-iresp 35 VideoKnots_FIR_MIN_norest_global.nii.gz \
-iresp 36 FingerSimple_FIR_MIN_norest_global.nii.gz \
-iresp 37 FingerSeq_FIR_MIN_norest_global.nii.gz \
-iresp 38 Object2Back_FIR_MIN_norest_global.nii.gz \
-iresp 39 VisualSearchEasy_FIR_MIN_norest_global.nii.gz \
-iresp 40 VisualSearchMed_FIR_MIN_norest_global.nii.gz \
-iresp 41 VisualSearchHard_FIR_MIN_norest_global.nii.gz \
-iresp 42 SpatialImagery_FIR_MIN_norest_global.nii.gz \
-iresp 43 VerbGen_FIR_MIN_norest_global.nii.gz \
-iresp 44 WordRead_FIR_MIN_norest_global.nii.gz \
-num_glt 69 \
-gltsym "SYM: +1*NoGo" -glt_label 1 NoGo \
-gltsym "SYM: +1*Go" -glt_label 2 Go \
-gltsym "SYM: +1*Math" -glt_label 3 Math \
-gltsym "SYM: +1*DigitJudgement" -glt_label 4 DigitJudgement \
-gltsym "SYM: +1*UnpleasantScenes" -glt_label 5 UnpleasantScenes \
-gltsym "SYM: +1*PleasantScenes" -glt_label 6 PleasantScenes \
-gltsym "SYM: +1*Objects" -glt_label 7 Objects \
-gltsym "SYM: +1*SadFaces" -glt_label 8 SadFaces \
-gltsym "SYM: +1*HappyFaces" -glt_label 9 HappyFaces \
-gltsym "SYM: +1*IntervalTiming" -glt_label 10 IntervalTiming \
-gltsym "SYM: +1*MotorImagery" -glt_label 11 MotorImagery \
-gltsym "SYM: +1*StroopIncon" -glt_label 12 StroopIncon \
-gltsym "SYM: +1*StroopCon" -glt_label 13 StroopCon \
-gltsym "SYM: +1*Verbal2Back" -glt_label 14 Verbal2Back \
-gltsym "SYM: +1*NatureMovie" -glt_label 15 NatureMovie \
-gltsym "SYM: +1*LandscapeMovie" -glt_label 16 LandscapeMovie \
-gltsym "SYM: +1*AnimatedMovie" -glt_label 17 AnimatedMovie \
-gltsym "SYM: +1*SpatialMapEasy" -glt_label 18 SpatialMapEasy \
-gltsym "SYM: +1*SpatialMapMed" -glt_label 19 SpatialMapMed \
-gltsym "SYM: +1*SpatialMapHard" -glt_label 20 SpatialMapHard \
-gltsym "SYM: +1*MentalRotEasy" -glt_label 21 MentalRotEasy \
-gltsym "SYM: +1*MentalRotMed" -glt_label 22 MentalRotMed \
-gltsym "SYM: +1*MentalRotHard" -glt_label 23 MentalRotHard \
-gltsym "SYM: +1*RespAltEasy" -glt_label 24 RespAltEasy \
-gltsym "SYM: +1*RespAltMed" -glt_label 25 RespAltMed \
-gltsym "SYM: +1*RespAltHard" -glt_label 26 RespAltHard \
-gltsym "SYM: +1*BiologicalMotion" -glt_label 27 BiologicalMotion \
-gltsym "SYM: +1*ScrambledMotion" -glt_label 28 ScrambledMotion \
-gltsym "SYM: +1*PermutedRules" -glt_label 29 PermutedRules \
-gltsym "SYM: +1*Prediction" -glt_label 30 Prediction \
-gltsym "SYM: +1*PredictViol" -glt_label 31 PredictViol \
-gltsym "SYM: +1*PredictScram" -glt_label 32 PredictScram \
-gltsym "SYM: +1*TheoryOfMind" -glt_label 33 TheoryOfMind \
-gltsym "SYM: +1*VideoActions" -glt_label 34 VideoActions \
-gltsym "SYM: +1*VideoKnots" -glt_label 35 VideoKnots \
-gltsym "SYM: +1*FingerSimple" -glt_label 36 FingerSimple \
-gltsym "SYM: +1*FingerSeq" -glt_label 37 FingerSeq \
-gltsym "SYM: +1*Object2Back" -glt_label 38 Object2Back \
-gltsym "SYM: +1*VisualSearchEasy" -glt_label 39 VisualSearchEasy \
-gltsym "SYM: +1*VisualSearchMed" -glt_label 40 VisualSearchMed \
-gltsym "SYM: +1*VisualSearchHard" -glt_label 41 VisualSearchHard \
-gltsym "SYM: +1*SpatialImagery" -glt_label 42 SpatialImagery \
-gltsym "SYM: +1*VerbGen" -glt_label 43 VerbGen \
-gltsym "SYM: +1*WordRead" -glt_label 44 WordRead \
-gltsym "SYM: +1*VideoActions +1*VideoKnots" -glt_label 45 ActionObservation \
-gltsym "SYM: +1*AnimatedMovie" -glt_label 46 AnimatedMovie \
-gltsym "SYM: +1*BiologicalMotion +1*ScrambledMotion" -glt_label 47 BiologicalMotion \
-gltsym "SYM: +1*NoGo +1*Go" -glt_label 48 Go/NoGo \
-gltsym "SYM: +1*UnpleasantScenes +1*PleasantScenes" -glt_label 49 IAPSaffective \
-gltsym "SYM: +1*SadFaces +1*HappyFaces" -glt_label 50 IAPSemotion \
-gltsym "SYM: +1*IntervalTiming" -glt_label 51 Interval \
-gltsym "SYM: +1*LandscapeMovie" -glt_label 52 LandscapeMovie \
-gltsym "SYM: +1*VerbGen +1*WordRead" -glt_label 53 Language \
-gltsym "SYM: +1*Math +1*DigitJudgement" -glt_label 54 Math \
-gltsym "SYM: +1*MentalRotEasy +1*MentalRotMed +1*MentalRotHard" -glt_label 55 MentalRotation \
-gltsym "SYM: +1*FingerSimple +1*FingerSeq" -glt_label 56 Motor \
-gltsym "SYM: +1*MotorImagery" -glt_label 57 MotorImagery \
-gltsym "SYM: +1*NatureMovie" -glt_label 58 NatureMovie \
-gltsym "SYM: +1*Object2Back" -glt_label 59 ObjectNBackTask \
-gltsym "SYM: +1*Objects" -glt_label 60 ObjectViewing \
-gltsym "SYM: +1*RespAltEasy +1*RespAltMed +1*RespAltHard" -glt_label 61 ResponseAlternativesMotor \
-gltsym "SYM: +1*PermutedRules" -glt_label 62 Rules \
-gltsym "SYM: +1*SpatialImagery" -glt_label 63 SpatialImagery \
-gltsym "SYM: +1*SpatialMapEasy +1*SpatialMapMed +1*SpatialMapHard" -glt_label 64 SpatialMap \
-gltsym "SYM: +1*StroopIncon +1*StroopCon" -glt_label 65 Stroop \
-gltsym "SYM: +1*TheoryOfMind" -glt_label 66 TheoryOfMind \
-gltsym "SYM: +1*Verbal2Back" -glt_label 67 Verbal2Back \
-gltsym "SYM: +1*VisualSearchEasy +1*VisualSearchMed +1*VisualSearchHard" -glt_label 68 VisualSearch \
-gltsym "SYM: +1*Prediction +1*PredictViol +1*PredictScram" -glt_label 69 WordPrediction \
-rout \
-tout \
-bucket FIRmodel_MNI_stats_norest_global \
-errts FIRmodel_errts_norest_global.nii.gz \
-noFDR \
-nocout \
-jobs 16 \
-ok_1D_text
