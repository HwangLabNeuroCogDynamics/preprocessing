#!/bin/bash
# SGE OPTIONS
#$ -N MDTB_3dmema
#$ -q SEASHORE
#$ -pe smp 4
#$ -o /Shared/lss_kahwang_hpc/data/MDTB/3dmema/logs/$JOB_NAME_$TASK_ID.o
#$ -e /Shared/lss_kahwang_hpc/data/MDTB/3dmema/logs/$JOB_NAME_$TASK_ID.e
#$ -t 1-43
#$ -ckpt user
export OMP_NUM_THREADS=4

# BASE SCRIPT
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(02 03 04 06 08 09 10 12 14 15 17 18 19 20 21 22 24 25 26 27 28 29 30 31)
echo subjects: ${subjects[@]}
echo total_subjects=${#subjects[@]}
subject="${subjects[$SGE_TASK_ID-1]}"

dataset_dir=/Shared/lss_kahwang_hpc/data/MDTB/
logs_dir=${dataset_dir}3dmema/logs/
conditions=(Instruct NoGo Go Math DigitJudgement UnpleasantScenes PleasantScenes Objects SadFaces HappyFaces MotorImagery StroopIncon StroopCon Verbal2Back NatureMovie LandscapeMovie AnimatedMovie SpatialMapEasy SpatialMapMed SpatialMapHard MentalRotEasy MentalRotMed MentalRotHard RespAltEasy RespAltMed RespAltHard BiologicalMotion ScrambledMotion PermutedRules PredictViol PredictScram TheoryOfMind VideoActions VideoKnots FingerSimple FingerSeq Object2Back VisualSearchEasy VisualSearchMed VisualSearchHard SpatialImagery VerbGen WordRead)
coef=([2] [5] [8] [11] [14] [17] [20] [23] [26] [29] [32] [35] [38] [41] [44] [47] [50] [53] [56] [59] [62] [65] [68] [71] [74] [77] [80] [83] [86] [89] [92] [95] [98] [101] [104] [107] [110] [113] [116] [119] [122] [125] [128])
tstat=([3] [6] [9] [12] [15] [18] [21] [24] [27] [30] [33] [36] [39] [42] [45] [48] [51] [54] [57] [60] [63] [66] [69] [72] [75] [78] [81] [84] [87] [90] [93] [96] [99] [102] [105] [108] [111] [114] [117] [120] [123] [126] [129])

condition=${conditions[SGE_TASK_ID]}

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dMEMA -prefix ${dataset_dir}3dmema/MEMA_${condition}} \
-set ${condition} \
02 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-02/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-02/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
03 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-03/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-03/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
04 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-04/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-04/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
06 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-06/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-06/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
08 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-08/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-08/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
09 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-09/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-09/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
10 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-10/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-10/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
12 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-12/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-12/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
14 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-14/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-14/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
15 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-15/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-15/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
17 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-17/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-17/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
18 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-18/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-18/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
19 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-19/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-19/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
20 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-20/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-20/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
21 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-21/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-21/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
22 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-22/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-22/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
24 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-24/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-24/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
25 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-25/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-25/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
26 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-26/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-26/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
27 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-27/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-27/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
28 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-28/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-28/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
29 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-29/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-29/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
30 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-30/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-30/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
31 /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-31/FIRmodel_MNI_stats+tlrc.BRIK${coef[$c]} /Shared/lss_kahwang_hpc/data/MDTB/3dDeconvolve/sub-31/FIRmodel_MNI_stats+tlrc.BRIK${tstat[$c]} \
-cio \
-missing_data 0 \
-model_outliers
