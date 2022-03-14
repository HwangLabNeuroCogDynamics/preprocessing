#!/bin/bash
# SGE OPTIONS
SGE_OPTIONS

# BASE SCRIPT
BASE_SCRIPT

dataset_dir=DATASET_DIR
logs_dir=${dataset_dir}3dmema/logs/
conditions=(CONDITIONS)
coef=(COEF)
tstat=(TSTAT)

condition=${conditions[SGE_TASK_ID]}

singularity run --cleanenv /Shared/lss_kahwang_hpc/opt/afni/afni.sif \
3dMEMA -prefix ${dataset_dir}3dmema/MEMA_${condition}} \
-set ${condition} \
MEMA_SUBJECTS
-cio \
-missing_data 0 \
-model_outliers

mv -u $SGE_STDOUT_PATH ${logs_dir}${condition}.o
mv -u $SGE_STDERR_PATH ${logs_dir}${condition}.e
