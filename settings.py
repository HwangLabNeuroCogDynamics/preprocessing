# Basic settings
ARGON_HOST = 'argon'
ARGON_SCRIPTS_DIR = '/Shared/lss_kahwang_hpc/scripts/preprocessing/argon/'
THALAMEGE_HOST = 'thalamege.psychology.uiowa.edu'
MEGE_SCRIPTS_DIR = '/mnt/nfs/lss/lss_kahwang_hpc/scripts/preprocessing/thalamege/'

# Replacement Keys
DATASET_NAME_KEY = 'DATASET_NAME'
DATASET_KEY = 'DATASET_DIR'
SLOTS_KEY = 'SLOTS'
BIDS_KEY = 'BIDS_DIR'
WORK_KEY = 'WORK_DIR'
SGE_KEY = 'SGE_OPTIONS'
OPTIONS_KEY = 'OPTIONS'
BASE_SCRIPT_KEY = 'BASE_SCRIPT'
EFILE_KEY = 'EFILE'
MRIQC_KEY = 'MRIQC_DIR'
CONVERSION_SCRIPT_KEY = 'CONVERSION_SCRIPT'

# Workflow settings
HEUDICONV = 'heudiconv'
MRIQC = 'mriqc'
FMRIPREP = 'fmriprep'
DECONVOLVE = '3dDeconvolve'
DEFAULT_WORKFLOW = [HEUDICONV, MRIQC, FMRIPREP, DECONVOLVE]
JOB_SCRIPTS_DIR = '/Shared/lss_kahwang_hpc/scripts/jobs/'

# HPC settings
DEFAULT_QUEUE = 'SEASHORE'
LARGE_QUEUE = 'all.q'
QSUB = 'qsub -terse '
ARRAY_QSUB = ' | awk -F. \'{print $1}\''
BASH = 'bash '
LOCALSCRATCH = '/localscratch/Users/'

# heudiconv settings
HEUDICONV_BASHFILE = 'heudiconv_base.sh'

# mriqc settings
MRIQC_BASHFILE = 'mriqc_base.sh'
MRIQC_GROUP_BASHFILE = 'mriqc_group_base.sh'

# fmriprep settings
FMRIPREP_BASHFILE = 'fmriprep_base.sh'
MEM_ERROR = ('concurrent.futures.process.BrokenProcessPool: A process in the '
             'process pool was terminated abruptly while the future was running '
             'or pending.')
FAILED_SUB_FILE = 'failed_subjects.txt'
FAILED_SUB_MEM_FILE = 'failed_subjects_mem.txt'
COMPLETED_SUBS_FILE = 'completed_subjects.txt'

# singularity settings
SING_RUNCLEAN = 'singularity run --cleanenv'
AFNI_SING_PATH = '/Shared/lss_kahwang_hpc/opt/afni/afni.sif'
