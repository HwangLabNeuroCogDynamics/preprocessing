# #!/bin/bash
#
dataset_directory=$1

echo slots: ${slots:=8}
echo bids_directory: ${bids_directory:=${dataset_directory}BIDS/}
echo singularity_path: ${singularity_path:=/Shared/lss_kahwang_hpc/opt/fmriprep/fmriprep-20.1.1.simg}
echo working_directory: ${working_directory:=/nfsscratch/${USER}/work/}

subjects=($(ls -d ${bids_directory}sub-* | cut -d '/' -f 6 | cut -d '-' -f 2))
total_subjects=${#subjects[@]}

echo subjects: ${subjects[@]}
echo total_subjects: $total_subjects

#####Set Scheduler Configuration Directives#####
#Set the name of the job. This will be the first part of the error/output filename.
#$ -N MDTB_fmriprep

#Set the current working directory as the location for the error and output files.
#(Will show up as .e and .o files)
##$ -cwd

#Send e-mail at beginning/end/suspension of job
##$ -m bes

#E-mail address to send to
##$ -M esorenson@uiowa.edu

# Tell SGE that this is an array job
#$ -t 1-2

# Tell SGE to resubmit job if killed (in all.q queue so eviction will happen)
#$ -ckpt user

# Specify the output file
#$ -o ~/jobs/$JOB_NAME_JOB_ID_$TASK_ID.o

# Specify the error file
#$ -e ~/jobs/$JOB_NAME_JOB_ID_$TASK_ID.e
#####End Set Scheduler Configuration Directives#####

#####Resource Selection Directives#####
#See the HPC wiki for complete resource information: https://wiki.uiowa.edu/display/hpcdocs/Argon+C$

#Select the queue to run in
#$ -q all.q

#Select the number of slots the job will use
#$ -pe smp 8
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

echo Starting fmriprep on ${subjects[$SGE_TASK_ID-1]}


singularity run --cleanenv \
-B ${dataset_directory}:/data \
${singularity_path} \
${bids_directory} \
${dataset_directory} \
participant --participant_label "${subjects[$SGE_TASK_ID-1]}" \
--nthreads ${slots} --omp-nthreads ${slots} \
-w ${working_directory} \
--fs-license-file ~/freesurfer/license.txt \
--clean-workdir \
--skip_bids_validation \
#####End Compute Work#####
