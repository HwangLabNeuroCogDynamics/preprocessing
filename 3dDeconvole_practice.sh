#!/bin/bash
set_variables() {
  data=$1
  output_path=$2
  output_file=${output_file}/all_nuisance.1D
}

prep_regressors() {

  #this will create an empty file
  echo -n $output_file

  cd $data
  runs=(ls *regressors.tsv)

  for run in runs; do
    # pipe everything after the first line into the empty file we just created
    cat run | tail -n+2 >> $output_file
    # beware of the difference between ">" and ">>"

  done

  cat $output_path/all_nuisance.1D | cut -f23-28,203,207,211,215,219,223  > $output_path/nuisance.1D
  echo "Regressor prep complete. $output_path created."
}

run_3dDeconvolve() {
  3dDeconvolve -input $(ls ${data}/sub-20190516_task-MB3_run-*space-MNI152NLin2009cAsym_desc-preproc_bold*.nii.gz | sort -V) \
  -mask ${data}/sub-20190516_task-MB3_run-004_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz \
  -polort A \
  -ortvec $output_file \
  -local_times \
  -num_stimts 3 \
  -stim_times 1 /data/backed_up/shared/fMRI_Practice/ScanLogs/110_MB3_EDS_stimtime.1D.txt 'TENT(0, 13.6, 9)' -stim_label 1 EDS \
  -stim_times 2 /data/backed_up/shared/fMRI_Practice/ScanLogs/110_MB3_IDS_stimtime.1D.txt 'TENT(0, 13.6, 9)' -stim_label 2 IDS \
  -stim_times 3 /data/backed_up/shared/fMRI_Practice/ScanLogs/110_MB3_Stay_stimtime.1D.txt 'TENT(0, 13.6, 9)' -stim_label 3 Stay \
  -iresp 1 ${output_path}/sub-20190516_EDS_FIR_MNI.nii.gz \
  -iresp 2 ${output_path}/sub-20190516_IDS_FIR_MNI.nii.gz \
  -iresp 3 ${output_path}/sub-20190516_Stay_FIR_MNI.nii.gz \
  -num_glt 7 \
  -gltsym 'SYM: +1*EDS' -glt_label 1 EDS \
  -gltsym 'SYM: +1*IDS' -glt_label 2 IDS \
  -gltsym 'SYM: +1*Stay' -glt_label 3 Stay \
  -gltsym 'SYM: +1*EDS - 1*IDS' -glt_label 4 EDS-IDS \
  -gltsym 'SYM: +1*IDS - 1*Stay' -glt_label 5 IDS-Stay \
  -gltsym 'SYM: +1*EDS + 1*IDS + 1*Stay' -glt_label 6 All \
  -gltsym 'SYM: +1*EDS + 1*IDS - 2*Stay' -glt_label 7 Switch \
  -rout \
  -tout \
  -bucket ${output_path}/sub-20190516_FIRmodel_MNI_stats \
  -errts ${output_path}/sub-20190516_FIRmodel_errts.nii.gz \
  -noFDR \
  -nocout \
  -jobs 4 \
  -ok_1D_text
}

main() {
  set_variables
  prep_regressors
  run_3dDeconvolve
}

main
