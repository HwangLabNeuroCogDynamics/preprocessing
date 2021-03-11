#!/bin/bash
# SGE 
#$ -N HCP_D_fmriprep
#$ -q all.q
#$ -pe smp 8
#$ -o /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.o
#$ -e /localscratch/Users/esorenson/$JOB_NAME_$TASK_ID.e
#$ -t 1-301
#$ -ckpt user
#$ -l mt=16G
export OMP_NUM_THREADS=8

# BASE SCRIPT
/bin/echo Running on compute node: `hostname`.
/bin/echo Job: $JOB_ID
/bin/echo Task: $SGE_TASK_ID
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


subjects=(1410933 1458153 1464653 1515644 1534244 1553551 1568867 1578365 1630139 1646154 1654355 1655458 1656359 1658969 1663053 1664762 1668164 1681257 1685164 1686267 1694569 1703140 1707047 1711240 1712444 1714852 1723651 1729562 1742958 1743354 1748061 1749467 1753559 1756060 1756262 1757062 1759571 1762661 1765970 1778070 1778474 1783366 1784065 1785572 1787677 1790262 1791163 1791567 1807051 1812044 1826661 1832858 1838567 1842558 1845160 1849673 1852056 1855365 1856468 1859474 1863465 1870159 1871969 1876272 1876878 1880162 1880465 1881164 1886275 1886477 1886881 1891268 1900142 1900445 1905152 1906457 1914557 1920754 1925461 1928871 1930353 1931456 1933864 1934159 1939068 1943867 1946469 1946873 1948170 1949879 1950056 1959680 1961263 1964269 1976377 1985378 1986784 1994884 1998791 2000212 2001517 2001719 2028638 2030726 2035635 2035837 2039946 2045638 2046842 2051532 2062537 2063034 2064440 2068145 2073340 2082442 2095148 2099257 2105125 2109234 2109638 2112829 2133433 2136540 2140026 2140127 2146139 2155645 2155847 2156344 2163644 2164242 2174649 2181848 2203933 2207840 2208135 2216437 2217742 2220428 2223131 2229547 2236140 2239247 2240030 2241234 2254243 2256651 2264549 2277558 2286155 2295762 2296461 2300426 2301428 2302430 2304737 2310227 2311633 2322335 2332136 2333340 2335344 2336346 2339049 2342745 2344244 2353245 2355249 2363450 2365454 2370952 2378463 2380753 2383456 2383658 2400026 2400632 2415140 2422440 2427753 2428755 2449763 2461450 2473356 2478669 2483561 2483662 2485666 2491257 2496570 2499576 2500939 2504038 2506951 2523345 2524751 2530140 2537457 2540042 2540648 2544151 2544757 2554255 2556158 2556764 2568670 2574564 2581763 2586268 2589981 2594671 2606652 2607452 2612142 2618053 2625454 2626456 2631954 2633554 2643052 2643456 2655766 2662763 2664161 2669575 2679982 2685169 2692671 2696780 2704551 2711649 2714655 2715152 2721147 2724456 2731049 2737869 2740454 2741961 2743157 2748268 2748672 2751560 2751964 2754061 2757370 2761967 2764771 2768981 2769983 2785678 2786074 2795479 2797584 2801852 2804151 2807460 2811552 2812352 2820351 2828569 2832863 2833360 2833461 2841965 2855875 2856170 2860262 2863975 2864270 2878382 2879788 2884175 2884377 2888789 2897891 2901654 2903759 2905460 2913459 2926973 2930055 2932665 2936875 2938172 2939275 2949682 2955374 2957075 2957277 2968080 2976079 2976382 2978386 2982276 2982579 2985181 2987185 2990073 2996590)
echo subjects: ${subjects[@]}
echo total_subjects=${#subjects[@]}
subject="${subjects[$SGE_TASK_ID-1]}"

FMRIPREP='fmriprep/'
FREESURFER='freesurfer/'
BIDS='BIDS/'

dataset_name=HCP_D
dataset_dir=/Shared/lss_kahwang_hpc/data/HCP_D/
slots=8
bids_dir=/Dedicated/inc_data/HCP_D/rawdata/
singularity_path=/Shared/lss_kahwang_hpc/opt/${FMRIPREP}fmriprep-20.1.1.simg
working_dir=/localscratch/Users/esorenson/${JOB_ID}_${SGE_TASK_ID}/
is_highthroughput=IS_HT

freesurfer_lic=/Shared/lss_kahwang_hpc/opt/${FREESURFER}license.txt
fmriprep_dir=${dataset_dir}${FMRIPREP}
freesurfer_dir=${dataset_dir}${FREESURFER}
freesurfer_sub_dir=${dataset_dir}${FREESURFER}sub-${subject}/
fmriprep_sub_dir=${dataset_dir}${FMRIPREP}sub-${subject}/
working_dataset_dir=${working_dir}${dataset_name}/
working_bids_dir=${working_dataset_dir}${BIDS}
working_fmriprep_dir=${working_dataset_dir}${FMRIPREP}
working_freesurfer_dir=${working_dataset_dir}${FREESURFER}
logs_dir=${fmriprep_dir}logs/
is_failed=false

echo dataset_dir: $dataset_dir
echo slots: $slots
echo bids_directory: $bids_dir
echo singularity_path: $singularity_path
echo working_directory: $working_dir
echo working_dataset_dir: $working_dataset_dir
echo working_fmriprep_dir: $working_fmriprep_dir
echo working_freesurfer_dir: $working_freesurfer_dir
echo freesurfer_license: $freesurfer_lic

mkdir $working_dir
mkdir $working_dataset_dir
mkdir $working_bids_dir
mkdir $working_fmriprep_dir
mkdir $working_freesurfer_dir

echo Starting fmriprep on $subject

if [[ $bids_dir =~ "/Dedicated/inc_data/" ]]; then
  cp -r ${bids_dir}sub-${subject}/ $working_bids_dir
  ls $working_bids_dir
  cd ${working_bids_dir}sub-${subject}
  cd ${working_bids_dir}sub-${subject}/fmap/
  for file in $(ls *fieldmap*)
  do
      mv "${file}" "${file/fieldmap/epi}"
  done

  for file in $(ls *.json)
  do
      intendedFile1=''
      intendedFile2=''
      if [[ $file =~ 'AP' ]]; then
        echo "This is AP $file"
        intendedFile1="func/$file"
        intendedFile2="func/${file/AP/PA}"
      else
        echo "This is PA $file"
        intendedFile1="func/$file"
        intendedFile2="func/${file/PA/AP}"
      fi
      intendedFile1=${intendedFile1/epi.json/bold.nii.gz}
      intendedFile2=${intendedFile2/epi.json/bold.nii.gz}
      intendedFile1=${intendedFile1/acq/task}
      intendedFile2=${intendedFile2/acq/task}
      echo $intendedFile1 $intendedFile2
      if [[ $file =~ acq-emotion_dir-AP ]]; then
        sed -i "s|\"$intendedFile1\"|\"$intendedFile2\"|g" $file
      elif [[ $file =~ acq-emotion_dir-PA ]]; then
        echo 'Do nothing'
      else
        sed -i "s|\"$intendedFile1\"|[\"$intendedFile1\", \"$intendedFile2\"]|g" $file
        less $file
      fi
  done

  echo $bids_dir
fi

# copy bids dir to working dir


# copy fmriprep dir to working dir if exists
if [ -d ${fmriprep_sub_dir} ]; then
  cp -r $fmriprep_sub_dir $working_fmriprep_dir
fi

# copy freesurfer dir to working dir if exists, renove IsRunning.lh
if [ -d ${freesurfer_sub_dir} ]; then
  rm ${freesurfer_sub_dir}scripts/*IsRunning*
  cp -r $freesurfer_sub_dir $working_freesurfer_dir
fi

# run fmriprep singularity container
{
singularity run --cleanenv -B $working_dataset_dir $singularity_path \
$working_bids_dir \
$working_dataset_dir \
participant --participant_label $subject \
--nthreads $slots --omp-nthreads $slots \
-w $working_dir \
--fs-license-file ${freesurfer_lic} \
--skip-bids-validation \
--mem 16 \


} ||
{
  # when erorr is thrown
  is_failed=true
  if grep -Fq "A process in the process pool was terminated abruptly while the future was running or pending." $SGE_STDERR_PATH; then
    echo $subject >> ${logs_dir}mem_failed_subjects.txt
  elif ! grep -Fq $subject ${logs_dir}failed_subjects.txt; then
    echo $subject >> ${logs_dir}failed_subjects.txt
  fi
}

if [ "$is_failed" = false ]; then
  echo $subject >> ${logs_dir}completed_subjects.txt
fi

# move fmriprep, freesurfer, and stdout/err files to dataset dir and delete
# working dir if on localscratch
cp -r $working_fmriprep_dir $dataset_dir
cp -r $working_freesurfer_dir $dataset_dir

/bin/echo Finished on: `date`
mv -u $SGE_STDOUT_PATH ${logs_dir}${subject}.o
mv -u $SGE_STDERR_PATH ${logs_dir}${subject}.e
if [[ $working_dir =~ "localscratch" ]]; then
  rm  -r $working_dir
fi


#####End Compute Work#####
