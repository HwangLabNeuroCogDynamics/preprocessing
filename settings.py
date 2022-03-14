# Basic settings
ARGON_HOST = "argon"
ARGON_SCRIPTS_DIR = "/Shared/lss_kahwang_hpc/scripts/preprocessing/argon/"
THALAMEGE_HOST = "thalamege.psychology.uiowa.edu"
MEGE_SCRIPTS_DIR = "/mnt/nfs/lss/lss_kahwang_hpc/scripts/preprocessing/thalamege/"

# Replacement Keys
DATASET_NAME_KEY = "DATASET_NAME"
DATASET_KEY = "DATASET_DIR"
SLOTS_KEY = "SLOTS"
BIDS_KEY = "BIDS_DIR"
WORK_KEY = "WORK_DIR"
SGE_KEY = "SGE_OPTIONS"
OPTIONS_KEY = "OPTIONS"
BASE_SCRIPT_KEY = "BASE_SCRIPT"
EFILE_KEY = "EFILE"
MRIQC_KEY = "MRIQC_DIR"
CONVERSION_SCRIPT_KEY = "CONVERSION_SCRIPT"
POST_CONV_SCRIPT_KEY = "POST_CONV_SCRIPT"
COND_KEY = "CONDITIONS"
TSTAT_KEY = "TSTAT"
COEF_KEY = "COEF"
MEMA_SUBJECTS_KEY = "MEMA_SUBJECTS"

# Workflow settings
HEUDICONV = "heudiconv"
MRIQC = "mriqc"
FMRIPREP = "fmriprep"
DECONVOLVE = "3dDeconvolve"
MEMA = "3dmema"
FD_STATS = "FD_stats"
REGRESSORS = "regressors"
DEFAULT_WORKFLOW = [HEUDICONV, MRIQC, FMRIPREP,
                    DECONVOLVE, MEMA, FD_STATS, REGRESSORS]
JOB_SCRIPTS_DIR = "/Shared/lss_kahwang_hpc/scripts/jobs/"

# HPC settings
DEFAULT_QUEUE = "SEASHORE"
LARGE_QUEUE = "all.q"
QSUB = "qsub -terse "
ARRAY_QSUB = " | awk -F. '{print $1}'"
BASH = "bash "
LOCALSCRATCH = "/localscratch/Users/"

# heudiconv settings
HEUDICONV_BASHFILE = "heudiconv_base.sh"

# mriqc settings
MRIQC_BASHFILE = "mriqc_base.sh"
MRIQC_GROUP_BASHFILE = "mriqc_group_base.sh"

# fmriprep settings
FMRIPREP_BASHFILE = "fmriprep_base.sh"
MEM_ERROR = (
    "concurrent.futures.process.BrokenProcessPool: A process in the "
    "process pool was terminated abruptly while the future was running "
    "or pending."
)
FAILED_SUB_FILE = "failed_subjects.txt"
FAILED_SUB_MEM_FILE = "failed_subjects_mem.txt"
COMPLETED_SUBS_FILE = "completed_subjects.txt"

# 3dDeconvolve settings
DEFAULT_COLUMNS = [
    "csf",
    "white_matter",
    "trans_x",
    "trans_y",
    "trans_z",
    "rot_x",
    "rot_y",
    "rot_z",
]
EVENTS_WC = "*events.tsv"
STIM_CONFIG = "stim_config.csv"
BUCKET_FILE = "FIRmodel_MNI_stats"
BUCKET_FILE_BRIK = BUCKET_FILE + "+tlrc.BRIK"
ERRTS_FILE = "FIRmodel_errts.nii.gz"
MASK_FILE = "combined_mask+tlrc.BRIK"
STIM_LABEL = "Stim Label"

# 3dmema settings
MEMA_BASHFILE = "3dmema_base.sh"

# singularity settings
SING_RUNCLEAN = "singularity run --cleanenv"
AFNI_SING_PATH = "/Shared/lss_kahwang_hpc/opt/afni/afni.sif"
