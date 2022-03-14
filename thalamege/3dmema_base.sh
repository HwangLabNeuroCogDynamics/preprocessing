#!/bin/bash
# BASE SCRIPT
BASE_SCRIPT

dataset_dir=DATASET_DIR
conditions=(CONDITIONS)
coef=(COEF)
tstat=(TSTAT)

for c in ${!conditions[@]}
do
  (
    3dMEMA -prefix ${dataset_dir}3dmema/MEMA_${conditions[$c]} \
    -set ${conditions[$c]} \
    MEMA_SUBJECTS
    -cio \
    -missing_data 0 \
    -model_outliers
  ) & 1> ${dataset_dir}3dmema/logs/${condition}.o 2> ${dataset_dir}3dmema/logs/${condition}.e
done
wait
