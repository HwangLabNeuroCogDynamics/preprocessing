# #!/bin/bash
#
dataset_directory=$1

echo slots: ${slots:=16}
echo bids_directory: ${bids_directory:=${dataset_directory}bids/}
echo mriqc_directory: ${mriqc_directory:=${dataset_directory}mriqc/}
echo singularity_path: ${singularity_path:=~/mriqc/mriqc.simg}
echo working_directory: ${working_directory:=/localscratch/}

subjects=($(ls -d ${bids_directory}sub-* | cut -d '/' -f 6 | cut -d '-' -f 2))
total_subjects=${#subjects[@]}

echo subjects: ${subjects[@]}
echo total_subjects: $total_subjects

#####Set Scheduler Configuration Directives#####
#Set the name of the job. This will be the first part of the error/output filename.
#$ -N MDTB_groupmriqc

#Set the current working directory as the location for the error and output files.
#(Will show up as .e and .o files)
#$ -cwd

# Tell SGE that this is an array job
# #$ -t 1-12
#
# Tell SGE to resubmit job if killed (in all.q queue so eviction will happen)
# #$ -ckpt user
#####End Set Scheduler Configuration Directives#####

#####Resource Selection Directives#####
#See the HPC wiki for complete resource information: https://wiki.uiowa.edu/display/hpcdocs/Argon+C$

#Select the queue to run in
#$ -q UI

#Select the number of slots the job will use
#$ -pe smp 16
#####End Resource Selection Directives#####

#####Begin Compute Work#####
#Print information from the job into the output file
/bin/echo Running on compute node: `hostname`.
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`
#!/bin/sh

# todo: might need depending on how fmriprep responds to eviction
# if [ $RESTARTED = 1 ]; then
#     .
#     .
#     .
#     some commands to set up the computation for a restart
#     .
#     .
#     .
# fi

echo Starting mriqc on ${subjects[$SGE_TASK_ID-1]}

singularity run --cleanenv \
-B ${dataset_directory}:/data ${singularity_path} \
${bids_directory} \
${mriqc_directory} \
group \
--n_procs ${slots} --ants-nthreads ${slots} \
-w ${working_directory}

# singularity run --cleanenv \
# -B ${dataset_directory}:/data ${singularity_path} \
# ${bids_directory} \
# ${mriqc_directory} \
# participant --participant_label "${subjects[$SGE_TASK_ID-1]}" \
# --n_procs ${slots} --ants-nthreads ${slots} \
# -w ${working_directory}

#####End Compute Work#####

##todo: look into using scratch space, it's faster, and then move files back to
